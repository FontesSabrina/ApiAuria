using AuriaAPI.Application.DTOs;
using AuriaAPI.Application.Interfaces;
using AuriaAPI.Domain.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AuriaAPI.Api.Controllers;

/// <summary>Ordens de serviço — acessíveis apenas aos perfis Tecnico e Admin.</summary>
[Route("api/ordemservico")]
[Authorize(Roles = Perfis.TecnicoOuAdmin)]
public class OrdemServicoController : ApiControllerBase
{
    private readonly IOrdemServicoService _ordemServicoService;

    public OrdemServicoController(IOrdemServicoService ordemServicoService) => _ordemServicoService = ordemServicoService;

    [HttpGet]
    public async Task<IActionResult> ObterTodas() =>
        Sucesso(await _ordemServicoService.ObterTodasAsync(), "Ordens de serviço recuperadas com sucesso.");

    /// <summary>Ordens designadas ao técnico logado.</summary>
    [HttpGet("minhas")]
    public async Task<IActionResult> ObterMinhas() =>
        Sucesso(await _ordemServicoService.ObterDoTecnicoAsync(UsuarioLogado.Id), "Ordens de serviço recuperadas com sucesso.");

    [HttpGet("{id:int}")]
    public async Task<IActionResult> ObterPorId(int id) =>
        Sucesso(await _ordemServicoService.ObterPorIdAsync(id), "Ordem de serviço recuperada com sucesso.");

    /// <summary>Abre a OS de um chamado "Aberto", designando o técnico (o chamado passa a "Em Execucao").</summary>
    [HttpPost]
    public async Task<IActionResult> Criar([FromBody] CriarOrdemServicoDto dto)
    {
        var criada = await _ordemServicoService.CriarAsync(dto);
        return Criado(nameof(ObterPorId), new { id = criada.Id }, criada, "Ordem de serviço criada com sucesso.");
    }

    /// <summary>Registra peças consumidas na OS, debitando o estoque.</summary>
    [HttpPost("{id:int}/itens")]
    public async Task<IActionResult> RegistrarConsumo(int id, [FromBody] RegistrarConsumoDto dto) =>
        Sucesso(await _ordemServicoService.RegistrarConsumoAsync(id, dto, UsuarioLogado), "Consumo de peças registrado com sucesso.");

    /// <summary>Conclui a OS e o chamado vinculado. Corpo opcional: tempoGastoMinutos, parecerTecnico, custoMaoObra.</summary>
    [HttpPut("{id:int}/concluir")]
    public async Task<IActionResult> Concluir(int id, [FromBody] ConcluirOrdemServicoDto? dto) =>
        Sucesso(await _ordemServicoService.ConcluirAsync(id, dto ?? new ConcluirOrdemServicoDto(), UsuarioLogado), "Ordem de serviço concluída com sucesso.");
}
