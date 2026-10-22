using AuriaAPI.Application.Common;
using AuriaAPI.Application.DTOs;
using AuriaAPI.Application.Exceptions;
using AuriaAPI.Application.Interfaces;
using AuriaAPI.Application.Mappings;
using AuriaAPI.Domain.Entities;
using AuriaAPI.Domain.Exceptions;
using AuriaAPI.Domain.Repositories;

namespace AuriaAPI.Application.Services;

/// <summary>
/// Implementa as duas interfaces de notificação:
/// <see cref="INotificacaoService"/> (endpoints do usuário) e <see cref="INotificador"/>
/// (notificações automáticas geradas pelos outros services).
/// </summary>
public class NotificacaoService : INotificacaoService, INotificador
{
    private readonly INotificacaoRepository _notificacoes;
    private readonly IUsuarioRepository _usuarios;
    private readonly IUnitOfWork _unitOfWork;

    public NotificacaoService(INotificacaoRepository notificacoes, IUsuarioRepository usuarios, IUnitOfWork unitOfWork)
    {
        _notificacoes = notificacoes;
        _usuarios = usuarios;
        _unitOfWork = unitOfWork;
    }

    public async Task<IReadOnlyList<NotificacaoResponseDto>> ObterDoUsuarioAsync(int usuarioId)
    {
        var notificacoes = await _notificacoes.ObterDoUsuarioAsync(usuarioId);
        return notificacoes.Select(n => n.ParaDto()).ToList();
    }

    public async Task<NotificacaoResponseDto> CriarAsync(CriarNotificacaoDto dto)
    {
        var destinatario = await _usuarios.ObterPorIdAsync(dto.UsuarioId)
            ?? throw new RegraDeNegocioException("O usuário informado (UsuarioId) não existe.");

        var notificacao = Notificacao.Criar(destinatario.Id, dto.Titulo.Trim(), dto.Mensagem.Trim());
        notificacao.Usuario = destinatario;

        await _notificacoes.AdicionarAsync(notificacao);
        await _unitOfWork.SalvarAlteracoesAsync();
        return notificacao.ParaDto();
    }

    public async Task MarcarComoLidaAsync(int id, UsuarioLogado usuarioLogado)
    {
        var notificacao = await ObterDoUsuarioLogadoAsync(id, usuarioLogado);
        notificacao.Lida = true;
        await _unitOfWork.SalvarAlteracoesAsync();
    }

    public async Task RemoverAsync(int id, UsuarioLogado usuarioLogado)
    {
        var notificacao = await ObterDoUsuarioLogadoAsync(id, usuarioLogado);
        _notificacoes.Remover(notificacao);
        await _unitOfWork.SalvarAlteracoesAsync();
    }

    public Task NotificarUsuarioAsync(int usuarioId, string titulo, string mensagem) =>
        _notificacoes.AdicionarAsync(Notificacao.Criar(usuarioId, titulo, mensagem));

    public async Task NotificarPerfilAsync(string perfil, string titulo, string mensagem)
    {
        foreach (var usuario in await _usuarios.ObterPorPerfilAsync(perfil))
            await _notificacoes.AdicionarAsync(Notificacao.Criar(usuario.Id, titulo, mensagem));
    }

    /// <summary>Uma notificação de outra pessoa é tratada como "não encontrada" para não revelar que ela existe.</summary>
    private async Task<Notificacao> ObterDoUsuarioLogadoAsync(int id, UsuarioLogado usuarioLogado)
    {
        var notificacao = await _notificacoes.ObterPorIdAsync(id);
        if (notificacao == null || notificacao.UsuarioId != usuarioLogado.Id)
            throw new RecursoNaoEncontradoException("Notificação não encontrada.");
        return notificacao;
    }
}
