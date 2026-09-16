namespace AuriaAPI.Models;

public class ItemEstoque
{
    public int Id { get; set; }
    public string Nome { get; set; } = string.Empty;
    public string CodigoInterno { get; set; } = string.Empty;
    public int QuantidadeEstoque { get; set; } = 0;
    public int EstoqueMinimo { get; set; } = 5;
    public decimal CustoUnitario { get; set; } = 0.00m;

    public ICollection<OrdemServicoItemEstoque> OrdensServicoItens { get; set; } = new List<OrdemServicoItemEstoque>();
}