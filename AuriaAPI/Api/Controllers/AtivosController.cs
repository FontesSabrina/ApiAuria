using AuriaAPI.Application.DTOs;
using AuriaAPI.Application.Interfaces;
using AuriaAPI.Domain.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AuriaAPI.Api.Controllers;

[Route("api/ativos")]
[Authorize]
public class AtivosController : ApiControllerBase
{
    private readonly IAtivoService _ativoService;

    public AtivosController(IAtivoService ativoService) => _ativoService = ativoService;

    /// <summary>Lista os ativos. Filtro opcional: ?ambienteId=1</summary>
    [HttpGet]
    public async Task<IActionResult> ObterTodos([FromQuery] int? ambienteId) =>
        Sucesso(await _ativoService.ObterTodosAsync(ambienteId), "Ativos recuperados com sucesso.");

    [HttpGet("{id:int}")]
    public async Task<IActionResult> ObterPorId(int id) =>
        Sucesso(await _ativoService.ObterPorIdAsync(id), "Ativo recuperado com sucesso.");

    [HttpPost]
    [Authorize(Roles = Perfis.Admin)]
    public async Task<IActionResult> Criar([FromBody] SalvarAtivoDto dto)
    {
        var criado = await _ativoService.CriarAsync(dto);
        return Criado(nameof(ObterPorId), new { id = criado.Id }, criado, "Ativo criado com sucesso.");
    }

    [HttpPut("{id:int}")]
    [Authorize(Roles = Perfis.Admin)]
    public async Task<IActionResult> Atualizar(int id, [FromBody] SalvarAtivoDto dto) =>
        Sucesso(await _ativoService.AtualizarAsync(id, dto), "Ativo atualizado com sucesso.");

    [HttpDelete("{id:int}")]
    [Authorize(Roles = Perfis.Admin)]
    public async Task<IActionResult> Remover(int id)
    {
        await _ativoService.RemoverAsync(id);
        return Sucesso("Ativo removido com sucesso.");
    }
}
