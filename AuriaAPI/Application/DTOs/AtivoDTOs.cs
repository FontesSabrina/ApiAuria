using System.ComponentModel.DataAnnotations;
using AuriaAPI.Domain.Constants;

namespace AuriaAPI.Application.DTOs;

/// <summary>Corpo usado tanto na criação (POST) quanto na atualização (PUT) de um ativo.</summary>
public class SalvarAtivoDto
{
    [Required(ErrorMessage = "O número de patrimônio é obrigatório.")]
    [StringLength(50, ErrorMessage = "O patrimônio deve ter no máximo 50 caracteres.")]
    public string Patrimonio { get; init; } = string.Empty;

    [Required(ErrorMessage = "O nome do ativo é obrigatório.")]
    [StringLength(100, ErrorMessage = "O nome deve ter no máximo 100 caracteres.")]
    public string Nome { get; init; } = string.Empty;

    [Required(ErrorMessage = "O estado de conservação é obrigatório.")]
    [AllowedValues(EstadosConservacao.Novo, EstadosConservacao.Bom, EstadosConservacao.Regular, EstadosConservacao.Ruim,
        EstadosConservacao.EmManutencao, EstadosConservacao.Desativado,
        ErrorMessage = "Estado de conservação inválido. Valores aceitos: Novo, Bom, Regular, Ruim, Em Manutenção, Desativado.")]
    public string EstadoConservacao { get; init; } = EstadosConservacao.Novo;

    public DateTime? DataAquisicao { get; init; }
    public DateTime? PrazoGarantia { get; init; }

    [Range(0, 100, ErrorMessage = "A vida útil estimada deve estar entre 0 e 100 anos.")]
    public int? VidaUtilEstimadaAnos { get; init; }

    [Range(1, int.MaxValue, ErrorMessage = "Informe o ambiente (AmbienteId) do ativo.")]
    public int AmbienteId { get; init; }
}

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
