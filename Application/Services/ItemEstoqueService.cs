using AuriaAPI.Application.DTOs;
using AuriaAPI.Infra.EF;
using AuriaAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace AuriaAPI.Application.Services;

public class ItemEstoqueService
{
    private readonly AuriaDbContext _context;

    public ItemEstoqueService(AuriaDbContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<ItemEstoqueResponseDto>> ObterTodosAsync()
    {
        var itens = await _context.ItensEstoque.ToListAsync();
        return itens.Select(MapearParaDto);
    }

    public async Task<ItemEstoqueResponseDto?> ObterPorIdAsync(int id)
    {
        var item = await _context.ItensEstoque.FindAsync(id);
        return item == null ? null : MapearParaDto(item);
    }

    public async Task<ItemEstoqueResponseDto> CriarAsync(CriarItemEstoqueDto dto)
    {
        var item = new ItemEstoque
        {
            Nome = dto.Nome,
            CodigoInterno = dto.CodigoInterno,
            QuantidadeEstoque = dto.QuantidadeEstoque,
            EstoqueMinimo = dto.EstoqueMinimo,
            CustoUnitario = dto.CustoUnitario
        };

        _context.ItensEstoque.Add(item);
        await _context.SaveChangesAsync();

        return MapearParaDto(item);
    }

    public async Task<ItemEstoqueResponseDto?> AtualizarAsync(int id, AtualizarItemEstoqueDto dto)
    {
        var item = await _context.ItensEstoque.FindAsync(id);
        if (item == null) return null;

        item.Nome = dto.Nome;
        item.CodigoInterno = dto.CodigoInterno;
        item.QuantidadeEstoque = dto.QuantidadeEstoque;
        item.EstoqueMinimo = dto.EstoqueMinimo;
        item.CustoUnitario = dto.CustoUnitario;

        await _context.SaveChangesAsync();
        return MapearParaDto(item);
    }

    public async Task<bool> DeletarAsync(int id)
    {
        var item = await _context.ItensEstoque.FindAsync(id);
        if (item == null) return false;

        _context.ItensEstoque.Remove(item);
        await _context.SaveChangesAsync();
        return true;
    }

    private static ItemEstoqueResponseDto MapearParaDto(ItemEstoque i) => new(
        i.Id, i.Nome, i.CodigoInterno, i.QuantidadeEstoque, i.EstoqueMinimo, i.CustoUnitario
    );
}
