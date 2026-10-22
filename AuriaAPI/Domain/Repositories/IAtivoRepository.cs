using AuriaAPI.Domain.Entities;

namespace AuriaAPI.Domain.Repositories;

public interface IAtivoRepository : IRepository<Ativo>
{
    Task<IReadOnlyList<Ativo>> ObterTodosComAmbienteAsync();
    Task<Ativo?> ObterComAmbienteAsync(int id);
    Task<bool> PossuiChamadosAsync(int ativoId);
}
