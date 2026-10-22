using AuriaAPI.Application.Interfaces;
using AuriaAPI.Domain.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AuriaAPI.Api.Controllers;

[Route("api/indicadores")]
[Authorize(Roles = Perfis.Admin)]
public class IndicadoresController : ApiControllerBase
{
    private readonly IIndicadorService _indicadorService;

    public IndicadoresController(IIndicadorService indicadorService) => _indicadorService = indicadorService;

    /// <summary>Indicadores do painel de BI (em cache por 2 minutos; o campo geradoEm mostra quando foram calculados).</summary>
    [HttpGet]
    public async Task<IActionResult> ObterResumo() =>
        Sucesso(await _indicadorService.ObterResumoAsync(), "Indicadores calculados com sucesso.");
}
