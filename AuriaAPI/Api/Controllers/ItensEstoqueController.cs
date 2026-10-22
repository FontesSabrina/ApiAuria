using AuriaAPI.Application.DTOs;
using AuriaAPI.Application.Interfaces;
using AuriaAPI.Domain.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AuriaAPI.Api.Controllers;

[Route("api/itensestoque")]
[Authorize]
public class ItensEstoqueController : ApiControllerBase
{
    private readonly IItemEstoqueService _itemEstoqueService;

    public ItensEstoqueController(IItemEstoqueService itemEstoqueService) => _itemEstoqueService = itemEstoqueService;

    [HttpGet]
    public async Task<IActionResult> ObterTodos() =>
        Sucesso(await _itemEstoqueService.ObterTodosAsync(), "Itens de estoque recuperados com sucesso.");

    /// <summary>Itens com quantidade menor ou igual ao estoque mínimo.</summary>
    [HttpGet("criticos")]
    public async Task<IActionResult> ObterCriticos() =>
        Sucesso(await _itemEstoqueService.ObterAbaixoDoMinimoAsync(), "Itens abaixo do estoque mínimo recuperados com sucesso.");

    [HttpGet("{id:int}")]
    public async Task<IActionResult> ObterPorId(int id) =>
        Sucesso(await _itemEstoqueService.ObterPorIdAsync(id), "Item de estoque recuperado com sucesso.");

    [HttpPost]
    [Authorize(Roles = Perfis.Admin)]
    public async Task<IActionResult> Criar([FromBody] SalvarItemEstoqueDto dto)
    {
        var criado = await _itemEstoqueService.CriarAsync(dto);
        return Criado(nameof(ObterPorId), new { id = criado.Id }, criado, "Item de estoque criado com sucesso.");
    }

    [HttpPut("{id:int}")]
    [Authorize(Roles = Perfis.Admin)]
    public async Task<IActionResult> Atualizar(int id, [FromBody] SalvarItemEstoqueDto dto) =>
        Sucesso(await _itemEstoqueService.AtualizarAsync(id, dto), "Item de estoque atualizado com sucesso.");

    [HttpDelete("{id:int}")]
    [Authorize(Roles = Perfis.Admin)]
    public async Task<IActionResult> Remover(int id)
    {
        await _itemEstoqueService.RemoverAsync(id);
        return Sucesso("Item de estoque removido com sucesso.");
    }
}
