using AuriaAPI.Domain.Entities;

namespace AuriaAPI.Domain.Repositories;

public interface IOrdemServicoRepository : IRepository<OrdemServico>
{
    Task<IReadOnlyList<OrdemServico>> ObterComDetalhesAsync(int? tecnicoId = null);
    Task<OrdemServico?> ObterComDetalhesPorIdAsync(int id);
}
