using AuriaAPI.Application.DTOs;
using AuriaAPI.Infra.EF;
using AuriaAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace AuriaAPI.Application.Services;

public class OrdemServicoService
{
    private readonly AuriaDbContext _context;

    public OrdemServicoService(AuriaDbContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<OrdemServicoResponseDto>> ObterTodasAsync()
    {
        var ordens = await _context.OrdensServico
            .Include(os => os.Chamado)
            .Include(os => os.Tecnico)
            .ToListAsync();

        return ordens.Select(MapearParaDto);
    }

    public async Task<OrdemServicoResponseDto?> ObterPorIdAsync(int id)
    {
        var ordemServico = await _context.OrdensServico
            .Include(os => os.Chamado)
            .Include(os => os.Tecnico)
            .FirstOrDefaultAsync(os => os.Id == id);

        return ordemServico == null ? null : MapearParaDto(ordemServico);
    }

    public Task<Chamado?> ObterChamadoAsync(int chamadoId) =>
        _context.Chamados.FirstOrDefaultAsync(c => c.Id == chamadoId);

    public Task<Usuario?> ObterTecnicoAsync(int tecnicoId) =>
        _context.Usuarios.FirstOrDefaultAsync(u => u.Id == tecnicoId);

    public async Task<OrdemServicoResponseDto> CriarAsync(CriarOrdemServicoDto dto, Chamado chamado, Usuario tecnico)
    {
        var ordemServico = new OrdemServico
        {
            ChamadoId = dto.ChamadoId,
            TecnicoId = dto.TecnicoId,
            TempoGastoMinutos = dto.TempoGastoMinutos,
            ParecerTecnico = dto.ParecerTecnico,
            CustoMaoObra = dto.CustoMaoObra,
            DataInicio = DateTime.UtcNow
        };

        chamado.Status = "Em Execucao";

        _context.OrdensServico.Add(ordemServico);
        await _context.SaveChangesAsync();

        return new OrdemServicoResponseDto(
            ordemServico.Id, ordemServico.ChamadoId, ordemServico.TecnicoId, tecnico.Nome,
            ordemServico.TempoGastoMinutos, ordemServico.ParecerTecnico, ordemServico.CustoMaoObra,
            ordemServico.DataInicio, ordemServico.DataConclusao, chamado.Status
        );
    }

    public async Task<bool> ConcluirAsync(int id)
    {
        var ordemServico = await _context.OrdensServico
            .Include(os => os.Chamado)
            .FirstOrDefaultAsync(os => os.Id == id);

        if (ordemServico == null) return false;

        ordemServico.DataConclusao = DateTime.UtcNow;
        if (ordemServico.Chamado != null)
        {
            ordemServico.Chamado.Status = "Concluido";
            ordemServico.Chamado.DataFechamento = DateTime.UtcNow;
        }

        await _context.SaveChangesAsync();
        return true;
    }

    private static OrdemServicoResponseDto MapearParaDto(OrdemServico os) => new(
        os.Id, os.ChamadoId, os.TecnicoId, os.Tecnico?.Nome,
        os.TempoGastoMinutos, os.ParecerTecnico, os.CustoMaoObra,
        os.DataInicio, os.DataConclusao, os.Chamado?.Status
    );
}
