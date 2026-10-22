namespace AuriaAPI.Domain.Entities;

public class OrdemServicoItemEstoque
{
    public int OrdemServicoId { get; set; }
    public OrdemServico? OrdemServico { get; set; }

    public int ItemEstoqueId { get; set; }
    public ItemEstoque? ItemEstoque { get; set; }

    public int QuantidadeUtilizada { get; set; }
}