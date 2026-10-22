using AuriaAPI.Domain.Entities;

namespace AuriaAPI.Domain.Repositories;

public interface IAmbienteRepository : IRepository<Ambiente>
{
    Task<bool> PossuiAtivosAsync(int ambienteId);
}
