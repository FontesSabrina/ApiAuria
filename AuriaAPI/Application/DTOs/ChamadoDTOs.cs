using System.ComponentModel.DataAnnotations;
using AuriaAPI.Domain.Constants;

namespace AuriaAPI.Application.DTOs;

public class CriarChamadoDto
{
    [Required(ErrorMessage = "A descrição do problema é obrigatória.")]
    [StringLength(1000, MinimumLength = 5, ErrorMessage = "A descrição deve ter entre 5 e 1000 caracteres.")]
    public string Descricao { get; init; } = string.Empty;

    [Required(ErrorMessage = "A prioridade é obrigatória.")]
    [AllowedValues(Prioridades.Baixa, Prioridades.Media, Prioridades.Alta, ErrorMessage = "Prioridade inválida. Valores aceitos: Baixa, Média, Alta.")]
    public string Prioridade { get; init; } = Prioridades.Baixa;

    [Range(1, int.MaxValue, ErrorMessage = "Informe o ativo (AtivoId) do chamado.")]
    public int AtivoId { get; init; }

    [Required(ErrorMessage = "O tipo de manutenção é obrigatório.")]
    [AllowedValues(TiposManutencao.Corretiva, TiposManutencao.Preventiva, TiposManutencao.Preditiva,
        ErrorMessage = "Tipo de manutenção inválido. Valores aceitos: Corretiva, Preventiva, Preditiva.")]
    public string TipoManutencao { get; init; } = TiposManutencao.Corretiva;

    [StringLength(300, ErrorMessage = "A localização detalhada deve ter no máximo 300 caracteres.")]
    public string? LocalizacaoDetalhada { get; init; }
}

public record ChamadoResponseDto(
    int Id,
    string Descricao,
    string TipoManutencao,
    string Prioridade,
    string Status,
    DateTime DataAbertura,
    DateTime? DataFechamento,
    int SolicitanteId,
    string SolicitanteNome,
    int? OrdemServicoId,
    int? TecnicoId,
    string? TecnicoNome,
    int AtivoId,
    string? AtivoNome,
    string AmbienteNome,
    string? LocalizacaoDetalhada
);
