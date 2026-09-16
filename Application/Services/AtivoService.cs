using AuriaAPI.Application.DTOs;
using AuriaAPI.Infra.EF;
using AuriaAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace AuriaAPI.Application.Services;

public class AtivoService
{
    private readonly AuriaDbContext _context;

    public AtivoService(AuriaDbContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<AtivoResponseDto>> ObterTodosAsync()
    {
        var ativos = await _context.Ativos.Include(a => a.Ambiente).ToListAsync();
        return ativos.Select(MapearParaDto);
    }

    public async Task<AtivoResponseDto?> ObterPorIdAsync(int id)
    {
        var ativo = await _context.Ativos.Include(a => a.Ambiente).FirstOrDefaultAsync(a => a.Id == id);
        return ativo == null ? null : MapearParaDto(ativo);
    }

    public Task<bool> AmbienteExisteAsync(int ambienteId) =>
        _context.Ambientes.AnyAsync(a => a.Id == ambienteId);

    public async Task<AtivoResponseDto> CriarAsync(CriarAtivoDto dto)
    {
        var ativo = new Ativo
        {
            Patrimonio = dto.Patrimonio,
            Nome = dto.Nome,
            EstadoConservacao = dto.EstadoConservacao,
            DataAquisicao = dto.DataAquisicao,
            PrazoGarantia = dto.PrazoGarantia,
            VidaUtilEstimadaAnos = dto.VidaUtilEstimadaAnos,
            AmbienteId = dto.AmbienteId
        };

        _context.Ativos.Add(ativo);
        await _context.SaveChangesAsync();

        await _context.Entry(ativo).Reference(a => a.Ambiente).LoadAsync();
        return MapearParaDto(ativo);
    }

    public async Task<AtivoResponseDto?> AtualizarAsync(int id, AtualizarAtivoDto dto)
    {
        var ativo = await _context.Ativos.Include(a => a.Ambiente).FirstOrDefaultAsync(a => a.Id == id);
        if (ativo == null) return null;

        ativo.Patrimonio = dto.Patrimonio;
        ativo.Nome = dto.Nome;
        ativo.EstadoConservacao = dto.EstadoConservacao;
        ativo.DataAquisicao = dto.DataAquisicao;
        ativo.PrazoGarantia = dto.PrazoGarantia;
        ativo.VidaUtilEstimadaAnos = dto.VidaUtilEstimadaAnos;
        ativo.AmbienteId = dto.AmbienteId;

        await _context.SaveChangesAsync();

        if (ativo.Ambiente?.Id != dto.AmbienteId)
            await _context.Entry(ativo).Reference(a => a.Ambiente).LoadAsync();

        return MapearParaDto(ativo);
    }

    public async Task<bool> DeletarAsync(int id)
    {
        var ativo = await _context.Ativos.FindAsync(id);
        if (ativo == null) return false;

        _context.Ativos.Remove(ativo);
        await _context.SaveChangesAsync();
        return true;
    }

    private static AtivoResponseDto MapearParaDto(Ativo a) => new(
        a.Id, a.Patrimonio, a.Nome, a.EstadoConservacao,
        a.DataAquisicao, a.PrazoGarantia, a.VidaUtilEstimadaAnos,
        a.AmbienteId, a.Ambiente?.Identificacao
    );
}
