using System.Security.Claims;
using AuriaAPI.Application.DTOs;
using AuriaAPI.Application.Services;
using AuriaAPI.Common; // Importante para o Result Wrapper
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AuriaAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ChamadosController : ControllerBase
{
    private readonly ChamadoService _chamadoService;

    public ChamadosController(ChamadoService chamadoService)
    {
        _chamadoService = chamadoService;
    }

    [HttpGet]
    public async Task<IActionResult> ObterTodos()
    {
        var chamados = await _chamadoService.ObterTodosAsync();
        return Ok(Result<object>.SuccessResult(chamados, "Chamados recuperados com sucesso."));
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> ObterPorId(int id)
    {
        var chamado = await _chamadoService.ObterPorIdAsync(id);
        if (chamado == null) 
            return NotFound(Result<object>.FailureResult("Chamado não encontrado."));
            
        return Ok(Result<object>.SuccessResult(chamado, "Chamado recuperado com sucesso."));
    }

    [HttpPost]
    public async Task<IActionResult> Criar([FromBody] CriarChamadoDto dto)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userIdClaim == null || !int.TryParse(userIdClaim, out int solicitanteId))
            return Unauthorized(Result<object>.FailureResult("Usuário não autenticado ou ID inválido."));

        var chamado = await _chamadoService.CriarAsync(dto, solicitanteId);
        return CreatedAtAction(nameof(ObterPorId), new { id = chamado.Id }, Result<object>.SuccessResult(chamado, "Chamado criado com sucesso."));
    }

    [HttpPut("{id}/cancelar")]
    public async Task<IActionResult> Cancelar(int id)
    {
        var sucesso = await _chamadoService.CancelarAsync(id);
        if (!sucesso)
            return NotFound(Result<object>.FailureResult("Chamado não encontrado."));

        return Ok(Result<object>.SuccessResult(null, "Chamado cancelado com sucesso."));
    }
}