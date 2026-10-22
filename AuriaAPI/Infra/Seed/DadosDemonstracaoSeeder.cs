using AuriaAPI.Application.Common;
using AuriaAPI.Application.Interfaces;
using AuriaAPI.Domain.Constants;
using AuriaAPI.Domain.Entities;
using AuriaAPI.Infra.EF;
using Microsoft.EntityFrameworkCore;

namespace AuriaAPI.Infra.Seed;

/// <summary>
/// Dados de demonstração para apresentar o sistema já "com vida": usuários de teste,
/// ambientes, ativos, itens de estoque e alguns chamados abertos.
///
/// Regras de segurança:
/// - só roda no ambiente de <b>Development</b> (nunca em produção);
/// - pode ser desligado com <c>"DadosDemonstracao:Ativar": false</c>;
/// - só cria o que ainda não existe (compara e-mail, nome do ambiente, patrimônio e nome do item),
///   então rodar a API várias vezes não duplica nada e não altera o que você cadastrou.
/// </summary>
public class DadosDemonstracaoSeeder
{
    private readonly AuriaDbContext _db;
    private readonly IPasswordHasher _passwordHasher;
    private readonly ICacheService _cache;
    private readonly IConfiguration _configuration;
    private readonly IHostEnvironment _ambiente;
    private readonly ILogger<DadosDemonstracaoSeeder> _logger;

    public DadosDemonstracaoSeeder(AuriaDbContext db, IPasswordHasher passwordHasher, ICacheService cache,
        IConfiguration configuration, IHostEnvironment ambiente, ILogger<DadosDemonstracaoSeeder> logger)
    {
        _db = db;
        _passwordHasher = passwordHasher;
        _cache = cache;
        _configuration = configuration;
        _ambiente = ambiente;
        _logger = logger;
    }

    public async Task ExecutarAsync()
    {
        if (!_ambiente.IsDevelopment() || !_configuration.GetValue("DadosDemonstracao:Ativar", false))
            return;

        var criados = 0;
        criados += await CriarUsuariosAsync();
        criados += await CriarAmbientesAsync();
        await _db.SaveChangesAsync();

        criados += await CriarAtivosAsync();
        criados += await CriarItensEstoqueAsync();
        await _db.SaveChangesAsync();

        criados += await CriarChamadosAsync();
        await _db.SaveChangesAsync();

        if (criados > 0)
        {
            _cache.Invalidar(ChavesCache.ListaAmbientes);
            _logger.LogInformation("[DEMO] {Quantidade} registros de demonstração criados.", criados);
        }
    }

    // ------------------------------------------------------------------ usuários

    private async Task<int> CriarUsuariosAsync()
    {
        var senha = _configuration["DadosDemonstracao:SenhaUsuarios"];
        if (string.IsNullOrWhiteSpace(senha))
        {
            _logger.LogWarning("[DEMO] 'DadosDemonstracao:SenhaUsuarios' vazio — usuários de demonstração não foram criados.");
            return 0;
        }

        var usuarios = new (string Nome, string Email, string Perfil)[]
        {
            ("Carlos Lima", "tecnico@auria.com", Perfis.Tecnico),
            ("Paula Souza", "tecnico2@auria.com", Perfis.Tecnico),
            ("Ana Martins", "solicitante@auria.com", Perfis.Solicitante),
            ("Bruno Costa", "solicitante2@auria.com", Perfis.Solicitante),
        };

        var criados = 0;
        foreach (var u in usuarios)
        {
            var email = Normalizacao.Email(u.Email);
            if (await _db.Usuarios.AnyAsync(x => x.Email == email)) continue;

            _db.Usuarios.Add(new Usuario { Nome = u.Nome, Email = email, Senha = _passwordHasher.GerarHash(senha), Perfil = u.Perfil });
            criados++;
        }
        return criados;
    }

    // ------------------------------------------------------------------ ambientes

