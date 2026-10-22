using AuriaAPI.Domain.Entities;

namespace AuriaAPI.Domain.Repositories;

public interface IChamadoRepository : IRepository<Chamado>
{
    Task<IReadOnlyList<Chamado>> ObterComDetalhesAsync(string? status = null, int? solicitanteId = null);
    Task<Chamado?> ObterComDetalhesPorIdAsync(int id);
}
