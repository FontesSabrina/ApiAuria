using AuriaAPI.Application.Common;
using AuriaAPI.Application.Interfaces;
using AuriaAPI.Domain.Constants;
using AuriaAPI.Domain.Entities;
using AuriaAPI.Domain.Repositories;

namespace AuriaAPI.Infra.Seed;

/// <summary>
/// Ao iniciar a API, cria o primeiro administrador caso ainda não exista nenhum.
/// Os dados vêm da seção "AdminInicial" da configuração (user-secrets / appsettings.Development.json),
/// nunca do código-fonte. Se a seção não estiver configurada, nada é criado.
/// </summary>
public class AdminSeeder
{
    private readonly IUsuarioRepository _usuarios;
    private readonly IUnitOfWork _unitOfWork;
    private readonly IPasswordHasher _passwordHasher;
    private readonly IConfiguration _configuration;
    private readonly ILogger<AdminSeeder> _logger;

    public AdminSeeder(IUsuarioRepository usuarios, IUnitOfWork unitOfWork, IPasswordHasher passwordHasher,
        IConfiguration configuration, ILogger<AdminSeeder> logger)
    {
        _usuarios = usuarios;
        _unitOfWork = unitOfWork;
        _passwordHasher = passwordHasher;
        _configuration = configuration;
        _logger = logger;
    }

    public async Task ExecutarAsync()
    {
        if (await _usuarios.ExisteAlgumComPerfilAsync(Perfis.Admin))
            return;

        var nome = _configuration["AdminInicial:Nome"];
        var email = _configuration["AdminInicial:Email"];
        var senha = _configuration["AdminInicial:Senha"];

        if (string.IsNullOrWhiteSpace(nome) || string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(senha))
        {
            _logger.LogWarning("Nenhum administrador cadastrado e a seção 'AdminInicial' não está configurada — o primeiro Admin não foi criado.");
            return;
        }

        var emailNormalizado = Normalizacao.Email(email);
        var existente = await _usuarios.ObterPorEmailAsync(emailNormalizado);
        if (existente != null)
        {
            existente.Perfil = Perfis.Admin;
            _logger.LogInformation("Usuário {Email} promovido a Admin (primeiro administrador do sistema).", emailNormalizado);
        }
        else
        {
            await _usuarios.AdicionarAsync(new Usuario
            {
                Nome = nome.Trim(),
                Email = emailNormalizado,
                Senha = _passwordHasher.GerarHash(senha),
                Perfil = Perfis.Admin
            });
            _logger.LogInformation("Primeiro administrador criado: {Email}.", emailNormalizado);
        }

        await _unitOfWork.SalvarAlteracoesAsync();
    }
}
