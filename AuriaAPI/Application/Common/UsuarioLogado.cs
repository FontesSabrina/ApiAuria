using AuriaAPI.Domain.Constants;

namespace AuriaAPI.Application.Common;

/// <summary>Quem está fazendo a requisição (extraído das claims do token JWT pelo controller).</summary>
public record UsuarioLogado(int Id, string Perfil)
{
    public bool EhAdmin => Perfil == Perfis.Admin;
    public bool EhTecnico => Perfil == Perfis.Tecnico;
}
