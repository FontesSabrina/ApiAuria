using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using AuriaAPI.Application.Common;
using AuriaAPI.Application.Exceptions;

namespace AuriaAPI.Api.Extensions;

public static class ClaimsPrincipalExtensions
{
    /// <summary>Lê o id (claim "sub") e o perfil (claim "role") do token JWT já validado.</summary>
    public static UsuarioLogado ObterUsuarioLogado(this ClaimsPrincipal user)
    {
        var id = user.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? user.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;
        var perfil = user.FindFirst(ClaimTypes.Role)?.Value;

        if (!int.TryParse(id, out var usuarioId) || string.IsNullOrEmpty(perfil))
            throw new AcessoNegadoException("Token sem a identificação do usuário. Faça login novamente.");

        return new UsuarioLogado(usuarioId, perfil);
    }
}
