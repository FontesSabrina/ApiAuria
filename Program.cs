using System.Text;
using System.Text.Json.Serialization;
using AuriaAPI.Application.Services;
using AuriaAPI.Core.Security;
using AuriaAPI.Domain.Repository;
using AuriaAPI.Infra.EF;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

// 1. Configurar Banco de Dados MySQL
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<AuriaDbContext>(options =>
    options.UseMySql(connectionString, ServerVersion.AutoDetect(connectionString)));

// 2. Injeção de Dependência (Repositories e Services)
builder.Services.AddScoped<IUsuarioRepository, UsuarioRepositoryEF>();
builder.Services.AddScoped<IChamadoRepository, ChamadoRepositoryEF>();
builder.Services.AddScoped<AuthService>();
builder.Services.AddScoped<ChamadoService>();
builder.Services.AddScoped<AmbienteService>();
builder.Services.AddScoped<AtivoService>();
builder.Services.AddScoped<ItemEstoqueService>();
builder.Services.AddScoped<NotificacaoService>();
builder.Services.AddScoped<OrdemServicoService>();
builder.Services.AddSingleton<JwtTokenGenerator>();
builder.Services.AddMemoryCache();

// 3. Configurar CORS (Libera requisições HTTP do Swagger e Flutter)
// Em produção, restrinja aos domínios reais via appsettings ("Cors:AllowedOrigins"),
// nunca use AllowAnyOrigin combinado com dados sensíveis/autenticação.
var allowedOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>();
builder.Services.AddCors(options =>
{
    options.AddPolicy("Default", policy =>
    {
        if (builder.Environment.IsDevelopment() || allowedOrigins == null || allowedOrigins.Length == 0)
        {
            policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod();
        }
        else
        {
            policy.WithOrigins(allowedOrigins).AllowAnyHeader().AllowAnyMethod();
        }
    });
});

// 4. Autenticação JWT
// Sem fallback hardcoded: a chave real deve vir de appsettings.Development.json (dev)
// ou de variável de ambiente/user-secrets (produção), nunca de um valor fixo no código.
var secretKey = builder.Configuration["Jwt:SecretKey"]
    ?? throw new InvalidOperationException("Jwt:SecretKey não configurado.");
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"] ?? "AuriaAPI",
            ValidAudience = builder.Configuration["Jwt:Audience"] ?? "AuriaAPI",
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey)),
            ClockSkew = TimeSpan.Zero
        };
    });

builder.Services.AddAuthorization();

// Controllers configurados para ignorar ciclos de referência durante a serialização JSON
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.ReferenceHandler = ReferenceHandler.IgnoreCycles;
    });

// 5. Configurar Swagger com suporte ao botão Authorize (Bearer Token)
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "Auria API", Version = "v1" });

    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "Cole APENAS o token JWT abaixo",
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
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

var app = builder.Build();

// 6. Middlewares e Rotas
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "Auria API v1");
    c.RoutePrefix = "swagger";
});

// Ativa o CORS antes do pipeline de autenticação
app.UseCors("Default");

app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();