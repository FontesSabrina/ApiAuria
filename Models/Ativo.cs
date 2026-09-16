namespace AuriaAPI.Models;

public class Ativo
{
    public int Id { get; set; }
    public string Patrimonio { get; set; } = string.Empty;
    public string Nome { get; set; } = string.Empty;
    public string EstadoConservacao { get; set; } = "Novo";
    
    public DateTime? DataAquisicao { get; set; }
    public DateTime? PrazoGarantia { get; set; }
    public int? VidaUtilEstimadaAnos { get; set; }

    public int AmbienteId { get; set; }
    public Ambiente? Ambiente { get; set; }

    public ICollection<Chamado> Chamados { get; set; } = new List<Chamado>();
}