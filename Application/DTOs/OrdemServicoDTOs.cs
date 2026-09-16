namespace AuriaAPI.Application.DTOs;

public record CriarOrdemServicoDto(
    int ChamadoId,
    int TecnicoId,
    int TempoGastoMinutos,
    string? ParecerTecnico,
    decimal CustoMaoObra
);

public record OrdemServicoResponseDto(
    int Id,
    int ChamadoId,
    int TecnicoId,
    string? TecnicoNome,
    int TempoGastoMinutos,
    string? ParecerTecnico,
    decimal CustoMaoObra,
    DateTime DataInicio,
    DateTime? DataConclusao,
    string? StatusChamado
);
