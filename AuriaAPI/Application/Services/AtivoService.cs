using AuriaAPI.Application.DTOs;
using AuriaAPI.Application.Exceptions;
using AuriaAPI.Application.Interfaces;
using AuriaAPI.Application.Mappings;
using AuriaAPI.Domain.Entities;
using AuriaAPI.Domain.Exceptions;
using AuriaAPI.Domain.Repositories;

namespace AuriaAPI.Application.Services;

public class AtivoService : IAtivoService
{
    private readonly IAtivoRepository _ativos;
    private readonly IAmbienteRepository _ambientes;
    private readonly IUnitOfWork _unitOfWork;

    public AtivoService(IAtivoRepository ativos, IAmbienteRepository ambientes, IUnitOfWork unitOfWork)
    {
        _ativos = ativos;
        _ambientes = ambientes;
        _unitOfWork = unitOfWork;
    }

    public async Task<IReadOnlyList<AtivoResponseDto>> ObterTodosAsync(int? ambienteId)
    {
        var ativos = await _ativos.ObterTodosComAmbienteAsync();
        return ativos
            .Where(a => ambienteId == null || a.AmbienteId == ambienteId)
            .OrderBy(a => a.Nome)
            .Select(a => a.ParaDto())
            .ToList();
    }

    public async Task<AtivoResponseDto> ObterPorIdAsync(int id) =>
        (await _ativos.ObterComAmbienteAsync(id) ?? throw new RecursoNaoEncontradoException("Ativo não encontrado.")).ParaDto();

    public async Task<AtivoResponseDto> CriarAsync(SalvarAtivoDto dto)
    {
        await GarantirQueAmbienteExisteAsync(dto.AmbienteId);

        var ativo = new Ativo();
        Preencher(ativo, dto);

        await _ativos.AdicionarAsync(ativo);
        await _unitOfWork.SalvarAlteracoesAsync();

        return await ObterPorIdAsync(ativo.Id);
    }

    public async Task<AtivoResponseDto> AtualizarAsync(int id, SalvarAtivoDto dto)
    {
        var ativo = await _ativos.ObterPorIdAsync(id) ?? throw new RecursoNaoEncontradoException("Ativo não encontrado.");
        await GarantirQueAmbienteExisteAsync(dto.AmbienteId);

        Preencher(ativo, dto);
        await _unitOfWork.SalvarAlteracoesAsync();

        return await ObterPorIdAsync(id);
    }

    public async Task RemoverAsync(int id)
    {
        var ativo = await _ativos.ObterPorIdAsync(id) ?? throw new RecursoNaoEncontradoException("Ativo não encontrado.");

        if (await _ativos.PossuiChamadosAsync(id))
            throw new ConflitoException("Este ativo possui chamados vinculados e não pode ser excluído. Altere o estado dele para 'Desativado'.");

        _ativos.Remover(ativo);
        await _unitOfWork.SalvarAlteracoesAsync();
    }

    private async Task GarantirQueAmbienteExisteAsync(int ambienteId)
    {
        if (!await _ambientes.ExisteAsync(ambienteId))
            throw new RegraDeNegocioException("O ambiente informado (AmbienteId) não existe.");
    }

    private static void Preencher(Ativo ativo, SalvarAtivoDto dto)
    {
        ativo.Patrimonio = dto.Patrimonio.Trim();
        ativo.Nome = dto.Nome.Trim();
        ativo.EstadoConservacao = dto.EstadoConservacao;
        ativo.DataAquisicao = dto.DataAquisicao;
        ativo.PrazoGarantia = dto.PrazoGarantia;
        ativo.VidaUtilEstimadaAnos = dto.VidaUtilEstimadaAnos;
        ativo.AmbienteId = dto.AmbienteId;
    }
}
