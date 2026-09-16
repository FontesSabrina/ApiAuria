using AuriaAPI.Domain.Repository;
using AuriaAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace AuriaAPI.Infra.EF;

public class ChamadoRepositoryEF : RepositoryEF<Chamado>, IChamadoRepository
{
    public ChamadoRepositoryEF(AuriaDbContext context) : base(context) { }

    public async Task<IEnumerable<Chamado>> GetChamadosComDetalhesAsync()
    {
        return await _context.Chamados
            .Include(c => c.Solicitante)
            .Include(c => c.Ativo!)
                .ThenInclude(a => a.Ambiente)
            .ToListAsync();
    }

    public async Task<Chamado?> GetChamadoComDetalhesByIdAsync(int id)
    {
        return await _context.Chamados
            .Include(c => c.Solicitante)
            .Include(c => c.Ativo!)
                .ThenInclude(a => a.Ambiente)
            .FirstOrDefaultAsync(c => c.Id == id);
    }
}