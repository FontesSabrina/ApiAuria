using AuriaAPI.Application.Common;
using AuriaAPI.Application.DTOs;
using AuriaAPI.Application.Exceptions;
using AuriaAPI.Application.Interfaces;
using AuriaAPI.Application.Mappings;
using AuriaAPI.Domain.Entities;
using AuriaAPI.Domain.Repositories;

namespace AuriaAPI.Application.Services;

/// <summary>
/// Estratégia de cache (cache-aside): a lista de ambientes muda pouco e é consultada em várias telas
/// (cadastro de ativos, lista de ambientes). Ela fica 5 minutos em cache e é invalidada sempre que
/// um ambiente é criado, alterado ou removido.
/// </summary>
public class AmbienteService : IAmbienteService
{
    private static readonly TimeSpan ExpiracaoCache = TimeSpan.FromMinutes(5);

    private readonly IAmbienteRepository _ambientes;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICacheService _cache;

    public AmbienteService(IAmbienteRepository ambientes, IUnitOfWork unitOfWork, ICacheService cache)
    {
        _ambientes = ambientes;
        _unitOfWork = unitOfWork;
        _cache = cache;
    }

    public Task<IReadOnlyList<AmbienteResponseDto>> ObterTodosAsync() =>
        _cache.ObterOuCriarAsync<IReadOnlyList<AmbienteResponseDto>>(
            ChavesCache.ListaAmbientes,
            async () =>
            {
                var ambientes = await _ambientes.ObterTodosAsync();
                return ambientes.OrderBy(a => a.Identificacao).Select(a => a.ParaDto()).ToList();
            },
            ExpiracaoCache);

    public async Task<AmbienteResponseDto> ObterPorIdAsync(int id) => (await ObterEntidadeAsync(id)).ParaDto();

    public async Task<AmbienteResponseDto> CriarAsync(SalvarAmbienteDto dto)
    {
        var ambiente = new Ambiente();
        Preencher(ambiente, dto);

        await _ambientes.AdicionarAsync(ambiente);
        await _unitOfWork.SalvarAlteracoesAsync();

        _cache.Invalidar(ChavesCache.ListaAmbientes);
        return ambiente.ParaDto();
    }

    public async Task<AmbienteResponseDto> AtualizarAsync(int id, SalvarAmbienteDto dto)
    {
        var ambiente = await ObterEntidadeAsync(id);
        Preencher(ambiente, dto);

        await _unitOfWork.SalvarAlteracoesAsync();

        _cache.Invalidar(ChavesCache.ListaAmbientes);
        return ambiente.ParaDto();
    }

    public async Task RemoverAsync(int id)
    {
        var ambiente = await ObterEntidadeAsync(id);

        if (await _ambientes.PossuiAtivosAsync(id))
            throw new ConflitoException("Este ambiente possui ativos vinculados. Transfira ou remova os ativos antes de excluí-lo.");

        _ambientes.Remover(ambiente);
        await _unitOfWork.SalvarAlteracoesAsync();

        _cache.Invalidar(ChavesCache.ListaAmbientes);
    }

    private async Task<Ambiente> ObterEntidadeAsync(int id) =>
        await _ambientes.ObterPorIdAsync(id) ?? throw new RecursoNaoEncontradoException("Ambiente não encontrado.");

    private static void Preencher(Ambiente ambiente, SalvarAmbienteDto dto)
    {
        ambiente.Identificacao = dto.Identificacao.Trim();
        ambiente.PredioBloco = dto.PredioBloco;
        ambiente.Andar = dto.Andar;
        ambiente.Observacoes = dto.Observacoes;
    }
}
