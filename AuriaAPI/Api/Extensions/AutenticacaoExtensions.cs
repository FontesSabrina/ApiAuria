using System.Text;
using AuriaAPI.Application.Common;
using AuriaAPI.Infra.Security;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;

namespace AuriaAPI.Api.Extensions;

public static class AutenticacaoExtensions
{
    /// <summary>
    /// Configura a validação do JWT em todas as requisições (assinatura, emissor, público e expiração)
    /// e faz com que as respostas 401 e 403 também sigam o formato do ResultWrapper.
    /// </summary>
    public static IServiceCollection AddAutenticacaoJwt(this IServiceCollection services, IConfiguration configuration)
    {
        var secao = configuration.GetSection(JwtSettings.Secao);
        services.Configure<JwtSettings>(secao);

        var settings = secao.Get<JwtSettings>() ?? new JwtSettings();
        if (string.IsNullOrWhiteSpace(settings.SecretKey) || settings.SecretKey.Length < JwtSettings.TamanhoMinimoChave)
        {
            throw new InvalidOperationException(
                $"Jwt:SecretKey não configurada (mínimo de {JwtSettings.TamanhoMinimoChave} caracteres). " +
                "Configure com 'dotnet user-secrets set \"Jwt:SecretKey\" \"<sua-chave>\"' ou pela variável de ambiente Jwt__SecretKey.");
        }

        services
            .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
            .AddJwtBearer(options =>
            {
                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuer = true,
                    ValidateAudience = true,
                    ValidateLifetime = true,
                    ValidateIssuerSigningKey = true,
                    ValidIssuer = settings.Issuer,
                    ValidAudience = settings.Audience,
                    IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(settings.SecretKey)),
                    ClockSkew = TimeSpan.Zero
                };

                options.Events = new JwtBearerEvents
                {
                    // 401: sem token, token inválido ou expirado.
                    OnChallenge = async context =>
                    {
                        context.HandleResponse();

                        var mensagem = context.AuthenticateFailure switch
                        {
                            SecurityTokenExpiredException => "Token expirado. Faça login novamente.",
                            not null => "Token inválido. Faça login novamente.",
                            null => "Token de autenticação não informado. Envie o header 'Authorization: Bearer <token>'."
                        };

                        context.Response.StatusCode = StatusCodes.Status401Unauthorized;
                        await context.Response.WriteAsJsonAsync(Result<object>.FailureResult(mensagem));
                    },
                    // 403: token válido, mas o perfil do usuário não tem acesso ao endpoint.
                    OnForbidden = async context =>
                    {
                        context.Response.StatusCode = StatusCodes.Status403Forbidden;
                        await context.Response.WriteAsJsonAsync(
                            Result<object>.FailureResult("Você não tem permissão para acessar este recurso com o seu perfil de usuário."));
                    }
                };
            });

        services.AddAuthorization();
        return services;
    }
}
