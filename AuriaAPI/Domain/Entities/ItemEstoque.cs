using AuriaAPI.Domain.Exceptions;

namespace AuriaAPI.Domain.Entities;

public class ItemEstoque
{
    public int Id { get; set; }
    public string Nome { get; set; } = string.Empty;
    public string CodigoInterno { get; set; } = string.Empty;
    public int QuantidadeEstoque { get; set; } = 0;
    public int EstoqueMinimo { get; set; } = 5;
    public decimal CustoUnitario { get; set; } = 0.00m;

    public ICollection<OrdemServicoItemEstoque> OrdensServicoItens { get; set; } = new List<OrdemServicoItemEstoque>();

    public bool EstaAbaixoDoMinimo => QuantidadeEstoque <= EstoqueMinimo;

    public void Debitar(int quantidade)
    {
        if (quantidade <= 0)
            throw new RegraDeNegocioException($"A quantidade utilizada do item '{Nome}' deve ser maior que zero.");

        if (quantidade > QuantidadeEstoque)
            throw new RegraDeNegocioException($"Estoque insuficiente para o item '{Nome}' (disponível: {QuantidadeEstoque}, solicitado: {quantidade}).");

        QuantidadeEstoque -= quantidade;
    }
}
