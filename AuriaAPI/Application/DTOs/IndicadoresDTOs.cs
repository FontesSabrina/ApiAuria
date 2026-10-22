namespace AuriaAPI.Application.DTOs;

public record AtivoFalhasDto(int AtivoId, string AtivoNome, int QuantidadeOrdens);

public record OrdemPendenteDto(int OrdemServicoId, string? AtivoNome, string? DescricaoProblema, string? Prioridade, string? TecnicoNome);

/// <summary>
/// Painel de indicadores (GET /api/indicadores). <see cref="GeradoEm"/> mostra quando os números
/// foram calculados — enquanto o resultado estiver em cache, esse horário não muda.
/// </summary>
public record IndicadoresDto(
    int TotalOrdens,
    int OrdensConcluidas,
    int OrdensEmAberto,
    double TaxaConclusao,
    decimal CustoTotal,
    decimal CustoMaoObra,
    decimal CustoPecas,
    double TempoMedioAtendimentoHoras,
    double TempoMedioExecucaoHoras,
    IReadOnlyDictionary<string, int> ChamadosPorStatus,
    IReadOnlyList<AtivoFalhasDto> TopAtivosComFalhas,
    IReadOnlyList<OrdemPendenteDto> OrdensPendentes,
    DateTime GeradoEm
);

public record AlertaPreventivaDto(
    int AtivoId,
    string Nome,
    string Patrimonio,
    string EstadoConservacao,
    string? AmbienteNome,
    DateTime? DataAquisicao,
    IReadOnlyList<string> Motivos
);
