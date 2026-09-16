namespace AuriaAPI.Application.DTOs;

public record CriarChamadoDto(
    string Descricao,
    string Prioridade,
    int AtivoId
);

public record ChamadoResponseDto(
    int Id,
    string Descricao,
    string Prioridade,
    string Status,
    DateTime DataAbertura,
    DateTime? DataFechamento,
    string SolicitanteNome,
    string? TecnicoNome,
    string AmbienteNome,
    string? AtivoNome
);
