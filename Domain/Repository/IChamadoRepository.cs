using AuriaAPI.Models;

namespace AuriaAPI.Domain.Repository;

public interface IChamadoRepository : IRepository<Chamado>
{
    Task<IEnumerable<Chamado>> GetChamadosComDetalhesAsync();
    Task<Chamado?> GetChamadoComDetalhesByIdAsync(int id);
}