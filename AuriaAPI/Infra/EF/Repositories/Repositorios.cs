using AuriaAPI.Domain.Entities;
using AuriaAPI.Domain.Repositories;
using Microsoft.EntityFrameworkCore;

namespace AuriaAPI.Infra.EF.Repositories;

public class UsuarioRepositoryEF : RepositoryEF<Usuario>, IUsuarioRepository
{
    public UsuarioRepositoryEF(AuriaDbContext context) : base(context) { }

    public Task<Usuario?> ObterPorEmailAsync(string email) =>
        _dbSet.FirstOrDefaultAsync(u => u.Email == email);

    public Task<bool> EmailEmUsoAsync(string email, int? ignorarUsuarioId = null) =>
        _dbSet.AnyAsync(u => u.Email == email && (ignorarUsuarioId == null || u.Id != ignorarUsuarioId));

    public async Task<IReadOnlyList<Usuario>> ObterPorPerfilAsync(string perfil) =>
        await _dbSet.Where(u => u.Perfil == perfil).ToListAsync();

    public Task<bool> ExisteAlgumComPerfilAsync(string perfil) =>
        _dbSet.AnyAsync(u => u.Perfil == perfil);

    public async Task<bool> PossuiVinculosAsync(int usuarioId) =>
        await _context.Chamados.AnyAsync(c => c.SolicitanteId == usuarioId)
        || await _context.OrdensServico.AnyAsync(o => o.TecnicoId == usuarioId);
}

public class AmbienteRepositoryEF : RepositoryEF<Ambiente>, IAmbienteRepository
{
    public AmbienteRepositoryEF(AuriaDbContext context) : base(context) { }

    public Task<bool> PossuiAtivosAsync(int ambienteId) =>
        _context.Ativos.AnyAsync(a => a.AmbienteId == ambienteId);
}

public class AtivoRepositoryEF : RepositoryEF<Ativo>, IAtivoRepository
{
    public AtivoRepositoryEF(AuriaDbContext context) : base(context) { }

    public async Task<IReadOnlyList<Ativo>> ObterTodosComAmbienteAsync() =>
        await _dbSet.Include(a => a.Ambiente).ToListAsync();

    public Task<Ativo?> ObterComAmbienteAsync(int id) =>
        _dbSet.Include(a => a.Ambiente).FirstOrDefaultAsync(a => a.Id == id);

    public Task<bool> PossuiChamadosAsync(int ativoId) =>
        _context.Chamados.AnyAsync(c => c.AtivoId == ativoId);
}

public class ChamadoRepositoryEF : RepositoryEF<Chamado>, IChamadoRepository
{
    public ChamadoRepositoryEF(AuriaDbContext context) : base(context) { }

    public async Task<IReadOnlyList<Chamado>> ObterComDetalhesAsync(string? status = null, int? solicitanteId = null)
    {
        var consulta = ComDetalhes();
        if (status != null)
            consulta = consulta.Where(c => c.Status == status);
        if (solicitanteId != null)
            consulta = consulta.Where(c => c.SolicitanteId == solicitanteId);

        return await consulta.OrderByDescending(c => c.DataAbertura).ToListAsync();
    }

    public Task<Chamado?> ObterComDetalhesPorIdAsync(int id) =>
        ComDetalhes().FirstOrDefaultAsync(c => c.Id == id);

    private IQueryable<Chamado> ComDetalhes() => _dbSet
        .Include(c => c.Solicitante)
        .Include(c => c.Ativo!).ThenInclude(a => a.Ambiente)
        .Include(c => c.OrdensServico).ThenInclude(os => os.Tecnico)
        .AsSplitQuery();
}

public class ItemEstoqueRepositoryEF : RepositoryEF<ItemEstoque>, IItemEstoqueRepository
{
    public ItemEstoqueRepositoryEF(AuriaDbContext context) : base(context) { }

    public async Task<IReadOnlyList<ItemEstoque>> ObterAbaixoDoMinimoAsync() =>
        await _dbSet.Where(i => i.QuantidadeEstoque <= i.EstoqueMinimo).ToListAsync();

    public async Task<IReadOnlyList<ItemEstoque>> ObterPorIdsAsync(IEnumerable<int> ids)
    {
        var lista = ids.ToList();
        return await _dbSet.Where(i => lista.Contains(i.Id)).ToListAsync();
    }

    public Task<bool> FoiUtilizadoEmOrdemServicoAsync(int itemId) =>
        _context.OrdensServicoItens.AnyAsync(i => i.ItemEstoqueId == itemId);
}

public class NotificacaoRepositoryEF : RepositoryEF<Notificacao>, INotificacaoRepository
{
    public NotificacaoRepositoryEF(AuriaDbContext context) : base(context) { }

    public async Task<IReadOnlyList<Notificacao>> ObterDoUsuarioAsync(int usuarioId) =>
        await _dbSet
            .Include(n => n.Usuario)
            .Where(n => n.UsuarioId == usuarioId)
            .OrderByDescending(n => n.DataCriacao)
            .ToListAsync();
}

public class OrdemServicoRepositoryEF : RepositoryEF<OrdemServico>, IOrdemServicoRepository
{
    public OrdemServicoRepositoryEF(AuriaDbContext context) : base(context) { }

    public async Task<IReadOnlyList<OrdemServico>> ObterComDetalhesAsync(int? tecnicoId = null)
    {
        var consulta = ComDetalhes();
        if (tecnicoId != null)
            consulta = consulta.Where(o => o.TecnicoId == tecnicoId);

        return await consulta.OrderByDescending(o => o.DataInicio).ToListAsync();
    }

    public Task<OrdemServico?> ObterComDetalhesPorIdAsync(int id) =>
        ComDetalhes().FirstOrDefaultAsync(o => o.Id == id);

    private IQueryable<OrdemServico> ComDetalhes() => _dbSet
        .Include(o => o.Tecnico)
        .Include(o => o.Chamado!).ThenInclude(c => c.Ativo)
        .Include(o => o.Chamado!).ThenInclude(c => c.Solicitante)
        .Include(o => o.OrdensServicoItens).ThenInclude(i => i.ItemEstoque)
        .AsSplitQuery();
}
