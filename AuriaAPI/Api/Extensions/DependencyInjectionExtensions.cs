using AuriaAPI.Application.Interfaces;
using AuriaAPI.Application.Services;
using AuriaAPI.Domain.Repositories;
using AuriaAPI.Infra.Cache;
using AuriaAPI.Infra.EF;
using AuriaAPI.Infra.EF.Repositories;
using AuriaAPI.Infra.Security;
using AuriaAPI.Infra.Seed;
using Microsoft.EntityFrameworkCore;

namespace AuriaAPI.Api.Extensions;

/// <summary>Registro de dependências por camada — o Program.cs só chama estes métodos.</summary>
public static class DependencyInjectionExtensions
{
    /// <summary>Camada Application: casos de uso (services), sempre registrados pela interface.</summary>
    public static IServiceCollection AddAplicacao(this IServiceCollection services)
    {
        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<IUsuarioService, UsuarioService>();
        services.AddScoped<IAmbienteService, AmbienteService>();
        services.AddScoped<IAtivoService, AtivoService>();
        services.AddScoped<IChamadoService, ChamadoService>();
        services.AddScoped<IOrdemServicoService, OrdemServicoService>();
        services.AddScoped<IItemEstoqueService, ItemEstoqueService>();
        services.AddScoped<IIndicadorService, IndicadorService>();
        services.AddScoped<IPlanejamentoService, PlanejamentoService>();

        // A mesma instância atende os endpoints de notificação e as notificações automáticas.
        services.AddScoped<NotificacaoService>();
        services.AddScoped<INotificacaoService>(sp => sp.GetRequiredService<NotificacaoService>());
        services.AddScoped<INotificador>(sp => sp.GetRequiredService<NotificacaoService>());

        return services;
    }

    /// <summary>Camada Infrastructure: banco (EF Core + MySQL), repositórios, cache e segurança.</summary>
    public static IServiceCollection AddInfraestrutura(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("DefaultConnection");
        if (string.IsNullOrWhiteSpace(connectionString))
            throw new InvalidOperationException(
                "ConnectionStrings:DefaultConnection não configurada. Veja a seção 'Configuração' do README (user-secrets ou appsettings.Development.json).");

        var versaoMySql = new MySqlServerVersion(new Version(8, 0, 36));
        services.AddDbContext<AuriaDbContext>(options => options.UseMySql(connectionString, versaoMySql));

        services.AddScoped<IUnitOfWork, EfUnitOfWork>();
        services.AddScoped<IUsuarioRepository, UsuarioRepositoryEF>();
        services.AddScoped<IAmbienteRepository, AmbienteRepositoryEF>();
        services.AddScoped<IAtivoRepository, AtivoRepositoryEF>();
        services.AddScoped<IChamadoRepository, ChamadoRepositoryEF>();
        services.AddScoped<IItemEstoqueRepository, ItemEstoqueRepositoryEF>();
        services.AddScoped<INotificacaoRepository, NotificacaoRepositoryEF>();
        services.AddScoped<IOrdemServicoRepository, OrdemServicoRepositoryEF>();

        services.AddMemoryCache();
        services.AddSingleton<ICacheService, MemoryCacheService>();

        services.AddSingleton<IPasswordHasher, BCryptPasswordHasher>();
        services.AddSingleton<ITokenService, JwtTokenService>();

        services.AddScoped<AdminSeeder>();
        services.AddScoped<DadosDemonstracaoSeeder>();

        return services;
    }
}
