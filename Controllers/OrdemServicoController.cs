using AuriaAPI.Application.DTOs;
using AuriaAPI.Application.Services;
using AuriaAPI.Common;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AuriaAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class OrdemServicoController : ControllerBase
{
    private readonly OrdemServicoService _ordemServicoService;

    public OrdemServicoController(OrdemServicoService ordemServicoService)
    {
        _ordemServicoService = ordemServicoService;
    }

    [HttpGet]
    public async Task<IActionResult> ObterTodas()
    {
        var ordens = await _ordemServicoService.ObterTodasAsync();
        return Ok(Result<IEnumerable<OrdemServicoResponseDto>>.SuccessResult(ordens, "Ordens de serviço recuperadas com sucesso."));
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> ObterPorId(int id)
    {
        var ordemServico = await _ordemServicoService.ObterPorIdAsync(id);
        if (ordemServico == null)
            return NotFound(Result<object>.FailureResult("Ordem de serviço não encontrada."));

        return Ok(Result<OrdemServicoResponseDto>.SuccessResult(ordemServico, "Ordem de serviço recuperada com sucesso."));
    }

    // Abrir uma ordem de serviço é uma atividade técnica: só Tecnico/Admin podem assumir um chamado.
    [HttpPost]
    [Authorize(Roles = "Tecnico,Admin")]
    public async Task<IActionResult> Criar([FromBody] CriarOrdemServicoDto dto)
    {
        var chamado = await _ordemServicoService.ObterChamadoAsync(dto.ChamadoId);
        if (chamado == null)
            return NotFound(Result<object>.FailureResult("Chamado não encontrado."));

        var tecnico = await _ordemServicoService.ObterTecnicoAsync(dto.TecnicoId);
        if (tecnico == null)
            return NotFound(Result<object>.FailureResult("Técnico não encontrado."));

        var (erroItens, itensEstoque) = await _ordemServicoService.ValidarItensAsync(dto.ItensUtilizados);
        if (erroItens != null)
            return BadRequest(Result<object>.FailureResult(erroItens));

        var criada = await _ordemServicoService.CriarAsync(dto, chamado, tecnico, itensEstoque);
        return CreatedAtAction(nameof(ObterPorId), new { id = criada.Id }, Result<OrdemServicoResponseDto>.SuccessResult(criada, "Ordem de serviço criada com sucesso."));
    }

    [HttpPut("{id}/concluir")]
    [Authorize(Roles = "Tecnico,Admin")]
    public async Task<IActionResult> Concluir(int id)
    {
        var sucesso = await _ordemServicoService.ConcluirAsync(id);
        if (!sucesso)
            return NotFound(Result<object>.FailureResult("Ordem de serviço não encontrada."));

        return Ok(Result<object>.SuccessResult(null, "Ordem de serviço concluída com sucesso."));
    }
}
