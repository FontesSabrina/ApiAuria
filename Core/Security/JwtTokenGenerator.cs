using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using AuriaAPI.Models;
using Microsoft.IdentityModel.Tokens;

namespace AuriaAPI.Core.Security;

public class JwtTokenGenerator
{
    private readonly IConfiguration _config;

    public JwtTokenGenerator(IConfiguration config)
    {
        _config = config;
    }

    public string GenerateToken(Usuario usuario)
    {
        var secretKey = _config["Jwt:SecretKey"];
        if (string.IsNullOrWhiteSpace(secretKey))
        {
            // Sem fallback hardcoded: se a chave não estiver configurada, a API
            // deve falhar aqui em vez de assinar tokens com uma chave pública/previsível.
            throw new InvalidOperationException(
                "Jwt:SecretKey não configurado. Defina em appsettings.Development.json (ambiente local) " +
                "e via variável de ambiente ou user-secrets em produção. Nunca versione a chave real no Git.");
        }

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, usuario.Id.ToString()),
            new Claim(JwtRegisteredClaimNames.Name, usuario.Nome ?? string.Empty),
            new Claim(JwtRegisteredClaimNames.Email, usuario.Email ?? string.Empty),
            new Claim(ClaimTypes.Role, usuario.Perfil ?? "User"),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        var token = new JwtSecurityToken(
            issuer: _config["Jwt:Issuer"] ?? "AuriaAPI",
            audience: _config["Jwt:Audience"] ?? "AuriaAPI",
            claims: claims,
            expires: DateTime.UtcNow.AddHours(8),
            signingCredentials: creds
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
