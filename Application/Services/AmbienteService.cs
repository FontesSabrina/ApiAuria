using AuriaAPI.Application.DTOs;
using AuriaAPI.Infra.EF;
using AuriaAPI.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;

namespace AuriaAPI.Application.Services;

public class AmbienteService
{
    private readonly AuriaDbContext _context;
    private readonly IMemoryCache _cache;
    private const string CacheKeyAmbientes = "ambiente_list_cache";

    public AmbienteService(AuriaDbContext context, IMemoryCache cache)
    {
        _context = context;
        _cache = cache;
    }

    public async Task<IEnumerable<AmbienteResponseDto>> ObterTodosAsync()
    {
        if (!_cache.TryGetValue(CacheKeyAmbientes, out IEnumerable<AmbienteResponseDto>? ambientes))
        {
            var entidades = await _context.Ambientes.ToListAsync();
            ambientes = entidades.Select(MapearParaDto).ToList();

            var cacheEntryOptions = new MemoryCacheEntryOptions()
                .SetAbsoluteExpiration(TimeSpan.FromMinutes(5));

            _cache.Set(CacheKeyAmbientes, ambientes, cacheEntryOptions);
        }

        return ambientes!;
    }

    public async Task<AmbienteResponseDto?> ObterPorIdAsync(int id)
    {
        var ambiente = await _context.Ambientes.FindAsync(id);
        return ambiente == null ? null : MapearParaDto(ambiente);
    }

    public async Task<AmbienteResponseDto> CriarAsync(CriarAmbienteDto dto)
    {
        var ambiente = new Ambiente
        {
            Identificacao = dto.Identificacao,
            PredioBloco = dto.PredioBloco,
            Andar = dto.Andar,
            Observacoes = dto.Observacoes
        };

        _context.Ambientes.Add(ambiente);
        await _context.SaveChangesAsync();

        _cache.Remove(CacheKeyAmbientes);
        return MapearParaDto(ambiente);
    }

    public async Task<AmbienteResponseDto?> AtualizarAsync(int id, AtualizarAmbienteDto dto)
    {
        var ambiente = await _context.Ambientes.FindAsync(id);
        if (ambiente == null) return null;

        // Atualiza campo a campo (em vez de EntityState.Modified no objeto inteiro
        // vindo do cliente), evitando sobrescrever colunas que o DTO não expõe.
        ambiente.Identificacao = dto.Identificacao;
        ambiente.PredioBloco = dto.PredioBloco;
        ambiente.Andar = dto.Andar;
        ambiente.Observacoes = dto.Observacoes;

        await _context.SaveChangesAsync();

        _cache.Remove(CacheKeyAmbientes);
        return MapearParaDto(ambiente);
    }

    public async Task<bool> DeletarAsync(int id)
    {
        var ambiente = await _context.Ambientes.FindAsync(id);
        if (ambiente == null) return false;

        _context.Ambientes.Remove(ambiente);
        await _context.SaveChangesAsync();

        _cache.Remove(CacheKeyAmbientes);
        return true;
    }

    private static AmbienteResponseDto MapearParaDto(Ambiente a) => new(
        a.Id, a.Identificacao, a.PredioBloco, a.Andar, a.Observacoes
    );
}
