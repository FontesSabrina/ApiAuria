using System.ComponentModel.DataAnnotations;

namespace AuriaAPI.Application.DTOs;

public class ItemUtilizadoDto
{
    [Range(1, int.MaxValue, ErrorMessage = "Informe o item de estoque (ItemEstoqueId).")]
    public int ItemEstoqueId { get; init; }

    [Range(1, int.MaxValue, ErrorMessage = "A quantidade utilizada deve ser maior que zero.")]
    public int QuantidadeUtilizada { get; init; }
}

public class CriarOrdemServicoDto
{
    [Range(1, int.MaxValue, ErrorMessage = "Informe o chamado (ChamadoId).")]
    public int ChamadoId { get; init; }

    [Range(1, int.MaxValue, ErrorMessage = "Informe o técnico responsável (TecnicoId).")]
    public int TecnicoId { get; init; }

    [Range(0, int.MaxValue, ErrorMessage = "O tempo gasto não pode ser negativo.")]
    public int TempoGastoMinutos { get; init; }

    [StringLength(2000, ErrorMessage = "O parecer técnico deve ter no máximo 2000 caracteres.")]
    public string? ParecerTecnico { get; init; }

    [Range(0.0, 99999999.0, ErrorMessage = "O custo de mão de obra não pode ser negativo.")]
    public decimal CustoMaoObra { get; init; }

    /// <summary>Opcional: peças já usadas na abertura da OS (debitadas do estoque).</summary>
    public List<ItemUtilizadoDto>? ItensUtilizados { get; init; }
}

/// <summary>POST /api/ordemservico/{id}/itens — registra o consumo de peças numa OS em andamento.</summary>
public class RegistrarConsumoDto
{
    [Required(ErrorMessage = "Informe ao menos um item.")]
    [MinLength(1, ErrorMessage = "Informe ao menos um item.")]
    public List<ItemUtilizadoDto> Itens { get; init; } = new();
}

/// <summary>Todos os campos são opcionais: só são gravados os que forem informados.</summary>
public class ConcluirOrdemServicoDto
{
    [Range(0, int.MaxValue, ErrorMessage = "O tempo gasto não pode ser negativo.")]
    public int? TempoGastoMinutos { get; init; }

    [StringLength(2000, ErrorMessage = "O parecer técnico deve ter no máximo 2000 caracteres.")]
    public string? ParecerTecnico { get; init; }

    [Range(0.0, 99999999.0, ErrorMessage = "O custo de mão de obra não pode ser negativo.")]
    public decimal? CustoMaoObra { get; init; }
}

public record ItemUtilizadoResponseDto(int ItemEstoqueId, string? ItemNome, int QuantidadeUtilizada, decimal CustoUnitario, decimal Subtotal);

public record OrdemServicoResponseDto(
    int Id,
    int ChamadoId,
    int TecnicoId,
    string? TecnicoNome,
    int TempoGastoMinutos,
    string? ParecerTecnico,
    decimal CustoMaoObra,
    decimal CustoPecas,
    decimal CustoTotal,
    DateTime DataInicio,
    DateTime? DataConclusao,
    bool Concluida,
    string? StatusChamado,
    string? DescricaoProblema,
    string? Prioridade,
    string? TipoManutencao,
    DateTime? DataAbertura,
    int? AtivoId,
    string? AtivoNome,
    int? SolicitanteId,
    string? SolicitanteNome,
    IReadOnlyList<ItemUtilizadoResponseDto> ItensUtilizados
);
