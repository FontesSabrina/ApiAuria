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
            .Include(os => os.OrdensServicoItens)
                .ThenInclude(i => i.ItemEstoque)
            .ToListAsync();

        return ordens.Select(MapearParaDto);
    }

    public async Task<OrdemServicoResponseDto?> ObterPorIdAsync(int id)
    {
        var ordemServico = await _context.OrdensServico
            .Include(os => os.Chamado)
            .Include(os => os.Tecnico)
            .Include(os => os.OrdensServicoItens)
                .ThenInclude(i => i.ItemEstoque)
            .FirstOrDefaultAsync(os => os.Id == id);

        return ordemServico == null ? null : MapearParaDto(ordemServico);
    }

    public Task<Chamado?> ObterChamadoAsync(int chamadoId) =>
        _context.Chamados.FirstOrDefaultAsync(c => c.Id == chamadoId);

    public Task<Usuario?> ObterTecnicoAsync(int tecnicoId) =>
        _context.Usuarios.FirstOrDefaultAsync(u => u.Id == tecnicoId);

    // Confere existência, duplicidade e estoque disponível de cada item antes de qualquer
    // escrita. Retorna os ItemEstoque já carregados para CriarAsync reaproveitar (evita
    // buscar cada item duas vezes) e evita debitar estoque parcialmente em caso de erro.
    public async Task<(string? Erro, Dictionary<int, ItemEstoque> Itens)> ValidarItensAsync(
        IReadOnlyList<ItemUtilizadoDto>? itensUtilizados)
    {
        var itens = new Dictionary<int, ItemEstoque>();
        if (itensUtilizados == null || itensUtilizados.Count == 0)
            return (null, itens);

        var idsDuplicados = itensUtilizados
            .GroupBy(i => i.ItemEstoqueId)
            .Where(g => g.Count() > 1)
            .Select(g => g.Key)
            .ToList();
        if (idsDuplicados.Count > 0)
            return ($"ItemEstoqueId duplicado na lista de itens utilizados: {string.Join(", ", idsDuplicados)}.", itens);

        foreach (var item in itensUtilizados)
        {
            if (item.QuantidadeUtilizada <= 0)
                return ($"A quantidade utilizada do item {item.ItemEstoqueId} deve ser maior que zero.", itens);

            var itemEstoque = await _context.ItensEstoque.FindAsync(item.ItemEstoqueId);
            if (itemEstoque == null)
                return ($"Item de estoque {item.ItemEstoqueId} não encontrado.", itens);

            if (itemEstoque.QuantidadeEstoque < item.QuantidadeUtilizada)
                return ($"Estoque insuficiente para o item '{itemEstoque.Nome}' (disponível: {itemEstoque.QuantidadeEstoque}, solicitado: {item.QuantidadeUtilizada}).", itens);

            itens[item.ItemEstoqueId] = itemEstoque;
        }

        return (null, itens);
    }

    public async Task<OrdemServicoResponseDto> CriarAsync(
        CriarOrdemServicoDto dto, Chamado chamado, Usuario tecnico, Dictionary<int, ItemEstoque> itensEstoque)
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

        var itensUtilizadosResposta = new List<ItemUtilizadoResponseDto>();
        if (dto.ItensUtilizados != null)
        {
            foreach (var itemDto in dto.ItensUtilizados)
            {
                var itemEstoque = itensEstoque[itemDto.ItemEstoqueId];
                itemEstoque.QuantidadeEstoque -= itemDto.QuantidadeUtilizada;

                ordemServico.OrdensServicoItens.Add(new OrdemServicoItemEstoque
                {
                    ItemEstoqueId = itemDto.ItemEstoqueId,
                    QuantidadeUtilizada = itemDto.QuantidadeUtilizada
                });

                itensUtilizadosResposta.Add(new ItemUtilizadoResponseDto(itemDto.ItemEstoqueId, itemEstoque.Nome, itemDto.QuantidadeUtilizada));
            }
        }

        await _context.SaveChangesAsync();

        return new OrdemServicoResponseDto(
            ordemServico.Id, ordemServico.ChamadoId, ordemServico.TecnicoId, tecnico.Nome,
            ordemServico.TempoGastoMinutos, ordemServico.ParecerTecnico, ordemServico.CustoMaoObra,
            ordemServico.DataInicio, ordemServico.DataConclusao, chamado.Status, itensUtilizadosResposta
        );
    }

    public async Task<bool> ConcluirAsync(int id, ConcluirOrdemServicoDto? dto = null)
    {
        var ordemServico = await _context.OrdensServico
            .Include(os => os.Chamado)
            .FirstOrDefaultAsync(os => os.Id == id);

        if (ordemServico == null) return false;

        ordemServico.DataConclusao = DateTime.UtcNow;
        if (dto?.TempoGastoMinutos is int tempoGasto) ordemServico.TempoGastoMinutos = tempoGasto;
        if (dto?.ParecerTecnico is string parecer) ordemServico.ParecerTecnico = parecer;
        if (dto?.CustoMaoObra is decimal custo) ordemServico.CustoMaoObra = custo;

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
        os.DataInicio, os.DataConclusao, os.Chamado?.Status,
        os.OrdensServicoItens
            .Select(i => new ItemUtilizadoResponseDto(i.ItemEstoqueId, i.ItemEstoque?.Nome, i.QuantidadeUtilizada))
            .ToList()
    );
}
