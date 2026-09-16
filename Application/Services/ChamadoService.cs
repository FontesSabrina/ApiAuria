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

    private static ChamadoResponseDto MapearParaDto(Chamado c) => new(
        c.Id,
        c.Descricao,
        c.TipoManutencao,
        c.Prioridade,
        c.Status,
        c.DataAbertura,
        c.DataFechamento,
        c.Solicitante?.Nome ?? "Desconhecido",
        ObterTecnicoResponsavel(c)?.Tecnico?.Nome,
        c.Ativo?.Ambiente?.Identificacao ?? "Desconhecido",
        c.Ativo?.Nome
    );

    // A ordem de serviço ainda em andamento tem prioridade; se todas estiverem
    // concluídas, usa a mais recente para refletir o último técnico responsável.
    private static OrdemServico? ObterTecnicoResponsavel(Chamado c) =>
        c.OrdensServico
            .OrderBy(os => os.DataConclusao.HasValue)
            .ThenByDescending(os => os.DataInicio)
            .FirstOrDefault();
}
