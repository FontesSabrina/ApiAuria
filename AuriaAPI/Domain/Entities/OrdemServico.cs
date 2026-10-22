using AuriaAPI.Domain.Exceptions;

namespace AuriaAPI.Domain.Entities;

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

    public bool EstaConcluida => DataConclusao.HasValue;

    /// <summary>Custo das peças usadas (quantidade × custo unitário atual de cada item).</summary>
    public decimal CustoPecas => OrdensServicoItens.Sum(i => i.QuantidadeUtilizada * (i.ItemEstoque?.CustoUnitario ?? 0m));

    public decimal CustoTotal => CustoMaoObra + CustoPecas;

    /// <summary>
    /// Registra o consumo de uma peça nesta ordem de serviço, debitando o estoque.
    /// Se a peça já foi usada antes nesta OS, a quantidade é somada ao registro existente.
    /// </summary>
    public void RegistrarConsumo(ItemEstoque item, int quantidade)
    {
        if (EstaConcluida)
            throw new RegraDeNegocioException("Não é possível registrar consumo de peças em uma ordem de serviço já concluída.");

        item.Debitar(quantidade);

        var existente = OrdensServicoItens.FirstOrDefault(i => i.ItemEstoqueId == item.Id);
        if (existente != null)
        {
            existente.QuantidadeUtilizada += quantidade;
            return;
        }

        OrdensServicoItens.Add(new OrdemServicoItemEstoque
        {
            ItemEstoqueId = item.Id,
            ItemEstoque = item,
            QuantidadeUtilizada = quantidade
        });
    }

    public void Concluir(int? tempoGastoMinutos, string? parecerTecnico, decimal? custoMaoObra)
    {
        if (EstaConcluida)
            throw new RegraDeNegocioException("Esta ordem de serviço já foi concluída.");

        if (tempoGastoMinutos.HasValue) TempoGastoMinutos = tempoGastoMinutos.Value;
        if (parecerTecnico != null) ParecerTecnico = parecerTecnico;
        if (custoMaoObra.HasValue) CustoMaoObra = custoMaoObra.Value;

        DataConclusao = DateTime.UtcNow;
        Chamado?.Concluir();
    }
}