    private static readonly (string Nome, string Bloco, string Andar, string? Obs)[] Ambientes =
    {
        ("Recepção", "Bloco A", "Térreo", "Entrada principal do prédio"),
        ("Sala 3", "Bloco A", "1º andar", null),
        ("Sala de Reuniões 1", "Bloco A", "1º andar", "Capacidade para 12 pessoas"),
        ("Copa", "Bloco A", "Térreo", null),
        ("Laboratório de Informática", "Bloco B", "2º andar", "30 computadores"),
        ("Auditório", "Bloco B", "Térreo", "Capacidade para 120 pessoas"),
        ("Almoxarifado", "Bloco C", "Subsolo", "Acesso restrito à manutenção"),
    };

    private async Task<int> CriarAmbientesAsync()
    {
        var existentes = await _db.Ambientes.Select(a => a.Identificacao.ToLower()).ToListAsync();
        var criados = 0;
        foreach (var a in Ambientes)
        {
            if (existentes.Contains(a.Nome.ToLower())) continue;
            _db.Ambientes.Add(new Ambiente { Identificacao = a.Nome, PredioBloco = a.Bloco, Andar = a.Andar, Observacoes = a.Obs });
            criados++;
        }
        return criados;
    }

    // ------------------------------------------------------------------ ativos

    private async Task<int> CriarAtivosAsync()
    {
        var ativos = new (string Patrimonio, string Nome, string Estado, string Ambiente, DateTime Aquisicao, DateTime? Garantia, int VidaUtil)[]
        {
            ("PAT-0001", "Ar-condicionado split 12.000 BTUs", EstadosConservacao.Bom, "Sala 3", Data(2023, 3, 10), Data(2026, 3, 10), 10),
            ("PAT-0002", "Ar-condicionado split 18.000 BTUs", EstadosConservacao.Regular, "Auditório", Data(2021, 2, 1), Data(2024, 2, 1), 10),
            ("PAT-0003", "Projetor multimídia", EstadosConservacao.Bom, "Sala de Reuniões 1", Data(2024, 5, 20), Data(2027, 5, 20), 6),
            ("PAT-0004", "Computador desktop", EstadosConservacao.Bom, "Laboratório de Informática", Data(2023, 8, 15), Data(2026, 8, 15), 5),
            ("PAT-0005", "Bebedouro industrial", EstadosConservacao.Ruim, "Copa", Data(2019, 6, 1), Data(2020, 6, 1), 8),
            ("PAT-0006", "Impressora multifuncional", EstadosConservacao.Regular, "Recepção", Data(2022, 1, 12), Data(2023, 1, 12), 5),
            ("PAT-0007", "Quadro de distribuição elétrica", EstadosConservacao.Bom, "Almoxarifado", Data(2018, 4, 1), null, 25),
            ("PAT-0008", "Porta automática de vidro", EstadosConservacao.Novo, "Recepção", Data(2026, 1, 15), Data(2028, 1, 15), 15),
        };

        var ambientes = await _db.Ambientes.ToListAsync();
        var patrimonios = await _db.Ativos.Select(a => a.Patrimonio.ToLower()).ToListAsync();
        var criados = 0;

        foreach (var a in ativos)
        {
            if (patrimonios.Contains(a.Patrimonio.ToLower())) continue;
            var ambiente = ambientes.FirstOrDefault(x => string.Equals(x.Identificacao, a.Ambiente, StringComparison.OrdinalIgnoreCase));
            if (ambiente == null) continue;

            _db.Ativos.Add(new Ativo
            {
                Patrimonio = a.Patrimonio,
                Nome = a.Nome,
                EstadoConservacao = a.Estado,
                AmbienteId = ambiente.Id,
                DataAquisicao = a.Aquisicao,
                PrazoGarantia = a.Garantia,
                VidaUtilEstimadaAnos = a.VidaUtil
            });
            criados++;
        }
        return criados;
    }

    // ------------------------------------------------------------------ estoque

