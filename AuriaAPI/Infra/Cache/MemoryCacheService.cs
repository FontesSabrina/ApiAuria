using AuriaAPI.Application.Interfaces;
using Microsoft.Extensions.Caching.Memory;

namespace AuriaAPI.Infra.Cache;

/// <summary>
/// Cache em memória (IMemoryCache) com estratégia cache-aside e expiração absoluta.
/// Cada passo é registrado no log do console, para que fique claro na demonstração:
///   [CACHE MISS]       → o dado não estava no cache e foi buscado na fonte original (banco);
///   [CACHE HIT]        → o dado foi devolvido direto do cache, sem acessar o banco;
///   [CACHE ARMAZENADO] → o resultado buscado foi guardado no cache (com o tempo de expiração);
///   [CACHE INVALIDADO] → a chave foi removida porque os dados mudaram.
/// </summary>
public class MemoryCacheService : ICacheService
{
    private readonly IMemoryCache _cache;
    private readonly ILogger<MemoryCacheService> _logger;

    public MemoryCacheService(IMemoryCache cache, ILogger<MemoryCacheService> logger)
    {
        _cache = cache;
        _logger = logger;
    }

    public async Task<T> ObterOuCriarAsync<T>(string chave, Func<Task<T>> buscarNaFonte, TimeSpan expiracao)
    {
        if (_cache.TryGetValue(chave, out T? valorEmCache) && valorEmCache is not null)
        {
            _logger.LogInformation("[CACHE HIT] '{Chave}' devolvido do cache, sem consultar o banco.", chave);
            return valorEmCache;
        }

        _logger.LogInformation("[CACHE MISS] '{Chave}' não está no cache — buscando na fonte original (banco de dados).", chave);
        var valor = await buscarNaFonte();

        _cache.Set(chave, valor, new MemoryCacheEntryOptions { AbsoluteExpirationRelativeToNow = expiracao });
        _logger.LogInformation("[CACHE ARMAZENADO] '{Chave}' guardado no cache por {Minutos} minuto(s).", chave, expiracao.TotalMinutes);

        return valor;
    }

    public void Invalidar(string chave)
    {
        _cache.Remove(chave);
        _logger.LogInformation("[CACHE INVALIDADO] '{Chave}' removido do cache porque os dados foram alterados.", chave);
    }
}
