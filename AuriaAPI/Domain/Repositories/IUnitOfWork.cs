namespace AuriaAPI.Domain.Repositories;

/// <summary>Confirma (salva) no banco todas as alterações feitas pelos repositórios na requisição atual.</summary>
public interface IUnitOfWork
{
    Task<int> SalvarAlteracoesAsync();
}
