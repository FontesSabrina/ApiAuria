using AuriaAPI.Domain.Repositories;

namespace AuriaAPI.Infra.EF;

/// <summary>
/// Todos os repositórios de uma requisição compartilham o mesmo DbContext (registrado como Scoped),
/// então um único SaveChanges grava tudo o que foi alterado — numa transação só.
/// </summary>
public class EfUnitOfWork : IUnitOfWork
{
    private readonly AuriaDbContext _context;

    public EfUnitOfWork(AuriaDbContext context) => _context = context;

    public Task<int> SalvarAlteracoesAsync() => _context.SaveChangesAsync();
}
