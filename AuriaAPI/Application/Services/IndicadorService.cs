using AuriaAPI.Application.Common;
using AuriaAPI.Application.DTOs;
using AuriaAPI.Application.Interfaces;
using AuriaAPI.Domain.Constants;
using AuriaAPI.Domain.Repositories;

namespace AuriaAPI.Application.Services;

/// <summary>
/// Calcula os indicadores do painel de BI. O cálculo percorre todas as ordens e chamados, por isso
/// o resultado fica 2 minutos em cache; ele é invalidado sempre que uma OS ou chamado muda.
/// </summary>
public class IndicadorService : IIndicadorService
{
    private static readonly TimeSpan ExpiracaoCache = TimeSpan.FromMinutes(2);

    private readonly IOrdemServicoRepository _ordens;
    private readonly IChamadoRepository _chamados;
    private readonly ICacheService _cache;

    public IndicadorService(IOrdemServicoRepository ordens, IChamadoRepository chamados, ICacheService cache)
    {
        _ordens = ordens;
        _chamados = chamados;
        _cache = cache;
    }

    public Task<IndicadoresDto> ObterResumoAsync() =>
        _cache.ObterOuCriarAsync<IndicadoresDto>(ChavesCache.Indicadores, CalcularAsync, ExpiracaoCache);

    private async Task<IndicadoresDto> CalcularAsync()
    {
        var ordens = await _ordens.ObterComDetalhesAsync();
        var chamados = await _chamados.ObterComDetalhesAsync();

        var concluidas = ordens.Where(o => o.EstaConcluida).ToList();
        var emAberto = ordens.Where(o => !o.EstaConcluida).ToList();

        var taxaConclusao = ordens.Count == 0 ? 0 : concluidas.Count * 100.0 / ordens.Count;

        var tempoMedioAtendimento = concluidas.Count == 0
            ? 0
            : concluidas.Average(o => (o.DataConclusao!.Value - o.DataInicio).TotalHours);

        var comTempoInformado = concluidas.Where(o => o.TempoGastoMinutos > 0).ToList();
        var tempoMedioExecucao = comTempoInformado.Count == 0
            ? 0
            : comTempoInformado.Average(o => o.TempoGastoMinutos / 60.0);

        var chamadosPorStatus = StatusChamado.Todos.ToDictionary(s => s, s => chamados.Count(c => c.Status == s));

        var topAtivos = ordens
            .Where(o => o.Chamado != null)
            .GroupBy(o => o.Chamado!.AtivoId)
            .Select(g => new AtivoFalhasDto(g.Key, g.First().Chamado!.Ativo?.Nome ?? $"Ativo #{g.Key}", g.Count()))
            .OrderByDescending(a => a.QuantidadeOrdens)
            .Take(5)
            .ToList();

        var pendentes = emAberto
            .OrderByDescending(o => o.DataInicio)
            .Take(5)
            .Select(o => new OrdemPendenteDto(o.Id, o.Chamado?.Ativo?.Nome, o.Chamado?.Descricao, o.Chamado?.Prioridade, o.Tecnico?.Nome))
            .ToList();

        var custoMaoObra = concluidas.Sum(o => o.CustoMaoObra);
        var custoPecas = concluidas.Sum(o => o.CustoPecas);

        return new IndicadoresDto(
            TotalOrdens: ordens.Count,
            OrdensConcluidas: concluidas.Count,
            OrdensEmAberto: emAberto.Count,
            TaxaConclusao: Math.Round(taxaConclusao, 1),
            CustoTotal: custoMaoObra + custoPecas,
            CustoMaoObra: custoMaoObra,
            CustoPecas: custoPecas,
            TempoMedioAtendimentoHoras: Math.Round(tempoMedioAtendimento, 2),
            TempoMedioExecucaoHoras: Math.Round(tempoMedioExecucao, 2),
            ChamadosPorStatus: chamadosPorStatus,
            TopAtivosComFalhas: topAtivos,
            OrdensPendentes: pendentes,
            GeradoEm: DateTime.UtcNow);
    }
}
