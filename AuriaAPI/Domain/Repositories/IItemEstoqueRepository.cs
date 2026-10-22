using AuriaAPI.Domain.Entities;

namespace AuriaAPI.Domain.Repositories;

public interface IItemEstoqueRepository : IRepository<ItemEstoque>
{
    Task<IReadOnlyList<ItemEstoque>> ObterAbaixoDoMinimoAsync();
    Task<IReadOnlyList<ItemEstoque>> ObterPorIdsAsync(IEnumerable<int> ids);
    Task<bool> FoiUtilizadoEmOrdemServicoAsync(int itemId);
}
