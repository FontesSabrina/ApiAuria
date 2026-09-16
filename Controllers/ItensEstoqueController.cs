using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using AuriaAPI.Application.DTOs;
using AuriaAPI.Application.Services;
using AuriaAPI.Common;

namespace AuriaAPI.Controllers;

// Corrigido: faltava [Authorize] - antes, todos os endpoints de estoque
// estavam publicos, diferente do resto da API.
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ItensEstoqueController : ControllerBase
{
    private readonly ItemEstoqueService _itemEstoqueService;

    public ItensEstoqueController(ItemEstoqueService itemEstoqueService)
    {
        _itemEstoqueService = itemEstoqueService;
    }

    [HttpGet]
    public async Task<IActionResult> ObterTodos()
    {
        var itens = await _itemEstoqueService.ObterTodosAsync();
        return Ok(Result<IEnumerable<ItemEstoqueResponseDto>>.SuccessResult(itens, "Itens de estoque recuperados com sucesso."));
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> ObterPorId(int id)
    {
        var item = await _itemEstoqueService.ObterPorIdAsync(id);
        if (item == null)
            return NotFound(Result<object>.FailureResult("Item de estoque não encontrado."));

        return Ok(Result<ItemEstoqueResponseDto>.SuccessResult(item, "Item de estoque recuperado com sucesso."));
    }

    [HttpPost]
    public async Task<IActionResult> Criar([FromBody] CriarItemEstoqueDto dto)
    {
        var criado = await _itemEstoqueService.CriarAsync(dto);
        return CreatedAtAction(nameof(ObterPorId), new { id = criado.Id }, Result<ItemEstoqueResponseDto>.SuccessResult(criado, "Item de estoque criado com sucesso."));
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Atualizar(int id, [FromBody] AtualizarItemEstoqueDto dto)
    {
        var atualizado = await _itemEstoqueService.AtualizarAsync(id, dto);
        if (atualizado == null)
            return NotFound(Result<object>.FailureResult("Item de estoque não encontrado."));

        return Ok(Result<ItemEstoqueResponseDto>.SuccessResult(atualizado, "Item de estoque atualizado com sucesso."));
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Deletar(int id)
    {
        var sucesso = await _itemEstoqueService.DeletarAsync(id);
        if (!sucesso)
            return NotFound(Result<object>.FailureResult("Item de estoque não encontrado."));

        return Ok(Result<object>.SuccessResult(null, "Item de estoque removido com sucesso."));
    }
}
