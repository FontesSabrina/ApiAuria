using AuriaAPI.Domain.Repository;
using AuriaAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace AuriaAPI.Infra.EF;

public class UsuarioRepositoryEF : RepositoryEF<Usuario>, IUsuarioRepository
{
    public UsuarioRepositoryEF(AuriaDbContext context) : base(context) { }

    public async Task<Usuario?> GetByEmailAsync(string email)
    {
        return await _context.Usuarios.FirstOrDefaultAsync(u => u.Email == email);
    }
}