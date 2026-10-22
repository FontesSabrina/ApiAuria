namespace AuriaAPI.Application.Interfaces;

/// <summary>
/// Abstração do cache usada pelos services. A implementação (Infra/Cache) registra em log
/// quando o dado vem da fonte original, quando vem do cache e quando o cache é invalidado.
/// </summary>
public interface ICacheService
{
    /// <summary>Retorna o valor do cache; se não existir (ou expirou), executa <paramref name="buscarNaFonte"/> e guarda o resultado.</summary>
    Task<T> ObterOuCriarAsync<T>(string chave, Func<Task<T>> buscarNaFonte, TimeSpan expiracao);

    /// <summary>Remove a chave do cache, forçando a próxima leitura a buscar na fonte.</summary>
    void Invalidar(string chave);
}
