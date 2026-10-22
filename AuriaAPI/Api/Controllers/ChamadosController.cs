using AuriaAPI.Application.DTOs;
using AuriaAPI.Application.Interfaces;
using AuriaAPI.Domain.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AuriaAPI.Api.Controllers;

[Route("api/chamados")]
[Authorize]
public class ChamadosController : ApiControllerBase
{
    private readonly IChamadoService _chamadoService;

    public ChamadosController(IChamadoService chamadoService) => _chamadoService = chamadoService;

    /// <summary>Todos os chamados (técnicos e admins). Filtro opcional: ?status=Aberto</summary>
    [HttpGet]
    [Authorize(Roles = Perfis.TecnicoOuAdmin)]
    public async Task<IActionResult> ObterTodos([FromQuery] string? status) =>
        Sucesso(await _chamadoService.ObterTodosAsync(status), "Chamados recuperados com sucesso.");

    /// <summary>Chamados abertos pelo usuário logado.</summary>
    [HttpGet("meus")]
    public async Task<IActionResult> ObterMeus() =>
        Sucesso(await _chamadoService.ObterDoSolicitanteAsync(UsuarioLogado.Id), "Chamados recuperados com sucesso.");

    [HttpGet("{id:int}")]
    public async Task<IActionResult> ObterPorId(int id) =>
        Sucesso(await _chamadoService.ObterPorIdAsync(id, UsuarioLogado), "Chamado recuperado com sucesso.");

    /// <summary>Abre um chamado. O solicitante é sempre o usuário do token; os admins são notificados.</summary>
    [HttpPost]
    public async Task<IActionResult> Criar([FromBody] CriarChamadoDto dto)
    {
        var criado = await _chamadoService.CriarAsync(dto, UsuarioLogado);
        return Criado(nameof(ObterPorId), new { id = criado.Id }, criado, "Chamado criado com sucesso.");
    }

    /// <summary>Cancela um chamado ainda "Aberto" (admin ou o próprio solicitante).</summary>
    [HttpPut("{id:int}/cancelar")]
    public async Task<IActionResult> Cancelar(int id) =>
        Sucesso(await _chamadoService.CancelarAsync(id, UsuarioLogado), "Chamado cancelado com sucesso.");
}