    private async Task<int> CriarItensEstoqueAsync()
    {
        // Alguns itens já começam abaixo do mínimo, para o alerta de reposição aparecer no painel.
        var itens = new (string Nome, string Codigo, int Quantidade, int Minimo, decimal Custo)[]
        {
            ("Lâmpada LED tubular 18W", "EST-001", 40, 15, 12.90m),
            ("Filtro de ar-condicionado", "EST-002", 6, 8, 45.00m),
            ("Gás refrigerante R-410A (kg)", "EST-003", 12, 5, 89.90m),
            ("Disjuntor bipolar 32A", "EST-004", 10, 4, 38.50m),
            ("Tomada 2P+T 10A", "EST-005", 25, 10, 9.80m),
            ("Fita isolante 20 m", "EST-006", 3, 10, 6.50m),
            ("Cabo flexível 2,5 mm (rolo 100 m)", "EST-007", 4, 2, 219.90m),
            ("Toner para impressora", "EST-008", 2, 3, 159.00m),
            ("Torneira para bebedouro", "EST-009", 5, 2, 27.00m),
            ("Parafuso com bucha 8 mm (cento)", "EST-010", 18, 5, 14.90m),
        };

        var existentes = await _db.ItensEstoque.Select(i => i.Nome.ToLower()).ToListAsync();
        var criados = 0;
        foreach (var i in itens)
        {
            if (existentes.Contains(i.Nome.ToLower())) continue;
            _db.ItensEstoque.Add(new ItemEstoque
            {
                Nome = i.Nome,
                CodigoInterno = i.Codigo,
                QuantidadeEstoque = i.Quantidade,
                EstoqueMinimo = i.Minimo,
                CustoUnitario = i.Custo
            });
            criados++;
        }
        return criados;
    }

    // ------------------------------------------------------------------ chamados

    private async Task<int> CriarChamadosAsync()
    {
        // Só cria chamados num banco que ainda não tem nenhum, para não misturar com os seus.
        if (await _db.Chamados.AnyAsync()) return 0;

        var solicitante = await _db.Usuarios.FirstOrDefaultAsync(u => u.Email == "solicitante@auria.com");
        if (solicitante == null) return 0;

        var ativos = await _db.Ativos.ToListAsync();
        int? IdDoAtivo(string patrimonio) => ativos.FirstOrDefault(a => a.Patrimonio == patrimonio)?.Id;

        var agora = DateTime.UtcNow;
        var chamados = new (string Patrimonio, string Descricao, string? Local, string Tipo, string Prioridade, TimeSpan Ha)[]
        {
            ("PAT-0001", "O ar-condicionado está pingando água no chão.", "Perto da janela", TiposManutencao.Corretiva, Prioridades.Alta, TimeSpan.FromHours(2)),
            ("PAT-0005", "O bebedouro não está gelando a água.", null, TiposManutencao.Corretiva, Prioridades.Media, TimeSpan.FromHours(20)),
            ("PAT-0006", "A impressora está atolando papel com frequência.", "Balcão da recepção", TiposManutencao.Corretiva, Prioridades.Baixa, TimeSpan.FromDays(2)),
            ("PAT-0002", "Revisão semestral do ar-condicionado do auditório.", null, TiposManutencao.Preventiva, Prioridades.Media, TimeSpan.FromDays(3)),
        };

        var criados = 0;
        foreach (var c in chamados)
        {
            var ativoId = IdDoAtivo(c.Patrimonio);
            if (ativoId == null) continue;
            _db.Chamados.Add(new Chamado
            {
                Descricao = c.Descricao,
                LocalizacaoDetalhada = c.Local,
                TipoManutencao = c.Tipo,
                Prioridade = c.Prioridade,
                Status = StatusChamado.Aberto,
                DataAbertura = agora - c.Ha,
                SolicitanteId = solicitante.Id,
                AtivoId = ativoId.Value
            });
            criados++;
        }
        return criados;
    }

    private static DateTime Data(int ano, int mes, int dia) => new(ano, mes, dia, 12, 0, 0, DateTimeKind.Utc);
}
