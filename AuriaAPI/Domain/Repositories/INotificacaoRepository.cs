using AuriaAPI.Domain.Entities;

namespace AuriaAPI.Domain.Repositories;

public interface INotificacaoRepository : IRepository<Notificacao>
{
    Task<IReadOnlyList<Notificacao>> ObterDoUsuarioAsync(int usuarioId);
}
