using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using AuriaAPI.Application.DTOs;
using AuriaAPI.Application.Services;
using AuriaAPI.Common;

namespace AuriaAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class NotificacoesController : ControllerBase
{
    private readonly NotificacaoService _notificacaoService;

    public NotificacoesController(NotificacaoService notificacaoService)
    {
        _notificacaoService = notificacaoService;
    }

    [HttpGet]
    public async Task<IActionResult> ObterTodas()
    {
        var notificacoes = await _notificacaoService.ObterTodasAsync();
        return Ok(Result<IEnumerable<NotificacaoResponseDto>>.SuccessResult(notificacoes, "Notificações recuperadas com sucesso."));
    }

    // Corrigido: id agora é int, igual ao restante da API (a coluna no banco é inteira).
    [HttpGet("{id:int}")]
    public async Task<IActionResult> ObterPorId(int id)
    {
        var notificacao = await _notificacaoService.ObterPorIdAsync(id);
        if (notificacao == null)
            return NotFound(Result<object>.FailureResult("Notificação não encontrada."));

        return Ok(Result<NotificacaoResponseDto>.SuccessResult(notificacao, "Notificação recuperada com sucesso."));
    }

    [HttpPost]
    public async Task<IActionResult> Criar([FromBody] CriarNotificacaoDto dto)
    {
        var criada = await _notificacaoService.CriarAsync(dto);
        return CreatedAtAction(nameof(ObterPorId), new { id = criada.Id }, Result<NotificacaoResponseDto>.SuccessResult(criada, "Notificação criada com sucesso."));
    }

    [HttpPut("{id:int}/lida")]
    public async Task<IActionResult> MarcarComoLida(int id)
    {
        var sucesso = await _notificacaoService.MarcarComoLidaAsync(id);
        if (!sucesso)
            return NotFound(Result<object>.FailureResult("Notificação não encontrada."));

        return Ok(Result<object>.SuccessResult(null, "Notificação marcada como lida."));
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Deletar(int id)
    {
        var sucesso = await _notificacaoService.DeletarAsync(id);
        if (!sucesso)
            return NotFound(Result<object>.FailureResult("Notificação não encontrada."));

        return Ok(Result<object>.SuccessResult(null, "Notificação removida com sucesso."));
    }
}
