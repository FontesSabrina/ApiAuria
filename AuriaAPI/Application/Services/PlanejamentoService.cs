using AuriaAPI.Application.DTOs;
using AuriaAPI.Application.Interfaces;
using AuriaAPI.Application.Mappings;
using AuriaAPI.Domain.Constants;
using AuriaAPI.Domain.Repositories;

namespace AuriaAPI.Application.Services;

public class PlanejamentoService : IPlanejamentoService
{
    private readonly IOrdemServicoRepository _ordens;
    private readonly IAtivoRepository _ativos;

    public PlanejamentoService(IOrdemServicoRepository ordens, IAtivoRepository ativos)
    {
        _ordens = ordens;
        _ativos = ativos;
    }

    /// <summary>
    /// Ordens de serviço de chamados preventivos abertos na data informada.
    /// As datas são gravadas em UTC; a comparação usa o fuso horário do servidor da API.
    /// </summary>
    public async Task<IReadOnlyList<OrdemServicoResponseDto>> ObterCronogramaPreventivasAsync(DateOnly data)
    {
        var ordens = await _ordens.ObterComDetalhesAsync();
        return ordens
            .Where(o => o.Chamado != null
                        && o.Chamado.TipoManutencao == TiposManutencao.Preventiva
                        && DateOnly.FromDateTime(DateTime.SpecifyKind(o.Chamado.DataAbertura, DateTimeKind.Utc).ToLocalTime()) == data)
            .OrderBy(o => o.Chamado!.DataAbertura)
            .Select(o => o.ParaDto())
            .ToList();
    }

    /// <summary>Ativos que precisam de manutenção preventiva (regra definida em <c>Ativo.MotivosAlertaPreventiva</c>).</summary>
    public async Task<IReadOnlyList<AlertaPreventivaDto>> ObterAlertasAsync()
    {
        var agora = DateTime.UtcNow;
        var ativos = await _ativos.ObterTodosComAmbienteAsync();

        return ativos
            .Select(a => new { Ativo = a, Motivos = a.MotivosAlertaPreventiva(agora) })
            .Where(x => x.Motivos.Count > 0)
            .OrderByDescending(x => x.Motivos.Count)
            .ThenBy(x => x.Ativo.Nome)
            .Select(x => new AlertaPreventivaDto(
                x.Ativo.Id, x.Ativo.Nome, x.Ativo.Patrimonio, x.Ativo.EstadoConservacao,
                x.Ativo.Ambiente?.Identificacao, x.Ativo.DataAquisicao, x.Motivos))
            .ToList();
    }
}
