using AuriaAPI.Models;

namespace AuriaAPI.Domain.Repository;

public interface IUsuarioRepository : IRepository<Usuario>
{
    Task<Usuario?> GetByEmailAsync(string email);
}