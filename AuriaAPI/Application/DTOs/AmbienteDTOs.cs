using System.ComponentModel.DataAnnotations;

namespace AuriaAPI.Application.DTOs;

/// <summary>Corpo usado tanto na criação (POST) quanto na atualização (PUT) de um ambiente.</summary>
public class SalvarAmbienteDto
{
    [Required(ErrorMessage = "A identificação do ambiente é obrigatória.")]
    [StringLength(100, ErrorMessage = "A identificação deve ter no máximo 100 caracteres.")]
    public string Identificacao { get; init; } = string.Empty;

    [StringLength(100, ErrorMessage = "O prédio/bloco deve ter no máximo 100 caracteres.")]
    public string? PredioBloco { get; init; }

    [StringLength(50, ErrorMessage = "O andar deve ter no máximo 50 caracteres.")]
    public string? Andar { get; init; }

    [StringLength(500, ErrorMessage = "As observações devem ter no máximo 500 caracteres.")]
    public string? Observacoes { get; init; }
}

public record AmbienteResponseDto(int Id, string Identificacao, string? PredioBloco, string? Andar, string? Observacoes);
