using AuriaAPI.Domain.Entities;

namespace AuriaAPI.Domain.Repositories;

public interface IUsuarioRepository : IRepository<Usuario>
{
    Task<Usuario?> ObterPorEmailAsync(string email);
    Task<bool> EmailEmUsoAsync(string email, int? ignorarUsuarioId = null);
    Task<IReadOnlyList<Usuario>> ObterPorPerfilAsync(string perfil);
    Task<bool> ExisteAlgumComPerfilAsync(string perfil);
    Task<bool> PossuiVinculosAsync(int usuarioId);
}
