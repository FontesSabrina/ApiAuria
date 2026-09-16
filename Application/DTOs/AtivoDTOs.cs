namespace AuriaAPI.Application.DTOs;

public record CriarAtivoDto(
    string Patrimonio,
    string Nome,
    string EstadoConservacao,
    DateTime? DataAquisicao,
    DateTime? PrazoGarantia,
    int? VidaUtilEstimadaAnos,
    int AmbienteId
);

public record AtualizarAtivoDto(
    string Patrimonio,
    string Nome,
    string EstadoConservacao,
    DateTime? DataAquisicao,
    DateTime? PrazoGarantia,
    int? VidaUtilEstimadaAnos,
    int AmbienteId
);

public record AtivoResponseDto(
    int Id,
    string Patrimonio,
    string Nome,
    string EstadoConservacao,
    DateTime? DataAquisicao,
    DateTime? PrazoGarantia,
    int? VidaUtilEstimadaAnos,
    int AmbienteId,
    string? AmbienteIdentificacao
);
