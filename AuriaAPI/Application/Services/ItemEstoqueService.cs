using AuriaAPI.Application.Common;
using AuriaAPI.Application.DTOs;
using AuriaAPI.Application.Exceptions;
using AuriaAPI.Application.Interfaces;
using AuriaAPI.Application.Mappings;
using AuriaAPI.Domain.Entities;
using AuriaAPI.Domain.Repositories;

namespace AuriaAPI.Application.Services;

public class ItemEstoqueService : IItemEstoqueService
{
    private readonly IItemEstoqueRepository _itens;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICacheService _cache;

    public ItemEstoqueService(IItemEstoqueRepository itens, IUnitOfWork unitOfWork, ICacheService cache)
    {
        _itens = itens;
        _unitOfWork = unitOfWork;
        _cache = cache;
    }

    public async Task<IReadOnlyList<ItemEstoqueResponseDto>> ObterTodosAsync()
    {
        var itens = await _itens.ObterTodosAsync();
        return itens.OrderBy(i => i.Nome).Select(i => i.ParaDto()).ToList();
    }

    public async Task<IReadOnlyList<ItemEstoqueResponseDto>> ObterAbaixoDoMinimoAsync()
    {
        var itens = await _itens.ObterAbaixoDoMinimoAsync();
        return itens.OrderBy(i => i.QuantidadeEstoque).Select(i => i.ParaDto()).ToList();
    }

    public async Task<ItemEstoqueResponseDto> ObterPorIdAsync(int id) => (await ObterEntidadeAsync(id)).ParaDto();

    public async Task<ItemEstoqueResponseDto> CriarAsync(SalvarItemEstoqueDto dto)
    {
        var item = new ItemEstoque();
        Preencher(item, dto);

        await _itens.AdicionarAsync(item);
        await _unitOfWork.SalvarAlteracoesAsync();
        return item.ParaDto();
    }

    public async Task<ItemEstoqueResponseDto> AtualizarAsync(int id, SalvarItemEstoqueDto dto)
    {
        var item = await ObterEntidadeAsync(id);
        Preencher(item, dto);

        await _unitOfWork.SalvarAlteracoesAsync();

        // O custo das peças entra no cálculo dos indicadores.
        _cache.Invalidar(ChavesCache.Indicadores);
        return item.ParaDto();
    }

    public async Task RemoverAsync(int id)
    {
        var item = await ObterEntidadeAsync(id);

        // Sem esta verificação, o banco apagaria em cascata o histórico de consumo das ordens de serviço.
        if (await _itens.FoiUtilizadoEmOrdemServicoAsync(id))
            throw new ConflitoException("Este item já foi utilizado em ordens de serviço e não pode ser excluído (o histórico de consumo seria perdido).");

        _itens.Remover(item);
        await _unitOfWork.SalvarAlteracoesAsync();
    }

    private async Task<ItemEstoque> ObterEntidadeAsync(int id) =>
        await _itens.ObterPorIdAsync(id) ?? throw new RecursoNaoEncontradoException("Item de estoque não encontrado.");

    private static void Preencher(ItemEstoque item, SalvarItemEstoqueDto dto)
    {
        item.Nome = dto.Nome.Trim();
        item.CodigoInterno = dto.CodigoInterno.Trim();
        item.QuantidadeEstoque = dto.QuantidadeEstoque;
        item.EstoqueMinimo = dto.EstoqueMinimo;
        item.CustoUnitario = dto.CustoUnitario;
    }
}
