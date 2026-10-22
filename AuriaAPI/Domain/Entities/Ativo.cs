using AuriaAPI.Domain.Constants;

namespace AuriaAPI.Domain.Entities;

public class Ativo
{
    public int Id { get; set; }
    public string Patrimonio { get; set; } = string.Empty;
    public string Nome { get; set; } = string.Empty;
    public string EstadoConservacao { get; set; } = EstadosConservacao.Novo;

    public DateTime? DataAquisicao { get; set; }
    public DateTime? PrazoGarantia { get; set; }
    public int? VidaUtilEstimadaAnos { get; set; }

    public int AmbienteId { get; set; }
    public Ambiente? Ambiente { get; set; }

    public ICollection<Chamado> Chamados { get; set; } = new List<Chamado>();

    /// <summary>
    /// Motivos pelos quais o ativo precisa de atenção preventiva
    /// (estado de conservação ruim e/ou tempo de uso elevado). Lista vazia = sem alerta.
    /// </summary>
    public IReadOnlyList<string> MotivosAlertaPreventiva(DateTime agoraUtc)
    {
        var motivos = new List<string>();
        if (EstadoConservacao == EstadosConservacao.Desativado)
            return motivos;

        if (EstadosConservacao.QueGeramAlerta.Contains(EstadoConservacao))
            motivos.Add($"Estado de conservação: {EstadoConservacao}");

        if (DataAquisicao.HasValue && (agoraUtc - DataAquisicao.Value).TotalDays > EstadosConservacao.DiasUsoParaAlerta)
            motivos.Add($"Mais de {EstadosConservacao.DiasUsoParaAlerta / 365} anos de uso");

        if (PrazoGarantia.HasValue && PrazoGarantia.Value < agoraUtc)
            motivos.Add("Garantia vencida");

        return motivos;
    }
}
