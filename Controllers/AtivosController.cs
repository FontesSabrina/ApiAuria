using AuriaAPI.Application.DTOs;
using AuriaAPI.Application.Services;
using AuriaAPI.Common;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AuriaAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class AtivosController : ControllerBase
{
    private readonly AtivoService _ativoService;

    public AtivosController(AtivoService ativoService)
    {
        _ativoService = ativoService;
    }

    [HttpGet]
    public async Task<IActionResult> ObterTodos()
    {
        var ativos = await _ativoService.ObterTodosAsync();
        return Ok(Result<IEnumerable<AtivoResponseDto>>.SuccessResult(ativos, "Ativos recuperados com sucesso."));
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> ObterPorId(int id)
    {
        var ativo = await _ativoService.ObterPorIdAsync(id);
        if (ativo == null)
            return NotFound(Result<object>.FailureResult("Ativo não encontrado."));

        return Ok(Result<AtivoResponseDto>.SuccessResult(ativo, "Ativo recuperado com sucesso."));
    }

    [HttpPost]
    public async Task<IActionResult> Criar([FromBody] CriarAtivoDto dto)
    {
        if (!await _ativoService.AmbienteExisteAsync(dto.AmbienteId))
            return BadRequest(Result<object>.FailureResult("AmbienteId informado não existe."));

        var criado = await _ativoService.CriarAsync(dto);
        return CreatedAtAction(nameof(ObterPorId), new { id = criado.Id }, Result<AtivoResponseDto>.SuccessResult(criado, "Ativo criado com sucesso."));
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Atualizar(int id, [FromBody] AtualizarAtivoDto dto)
    {
        if (!await _ativoService.AmbienteExisteAsync(dto.AmbienteId))
            return BadRequest(Result<object>.FailureResult("AmbienteId informado não existe."));

        var atualizado = await _ativoService.AtualizarAsync(id, dto);
        if (atualizado == null)
            return NotFound(Result<object>.FailureResult("Ativo não encontrado."));

        return Ok(Result<AtivoResponseDto>.SuccessResult(atualizado, "Ativo atualizado com sucesso."));
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Deletar(int id)
    {
        var sucesso = await _ativoService.DeletarAsync(id);
        if (!sucesso)
            return NotFound(Result<object>.FailureResult("Ativo não encontrado."));

        return Ok(Result<object>.SuccessResult(null, "Ativo removido com sucesso."));
    }
}
