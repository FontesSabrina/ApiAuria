using AuriaAPI.Application.Interfaces;

namespace AuriaAPI.Infra.Security;

/// <summary>Hash de senha com BCrypt (salt aleatório embutido no próprio hash). A senha em texto puro nunca é gravada.</summary>
public class BCryptPasswordHasher : IPasswordHasher
{
    public string GerarHash(string senha) => BCrypt.Net.BCrypt.HashPassword(senha);

    public bool Verificar(string senha, string hash) => BCrypt.Net.BCrypt.Verify(senha, hash);
}
