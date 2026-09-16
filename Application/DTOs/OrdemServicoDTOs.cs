namespace AuriaAPI.Application.DTOs;

public record ItemUtilizadoDto(int ItemEstoqueId, int QuantidadeUtilizada);

public record CriarOrdemServicoDto(
    int ChamadoId,
    int TecnicoId,
    int TempoGastoMinutos,
    string? ParecerTecnico,
    decimal CustoMaoObra,
    IReadOnlyList<ItemUtilizadoDto>? ItensUtilizados
);

public record ItemUtilizadoResponseDto(int ItemEstoqueId, string? ItemNome, int QuantidadeUtilizada);

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
    string? StatusChamado,
    IReadOnlyList<ItemUtilizadoResponseDto> ItensUtilizados
);
