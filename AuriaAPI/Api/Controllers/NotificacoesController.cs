using AuriaAPI.Application.Common;
using AuriaAPI.Application.DTOs;
using AuriaAPI.Application.Interfaces;
using AuriaAPI.Domain.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AuriaAPI.Api.Controllers;

/// <summary>Cada usuário só vê e altera as próprias notificações (identificado pelo token).</summary>
[Route("api/notificacoes")]
[Authorize]
public class NotificacoesController : ApiControllerBase
{
    private readonly INotificacaoService _notificacaoService;

    public NotificacoesController(INotificacaoService notificacaoService) => _notificacaoService = notificacaoService;

    [HttpGet]
    public async Task<IActionResult> ObterMinhas() =>
        Sucesso(await _notificacaoService.ObterDoUsuarioAsync(UsuarioLogado.Id), "Notificações recuperadas com sucesso.");

    /// <summary>Envio manual de um aviso a um usuário (Admin).</summary>
    [HttpPost]
    [Authorize(Roles = Perfis.Admin)]
    public async Task<IActionResult> Criar([FromBody] CriarNotificacaoDto dto)
    {
        var criada = await _notificacaoService.CriarAsync(dto);
        return StatusCode(StatusCodes.Status201Created,
            Result<NotificacaoResponseDto>.SuccessResult(criada, "Notificação criada com sucesso."));
    }

    [HttpPut("{id:int}/lida")]
    public async Task<IActionResult> MarcarComoLida(int id)
    {
        await _notificacaoService.MarcarComoLidaAsync(id, UsuarioLogado);
        return Sucesso("Notificação marcada como lida.");
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Remover(int id)
    {
        await _notificacaoService.RemoverAsync(id, UsuarioLogado);
        return Sucesso("Notificação removida com sucesso.");
    }
}
