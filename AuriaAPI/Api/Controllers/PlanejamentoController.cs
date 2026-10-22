using AuriaAPI.Application.Interfaces;
using AuriaAPI.Domain.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AuriaAPI.Api.Controllers;

[Route("api/planejamento")]
[Authorize(Roles = Perfis.Admin)]
public class PlanejamentoController : ApiControllerBase
{
    private readonly IPlanejamentoService _planejamentoService;

    public PlanejamentoController(IPlanejamentoService planejamentoService) => _planejamentoService = planejamentoService;

    /// <summary>Ordens de serviço de manutenções preventivas de um dia. Ex.: ?data=2026-10-22 (padrão: hoje).</summary>
    [HttpGet("cronograma")]
    public async Task<IActionResult> ObterCronograma([FromQuery] DateOnly? data) =>
        Sucesso(await _planejamentoService.ObterCronogramaPreventivasAsync(data ?? DateOnly.FromDateTime(DateTime.Now)),
            "Cronograma de preventivas recuperado com sucesso.");

    /// <summary>Ativos que precisam de manutenção preventiva (estado de conservação, tempo de uso ou garantia vencida).</summary>
    [HttpGet("alertas")]
    public async Task<IActionResult> ObterAlertas() =>
        Sucesso(await _planejamentoService.ObterAlertasAsync(), "Alertas de manutenção preventiva recuperados com sucesso.");
}
