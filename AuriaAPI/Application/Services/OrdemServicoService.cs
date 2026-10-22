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

/// <summary>
/// Fluxo da ordem de serviço:
/// 1. Admin/Técnico abre a OS para um chamado "Aberto" → chamado passa a "Em Execucao".
/// 2. O técnico registra as peças consumidas → estoque é debitado.
/// 3. O técnico conclui a OS → chamado passa a "Concluido" e o solicitante é avisado.
/// Tudo o que uma etapa altera (OS, chamado, estoque, notificações) é salvo junto, numa única operação.
/// </summary>
public class OrdemServicoService : IOrdemServicoService
{
    private readonly IOrdemServicoRepository _ordens;
    private readonly IChamadoRepository _chamados;
    private readonly IUsuarioRepository _usuarios;
    private readonly IItemEstoqueRepository _itens;
    private readonly INotificador _notificador;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICacheService _cache;

    public OrdemServicoService(
        IOrdemServicoRepository ordens,
        IChamadoRepository chamados,
        IUsuarioRepository usuarios,
        IItemEstoqueRepository itens,
        INotificador notificador,
        IUnitOfWork unitOfWork,
        ICacheService cache)
    {
        _ordens = ordens;
        _chamados = chamados;
        _usuarios = usuarios;
        _itens = itens;
        _notificador = notificador;
        _unitOfWork = unitOfWork;
        _cache = cache;
    }

    public async Task<IReadOnlyList<OrdemServicoResponseDto>> ObterTodasAsync()
    {
        var ordens = await _ordens.ObterComDetalhesAsync();
        return ordens.Select(o => o.ParaDto()).ToList();
    }

    public async Task<IReadOnlyList<OrdemServicoResponseDto>> ObterDoTecnicoAsync(int tecnicoId)
    {
        var ordens = await _ordens.ObterComDetalhesAsync(tecnicoId);
        return ordens.Select(o => o.ParaDto()).ToList();
    }

    public async Task<OrdemServicoResponseDto> ObterPorIdAsync(int id) => (await ObterEntidadeAsync(id)).ParaDto();

    public async Task<OrdemServicoResponseDto> CriarAsync(CriarOrdemServicoDto dto)
    {
        var chamado = await _chamados.ObterComDetalhesPorIdAsync(dto.ChamadoId)
            ?? throw new RecursoNaoEncontradoException("Chamado não encontrado.");

        var tecnico = await _usuarios.ObterPorIdAsync(dto.TecnicoId)
            ?? throw new RecursoNaoEncontradoException("Técnico não encontrado.");

        if (!tecnico.PodeExecutarOrdens)
            throw new RegraDeNegocioException($"O usuário designado precisa ter perfil {Perfis.Tecnico} ou {Perfis.Admin}.");

        chamado.IniciarExecucao();

        var ordem = new OrdemServico
        {
            ChamadoId = chamado.Id,
            Chamado = chamado,
            TecnicoId = tecnico.Id,
            Tecnico = tecnico,
            TempoGastoMinutos = dto.TempoGastoMinutos,
            ParecerTecnico = dto.ParecerTecnico,
            CustoMaoObra = dto.CustoMaoObra,
            DataInicio = DateTime.UtcNow
        };

        var itensConsumidos = await RegistrarItensAsync(ordem, dto.ItensUtilizados);
        await _ordens.AdicionarAsync(ordem);

        await _notificador.NotificarUsuarioAsync(
            tecnico.Id,
            "Nova ordem de serviço",
            $"Você foi designado para o chamado #{chamado.Id} (ativo '{chamado.Ativo?.Nome}', prioridade {chamado.Prioridade}).");
        await _notificador.NotificarUsuarioAsync(
            chamado.SolicitanteId,
            "Chamado em execução",
            $"O seu chamado #{chamado.Id} foi aprovado e está em execução pelo técnico {tecnico.Nome}.");
        await AvisarEstoqueBaixoAsync(itensConsumidos);

        await _unitOfWork.SalvarAlteracoesAsync();
        _cache.Invalidar(ChavesCache.Indicadores);

        return (await ObterEntidadeAsync(ordem.Id)).ParaDto();
    }

