using AuriaAPI.Domain.Repositories;
using Microsoft.EntityFrameworkCore;

namespace AuriaAPI.Infra.EF.Repositories;

/// <summary>Implementação genérica (Entity Framework Core) das operações comuns de <see cref="IRepository{T}"/>.</summary>
public class RepositoryEF<T> : IRepository<T> where T : class
{
    protected readonly AuriaDbContext _context;
    protected readonly DbSet<T> _dbSet;

    public RepositoryEF(AuriaDbContext context)
    {
        _context = context;
        _dbSet = context.Set<T>();
    }

    public async Task<IReadOnlyList<T>> ObterTodosAsync() => await _dbSet.ToListAsync();

    public async Task<T?> ObterPorIdAsync(int id) => await _dbSet.FindAsync(id);

    public async Task<bool> ExisteAsync(int id) => await _dbSet.FindAsync(id) != null;

    public async Task AdicionarAsync(T entidade) => await _dbSet.AddAsync(entidade);

    public void Atualizar(T entidade) => _dbSet.Update(entidade);

    public void Remover(T entidade) => _dbSet.Remove(entidade);
}
