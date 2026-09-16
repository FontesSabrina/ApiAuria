using AuriaAPI.Models;
using AuriaAPI.Infra.EF;
using AuriaAPI.Common; // Importante para o Result Wrapper
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace AuriaAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class OrdemServicoController : ControllerBase
{
    private readonly AuriaDbContext _context;

    public OrdemServicoController(AuriaDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> ObterTodas()
    {
        var ordens = await _context.OrdensServico
            .Include(os => os.Chamado)
            .Include(os => os.Tecnico)
            .Select(os => new
            {
                os.Id,
                os.ChamadoId,
                os.TecnicoId,
                TecnicoNome = os.Tecnico != null ? os.Tecnico.Nome : null,
                os.TempoGastoMinutos,
                os.ParecerTecnico,
                os.CustoMaoObra,
                os.DataInicio,
                os.DataConclusao,
                StatusChamado = os.Chamado != null ? os.Chamado.Status : null
            })
            .ToListAsync();

        return Ok(Result<object>.SuccessResult(ordens, "Ordens de serviço recuperadas com sucesso."));
    }

    // ADICIONADO: Necessário para o CreatedAtAction do método Criar funcionar corretamente
    [HttpGet("{id}")]
    public async Task<IActionResult> ObterPorId(int id)
    {
        var ordemServico = await _context.OrdensServico
            .Include(os => os.Chamado)
            .Include(os => os.Tecnico)
            .Where(os => os.Id == id)
            .Select(os => new
            {
                os.Id,
                os.ChamadoId,
                os.TecnicoId,
                TecnicoNome = os.Tecnico != null ? os.Tecnico.Nome : null,
                os.TempoGastoMinutos,
                os.ParecerTecnico,
                os.CustoMaoObra,
                os.DataInicio,
                os.DataConclusao,
                StatusChamado = os.Chamado != null ? os.Chamado.Status : null
            })
            .FirstOrDefaultAsync();

        if (ordemServico == null)
            return NotFound(Result<object>.FailureResult("Ordem de serviço não encontrada."));

        return Ok(Result<object>.SuccessResult(ordemServico, "Ordem de serviço recuperada com sucesso."));
    }

    [HttpPost]
    public async Task<IActionResult> Criar([FromBody] OrdemServicoRequest request)
    {
        var chamado = await _context.Chamados.FindAsync(request.ChamadoId);
        if (chamado == null) 
            return NotFound(Result<object>.FailureResult("Chamado não encontrado."));

        var tecnico = await _context.Usuarios.FindAsync(request.TecnicoId);
        if (tecnico == null) 
            return NotFound(Result<object>.FailureResult("Técnico não encontrado."));

        var ordemServico = new OrdemServico
        {
            ChamadoId = request.ChamadoId,
            TecnicoId = request.TecnicoId,
            TempoGastoMinutos = request.TempoGastoMinutos,
            ParecerTecnico = request.ParecerTecnico,
            CustoMaoObra = request.CustoMaoObra,
            DataInicio = DateTime.UtcNow
        };

        chamado.Status = "Em Execucao";

        _context.OrdensServico.Add(ordemServico);
        await _context.SaveChangesAsync();

        var resposta = new
        {
            ordemServico.Id,
            ordemServico.ChamadoId,
            ordemServico.TecnicoId,
            TecnicoNome = tecnico.Nome,
            ordemServico.TempoGastoMinutos,
            ordemServico.ParecerTecnico,
            ordemServico.CustoMaoObra,
            ordemServico.DataInicio,
            ordemServico.DataConclusao,
            StatusChamado = chamado.Status
        };

        return CreatedAtAction(nameof(ObterPorId), new { id = ordemServico.Id }, Result<object>.SuccessResult(resposta, "Ordem de serviço criada com sucesso."));
    }

    [HttpPut("{id}/concluir")]
    public async Task<IActionResult> Concluir(int id)
    {
        var ordemServico = await _context.OrdensServico
            .Include(os => os.Chamado)
            .FirstOrDefaultAsync(os => os.Id == id);

        if (ordemServico == null) 
            return NotFound(Result<object>.FailureResult("Ordem de serviço não encontrada."));

        ordemServico.DataConclusao = DateTime.UtcNow;
        if (ordemServico.Chamado != null)
        {
            ordemServico.Chamado.Status = "Concluido";
            ordemServico.Chamado.DataFechamento = DateTime.UtcNow;
        }

        await _context.SaveChangesAsync();
        return Ok(Result<object>.SuccessResult(null, "Ordem de serviço concluída com sucesso."));
    }
}

public class OrdemServicoRequest
{
    public int ChamadoId { get; set; }
    public int TecnicoId { get; set; }
    public int TempoGastoMinutos { get; set; } = 0;
    public string? ParecerTecnico { get; set; }
    public decimal CustoMaoObra { get; set; } = 0.00m;
}