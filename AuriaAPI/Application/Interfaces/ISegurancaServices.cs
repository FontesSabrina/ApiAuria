using AuriaAPI.Domain.Entities;

namespace AuriaAPI.Application.Interfaces;

/// <summary>Gera o hash da senha e confere uma senha contra o hash armazenado.</summary>
public interface IPasswordHasher
{
    string GerarHash(string senha);
    bool Verificar(string senha, string hash);
}

/// <summary>Gera o token JWT de um usuário autenticado.</summary>
public interface ITokenService
{
    (string Token, DateTime ExpiraEm) GerarToken(Usuario usuario);
}
