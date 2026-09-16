using AuriaAPI.Application.DTOs;
using AuriaAPI.Infra.EF;
using AuriaAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace AuriaAPI.Application.Services;

public class NotificacaoService
{
    private readonly AuriaDbContext _context;

    public NotificacaoService(AuriaDbContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<NotificacaoResponseDto>> ObterTodasAsync()
    {
        var notificacoes = await _context.Notificacoes
            .Include(n => n.Usuario)
            .ToListAsync();

        return notificacoes.Select(MapearParaDto);
    }

    public async Task<NotificacaoResponseDto?> ObterPorIdAsync(int id)
    {
        var notificacao = await _context.Notificacoes
            .Include(n => n.Usuario)
            .FirstOrDefaultAsync(n => n.Id == id);

        return notificacao == null ? null : MapearParaDto(notificacao);
    }

    public async Task<NotificacaoResponseDto> CriarAsync(CriarNotificacaoDto dto)
    {
        var notificacao = new Notificacao
        {
            Titulo = dto.Titulo,
            Mensagem = dto.Mensagem,
            UsuarioId = dto.UsuarioId,
            DataCriacao = DateTime.UtcNow,
            Lida = false
        };

        _context.Notificacoes.Add(notificacao);
        await _context.SaveChangesAsync();

        var criada = await _context.Notificacoes
            .Include(n => n.Usuario)
            .FirstOrDefaultAsync(n => n.Id == notificacao.Id);

        return MapearParaDto(criada!);
    }

    public async Task<bool> MarcarComoLidaAsync(int id)
    {
        var notificacao = await _context.Notificacoes.FindAsync(id);
        if (notificacao == null) return false;

        notificacao.Lida = true;
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> DeletarAsync(int id)
    {
        var notificacao = await _context.Notificacoes.FindAsync(id);
        if (notificacao == null) return false;

        _context.Notificacoes.Remove(notificacao);
        await _context.SaveChangesAsync();
        return true;
    }

    private static NotificacaoResponseDto MapearParaDto(Notificacao n) => new(
        n.Id,
        n.Titulo,
        n.Mensagem,
        n.DataCriacao,
        n.Lida,
        n.UsuarioId,
        n.Usuario?.Nome
    );
}
