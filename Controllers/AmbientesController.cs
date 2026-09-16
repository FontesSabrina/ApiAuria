using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using AuriaAPI.Application.DTOs;
using AuriaAPI.Application.Services;
using AuriaAPI.Common;

namespace AuriaAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class AmbientesController : ControllerBase
{
    private readonly AmbienteService _ambienteService;

    public AmbientesController(AmbienteService ambienteService)
    {
        _ambienteService = ambienteService;
    }

    [HttpGet]
    public async Task<IActionResult> ObterTodos()
    {
        var ambientes = await _ambienteService.ObterTodosAsync();
        return Ok(Result<IEnumerable<AmbienteResponseDto>>.SuccessResult(ambientes, "Ambientes recuperados com sucesso."));
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> ObterPorId(int id)
    {
        var ambiente = await _ambienteService.ObterPorIdAsync(id);
        if (ambiente == null)
            return NotFound(Result<object>.FailureResult("Ambiente não encontrado."));

        return Ok(Result<AmbienteResponseDto>.SuccessResult(ambiente, "Ambiente recuperado com sucesso."));
    }

    [HttpPost]
    public async Task<IActionResult> Criar([FromBody] CriarAmbienteDto dto)
    {
        var criado = await _ambienteService.CriarAsync(dto);
        return CreatedAtAction(nameof(ObterPorId), new { id = criado.Id }, Result<AmbienteResponseDto>.SuccessResult(criado, "Ambiente criado com sucesso."));
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Atualizar(int id, [FromBody] AtualizarAmbienteDto dto)
    {
        var atualizado = await _ambienteService.AtualizarAsync(id, dto);
        if (atualizado == null)
            return NotFound(Result<object>.FailureResult("Ambiente não encontrado."));

        return Ok(Result<AmbienteResponseDto>.SuccessResult(atualizado, "Ambiente atualizado com sucesso."));
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Deletar(int id)
    {
        var sucesso = await _ambienteService.DeletarAsync(id);
        if (!sucesso)
            return NotFound(Result<object>.FailureResult("Ambiente não encontrado."));

        return Ok(Result<object>.SuccessResult(null, "Ambiente removido com sucesso."));
    }
}
