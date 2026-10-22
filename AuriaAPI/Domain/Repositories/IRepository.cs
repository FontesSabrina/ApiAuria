namespace AuriaAPI.Domain.Repositories;

/// <summary>
/// Operações básicas de persistência comuns a todas as entidades.
/// A gravação efetiva no banco é feita pelo <see cref="IUnitOfWork"/>, para que
/// uma operação que altera várias entidades seja salva de uma vez só.
/// </summary>
public interface IRepository<T> where T : class
{
    Task<IReadOnlyList<T>> ObterTodosAsync();
    Task<T?> ObterPorIdAsync(int id);
    Task<bool> ExisteAsync(int id);
    Task AdicionarAsync(T entidade);
    void Atualizar(T entidade);
    void Remover(T entidade);
}
