using System.ComponentModel.DataAnnotations;

namespace AuriaAPI.Application.DTOs;

/// <summary>Corpo usado tanto na criação (POST) quanto na atualização (PUT) de um item de estoque.</summary>
public class SalvarItemEstoqueDto
{
    [Required(ErrorMessage = "O nome do item é obrigatório.")]
    [StringLength(100, ErrorMessage = "O nome deve ter no máximo 100 caracteres.")]
    public string Nome { get; init; } = string.Empty;

    [Required(ErrorMessage = "O código interno é obrigatório.")]
    [StringLength(100, ErrorMessage = "O código interno deve ter no máximo 100 caracteres.")]
    public string CodigoInterno { get; init; } = string.Empty;

    [Range(0, int.MaxValue, ErrorMessage = "A quantidade em estoque não pode ser negativa.")]
    public int QuantidadeEstoque { get; init; }

    [Range(0, int.MaxValue, ErrorMessage = "O estoque mínimo não pode ser negativo.")]
    public int EstoqueMinimo { get; init; }

    [Range(0.0, 99999999.0, ErrorMessage = "O custo unitário não pode ser negativo.")]
    public decimal CustoUnitario { get; init; }
}

public record ItemEstoqueResponseDto(
    int Id,
    string Nome,
    string CodigoInterno,
    int QuantidadeEstoque,
    int EstoqueMinimo,
    decimal CustoUnitario,
    bool AbaixoDoMinimo
);
