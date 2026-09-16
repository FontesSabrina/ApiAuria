using AuriaAPI.Domain.Repository;
using Microsoft.EntityFrameworkCore;

namespace AuriaAPI.Infra.EF;

public class RepositoryEF<T> : IRepository<T> where T : class
{
    protected readonly AuriaDbContext _context;

    public RepositoryEF(AuriaDbContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<T>> GetAllAsync() => await _context.Set<T>().ToListAsync();

    public async Task<T?> GetByIdAsync(int id) => await _context.Set<T>().FindAsync(id);

    public async Task AddAsync(T entity) => await _context.Set<T>().AddAsync(entity);

    public void Update(T entity) => _context.Set<T>().Update(entity);

    public void Delete(T entity) => _context.Set<T>().Remove(entity);

    public async Task<bool> SaveChangesAsync() => await _context.SaveChangesAsync() > 0;
}