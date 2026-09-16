namespace AuriaAPI.Models;

public class Ambiente
{
    public int Id { get; set; }
    public string Identificacao { get; set; } = string.Empty;
    public string? PredioBloco { get; set; }
    public string? Andar { get; set; }
    public string? Observacoes { get; set; }

    public ICollection<Ativo> Ativos { get; set; } = new List<Ativo>();
}