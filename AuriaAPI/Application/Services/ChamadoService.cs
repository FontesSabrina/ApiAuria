using AuriaAPI.Application.Common;
using AuriaAPI.Application.DTOs;
using AuriaAPI.Application.Exceptions;
using AuriaAPI.Application.Interfaces;
using AuriaAPI.Application.Mappings;
using AuriaAPI.Domain.Constants;
using AuriaAPI.Domain.Entities;
using AuriaAPI.Domain.Exceptions;
using AuriaAPI.Domain.Repositories;

namespace AuriaAPI.Application.Services;

public class ChamadoService : IChamadoService
{
    private readonly IChamadoRepository _chamados;
    private readonly IAtivoRepository _ativos;
    private readonly INotificador _notificador;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICacheService _cache;

    public ChamadoService(IChamadoRepository chamados, IAtivoRepository ativos, INotificador notificador, IUnitOfWork unitOfWork, ICacheService cache)
    {
        _chamados = chamados;
        _ativos = ativos;
        _notificador = notificador;
        _unitOfWork = unitOfWork;
        _cache = cache;
    }

    public async Task<IReadOnlyList<ChamadoResponseDto>> ObterTodosAsync(string? status)
    {
        if (!string.IsNullOrWhiteSpace(status) && !StatusChamado.Todos.Contains(status))
            throw new RegraDeNegocioException($"Status inválido. Valores aceitos: {string.Join(", ", StatusChamado.Todos)}.");

        var chamados = await _chamados.ObterComDetalhesAsync(status: string.IsNullOrWhiteSpace(status) ? null : status);
        return chamados.Select(c => c.ParaDto()).ToList();
    }

    public async Task<IReadOnlyList<ChamadoResponseDto>> ObterDoSolicitanteAsync(int solicitanteId)
    {
        var chamados = await _chamados.ObterComDetalhesAsync(solicitanteId: solicitanteId);
        return chamados.Select(c => c.ParaDto()).ToList();
    }

    public async Task<ChamadoResponseDto> ObterPorIdAsync(int id, UsuarioLogado usuarioLogado)
    {
        var chamado = await ObterEntidadeAsync(id);

        // Solicitantes só enxergam os próprios chamados; técnicos e admins enxergam todos.
        if (usuarioLogado.Perfil == Perfis.Solicitante && chamado.SolicitanteId != usuarioLogado.Id)
            throw new AcessoNegadoException("Você só pode consultar os seus próprios chamados.");

        return chamado.ParaDto();
    }

    public async Task<ChamadoResponseDto> CriarAsync(CriarChamadoDto dto, UsuarioLogado usuarioLogado)
    {
        var ativo = await _ativos.ObterPorIdAsync(dto.AtivoId)
            ?? throw new RegraDeNegocioException("O ativo informado (AtivoId) não existe.");

        if (ativo.EstadoConservacao == EstadosConservacao.Desativado)
            throw new RegraDeNegocioException("Não é possível abrir chamado para um ativo desativado.");

        var chamado = new Chamado
        {
            Descricao = dto.Descricao.Trim(),
            Prioridade = dto.Prioridade,
            TipoManutencao = dto.TipoManutencao,
            LocalizacaoDetalhada = dto.LocalizacaoDetalhada,
            AtivoId = ativo.Id,
            SolicitanteId = usuarioLogado.Id,
            Status = StatusChamado.Aberto,
            DataAbertura = DateTime.UtcNow
        };

        await _chamados.AdicionarAsync(chamado);
        await _notificador.NotificarPerfilAsync(
            Perfis.Admin,
            "Novo chamado aberto",
            $"Novo chamado ({chamado.TipoManutencao.ToLowerInvariant()}, prioridade {chamado.Prioridade}) para o ativo '{ativo.Nome}': {Resumir(chamado.Descricao)}");

        await _unitOfWork.SalvarAlteracoesAsync();
        _cache.Invalidar(ChavesCache.Indicadores);

        return (await ObterEntidadeAsync(chamado.Id)).ParaDto();
    }

    public async Task<ChamadoResponseDto> CancelarAsync(int id, UsuarioLogado usuarioLogado)
    {
        var chamado = await ObterEntidadeAsync(id);

        var ehDono = chamado.SolicitanteId == usuarioLogado.Id;
        if (!usuarioLogado.EhAdmin && !ehDono)
            throw new AcessoNegadoException("Apenas o administrador ou o próprio solicitante podem cancelar este chamado.");

        chamado.Cancelar();

        if (!ehDono)
        {
            await _notificador.NotificarUsuarioAsync(
                chamado.SolicitanteId,
                "Chamado cancelado",
                $"O seu chamado #{chamado.Id} para o ativo '{chamado.Ativo?.Nome}' foi cancelado pelo administrador.");
        }

        await _unitOfWork.SalvarAlteracoesAsync();
        _cache.Invalidar(ChavesCache.Indicadores);

        return chamado.ParaDto();
    }

    private async Task<Chamado> ObterEntidadeAsync(int id) =>
        await _chamados.ObterComDetalhesPorIdAsync(id) ?? throw new RecursoNaoEncontradoException("Chamado não encontrado.");

    private static string Resumir(string texto) => texto.Length <= 80 ? texto : texto[..77] + "...";
}
