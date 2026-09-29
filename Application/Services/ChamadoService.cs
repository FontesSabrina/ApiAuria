using AuriaAPI.Application.DTOs;
using AuriaAPI.Domain.Repository;
using AuriaAPI.Models;

namespace AuriaAPI.Application.Services;

public class ChamadoService
{
    private readonly IChamadoRepository _chamadoRepo;

    public ChamadoService(IChamadoRepository chamadoRepo)
    {
        _chamadoRepo = chamadoRepo;
    }

    public async Task<IEnumerable<ChamadoResponseDto>> ObterTodosAsync()
    {
        var chamados = await _chamadoRepo.GetChamadosComDetalhesAsync();
        return chamados.Select(MapearParaDto);
    }

    public async Task<ChamadoResponseDto?> ObterPorIdAsync(int id)
    {
        var chamado = await _chamadoRepo.GetChamadoComDetalhesByIdAsync(id);
        return chamado == null ? null : MapearParaDto(chamado);
    }

    public async Task<ChamadoResponseDto> CriarAsync(CriarChamadoDto dto, int solicitanteId)
    {
        var chamado = new Chamado
        {
            Descricao = dto.Descricao,
            Prioridade = dto.Prioridade,
            AtivoId = dto.AtivoId,
            SolicitanteId = solicitanteId,
            TipoManutencao = string.IsNullOrWhiteSpace(dto.TipoManutencao) ? "Corretiva" : dto.TipoManutencao,
            Status = "Aberto",
            DataAbertura = DateTime.UtcNow
        };

        await _chamadoRepo.AddAsync(chamado);
        await _chamadoRepo.SaveChangesAsync();

        var criado = await _chamadoRepo.GetChamadoComDetalhesByIdAsync(chamado.Id);
        return MapearParaDto(criado!);
    }

    public async Task<bool> CancelarAsync(int id)
    {
        var chamado = await _chamadoRepo.GetByIdAsync(id);
        if (chamado == null) return false;

        chamado.Status = "Cancelado";
        chamado.DataFechamento = DateTime.UtcNow;
        _chamadoRepo.Update(chamado);
        await _chamadoRepo.SaveChangesAsync();
        return true;
    }

    private static ChamadoResponseDto MapearParaDto(Chamado c) => new(
        c.Id,
        c.Descricao,
        c.TipoManutencao,
        c.Prioridade,
        c.Status,
        c.DataAbertura,
        c.DataFechamento,
        c.SolicitanteId,
        c.Solicitante?.Nome ?? "Desconhecido",
        ObterTecnicoResponsavel(c)?.Tecnico?.Nome,
        c.AtivoId,
        c.Ativo?.Ambiente?.Identificacao ?? "Desconhecido",
        c.Ativo?.Nome
    );

    private static OrdemServico? ObterTecnicoResponsavel(Chamado c) =>
        c.OrdensServico
            .OrderBy(os => os.DataConclusao.HasValue)
            .ThenByDescending(os => os.DataInicio)
            .FirstOrDefault();
}
