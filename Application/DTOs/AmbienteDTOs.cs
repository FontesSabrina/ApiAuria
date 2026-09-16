namespace AuriaAPI.Application.DTOs;

public record CriarAmbienteDto(string Identificacao, string? PredioBloco, string? Andar, string? Observacoes);
public record AtualizarAmbienteDto(string Identificacao, string? PredioBloco, string? Andar, string? Observacoes);
public record AmbienteResponseDto(int Id, string Identificacao, string? PredioBloco, string? Andar, string? Observacoes);
