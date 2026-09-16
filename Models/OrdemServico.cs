namespace AuriaAPI.Models;

public class OrdemServico
{
    public int Id { get; set; }
    public int ChamadoId { get; set; }
    public Chamado? Chamado { get; set; }

    public int TecnicoId { get; set; }
    public Usuario? Tecnico { get; set; }

    public int TempoGastoMinutos { get; set; }
    public string? ParecerTecnico { get; set; }
    public decimal CustoMaoObra { get; set; }

    public DateTime DataInicio { get; set; } = DateTime.UtcNow;
    public DateTime? DataConclusao { get; set; }

    public ICollection<OrdemServicoItemEstoque> OrdensServicoItens { get; set; } = new List<OrdemServicoItemEstoque>();
}
