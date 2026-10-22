using AuriaAPI.Application.DTOs;
using AuriaAPI.Application.Interfaces;
using AuriaAPI.Domain.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AuriaAPI.Api.Controllers;

[Route("api/ambientes")]
[Authorize]
public class AmbientesController : ApiControllerBase
{
    private readonly IAmbienteService _ambienteService;

    public AmbientesController(IAmbienteService ambienteService) => _ambienteService = ambienteService;

    /// <summary>Lista os ambientes (resultado em cache por 5 minutos — veja o log do console).</summary>
    [HttpGet]
    public async Task<IActionResult> ObterTodos() =>
        Sucesso(await _ambienteService.ObterTodosAsync(), "Ambientes recuperados com sucesso.");

    [HttpGet("{id:int}")]
    public async Task<IActionResult> ObterPorId(int id) =>
        Sucesso(await _ambienteService.ObterPorIdAsync(id), "Ambiente recuperado com sucesso.");

    [HttpPost]
    [Authorize(Roles = Perfis.Admin)]
    public async Task<IActionResult> Criar([FromBody] SalvarAmbienteDto dto)
    {
        var criado = await _ambienteService.CriarAsync(dto);
        return Criado(nameof(ObterPorId), new { id = criado.Id }, criado, "Ambiente criado com sucesso.");
    }

    [HttpPut("{id:int}")]
    [Authorize(Roles = Perfis.Admin)]
    public async Task<IActionResult> Atualizar(int id, [FromBody] SalvarAmbienteDto dto) =>
        Sucesso(await _ambienteService.AtualizarAsync(id, dto), "Ambiente atualizado com sucesso.");

    [HttpDelete("{id:int}")]
    [Authorize(Roles = Perfis.Admin)]
    public async Task<IActionResult> Remover(int id)
    {
        await _ambienteService.RemoverAsync(id);
        return Sucesso("Ambiente removido com sucesso.");
    }
}
