using System.Text.Json.Serialization;
using AuriaAPI.Application.Common;
using Microsoft.AspNetCore.Mvc;
using Microsoft.OpenApi.Models;

namespace AuriaAPI.Api.Extensions;

public static class ApiExtensions
{
    /// <summary>Controllers + resposta padronizada (ResultWrapper) para erros de validação dos DTOs.</summary>
    public static IServiceCollection AddControllersComResultWrapper(this IServiceCollection services)
    {
        services.AddControllers()
            .AddJsonOptions(options =>
            {
                options.JsonSerializerOptions.ReferenceHandler = ReferenceHandler.IgnoreCycles;
            })
            .ConfigureApiBehaviorOptions(options =>
            {
                // Sem isso, o [ApiController] devolveria um ProblemDetails (formato diferente) no erro 400.
                options.InvalidModelStateResponseFactory = context =>
                {
                    var erros = context.ModelState
                        .Where(campo => campo.Value?.Errors.Count > 0)
                        .SelectMany(campo => campo.Value!.Errors.Select(erro =>
                            string.IsNullOrWhiteSpace(erro.ErrorMessage)
                                ? $"Valor inválido no campo '{campo.Key}'."
                                : erro.ErrorMessage))
                        .Distinct()
                        .ToList();

                    return new BadRequestObjectResult(Result<object>.FailureResult("Dados inválidos.", erros));
                };
            });

        return services;
    }

    public static IServiceCollection AddSwaggerComJwt(this IServiceCollection services)
    {
        services.AddEndpointsApiExplorer();
        services.AddSwaggerGen(c =>
        {
            c.SwaggerDoc("v1", new OpenApiInfo
            {
                Title = "Auria API",
                Version = "v1",
                Description = "API de gestão de manutenção predial (ambientes, ativos, chamados, ordens de serviço e estoque). " +
                              "Faça login em POST /api/auth/login e clique em Authorize para colar o token."
            });

            c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
            {
                Description = "Cole APENAS o token JWT (sem a palavra Bearer).",
                Name = "Authorization",
                In = ParameterLocation.Header,
                Type = SecuritySchemeType.Http,
                Scheme = "bearer",
                BearerFormat = "JWT"
            });

            c.AddSecurityRequirement(new OpenApiSecurityRequirement
            {
                {
                    new OpenApiSecurityScheme
                    {
                        Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" }
                    },
                    Array.Empty<string>()
                }
            });
        });

        return services;
    }

    public static IServiceCollection AddCorsPadrao(this IServiceCollection services, IConfiguration configuration, IWebHostEnvironment environment)
    {
        var origensPermitidas = configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? Array.Empty<string>();

        services.AddCors(options =>
        {
            options.AddPolicy("Default", policy =>
            {
                // Em desenvolvimento libera qualquer origem (Flutter Web roda numa porta aleatória).
                if (environment.IsDevelopment() || origensPermitidas.Length == 0)
                    policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod();
                else
                    policy.WithOrigins(origensPermitidas).AllowAnyHeader().AllowAnyMethod();
            });
        });

        return services;
    }
}