    public async Task<OrdemServicoResponseDto> RegistrarConsumoAsync(int id, RegistrarConsumoDto dto, UsuarioLogado usuarioLogado)
    {
        var ordem = await ObterEntidadeAsync(id);
        GarantirQuePodeAlterar(ordem, usuarioLogado);

        var itensConsumidos = await RegistrarItensAsync(ordem, dto.Itens);
        await AvisarEstoqueBaixoAsync(itensConsumidos);

        await _unitOfWork.SalvarAlteracoesAsync();
        _cache.Invalidar(ChavesCache.Indicadores);

        return ordem.ParaDto();
    }

    public async Task<OrdemServicoResponseDto> ConcluirAsync(int id, ConcluirOrdemServicoDto dto, UsuarioLogado usuarioLogado)
    {
        var ordem = await ObterEntidadeAsync(id);
        GarantirQuePodeAlterar(ordem, usuarioLogado);

        ordem.Concluir(dto.TempoGastoMinutos, dto.ParecerTecnico, dto.CustoMaoObra);

        if (ordem.Chamado != null)
        {
            await _notificador.NotificarUsuarioAsync(
                ordem.Chamado.SolicitanteId,
                "Manutenção concluída",
                $"A manutenção do seu chamado #{ordem.ChamadoId} (ativo '{ordem.Chamado.Ativo?.Nome}') foi concluída.");
        }

        await _unitOfWork.SalvarAlteracoesAsync();
        _cache.Invalidar(ChavesCache.Indicadores);

        return ordem.ParaDto();
    }

    private async Task<OrdemServico> ObterEntidadeAsync(int id) =>
        await _ordens.ObterComDetalhesPorIdAsync(id) ?? throw new RecursoNaoEncontradoException("Ordem de serviço não encontrada.");

    /// <summary>Admin pode alterar qualquer OS; um técnico só as que foram designadas a ele.</summary>
    private static void GarantirQuePodeAlterar(OrdemServico ordem, UsuarioLogado usuarioLogado)
    {
        if (!usuarioLogado.EhAdmin && ordem.TecnicoId != usuarioLogado.Id)
            throw new AcessoNegadoException("Esta ordem de serviço está designada a outro técnico.");
    }

    /// <summary>Busca os itens de estoque informados e registra o consumo de cada um na OS (debitando o estoque).</summary>
    private async Task<IReadOnlyList<ItemEstoque>> RegistrarItensAsync(OrdemServico ordem, IReadOnlyList<ItemUtilizadoDto>? itensUtilizados)
    {
        if (itensUtilizados == null || itensUtilizados.Count == 0)
            return Array.Empty<ItemEstoque>();

        var ids = itensUtilizados.Select(i => i.ItemEstoqueId).Distinct().ToList();
        var itens = (await _itens.ObterPorIdsAsync(ids)).ToDictionary(i => i.Id);

        var naoEncontrados = ids.Where(id => !itens.ContainsKey(id)).ToList();
        if (naoEncontrados.Count > 0)
            throw new RegraDeNegocioException($"Item(ns) de estoque não encontrado(s): {string.Join(", ", naoEncontrados)}.");

        foreach (var itemUtilizado in itensUtilizados)
            ordem.RegistrarConsumo(itens[itemUtilizado.ItemEstoqueId], itemUtilizado.QuantidadeUtilizada);

        return itens.Values.ToList();
    }

    private async Task AvisarEstoqueBaixoAsync(IEnumerable<ItemEstoque> itens)
    {
        foreach (var item in itens.Where(i => i.EstaAbaixoDoMinimo))
        {
            await _notificador.NotificarPerfilAsync(
                Perfis.Admin,
                "Estoque baixo",
                $"O item '{item.Nome}' está com {item.QuantidadeEstoque} unidade(s) em estoque (mínimo: {item.EstoqueMinimo}).");
        }
    }
}
