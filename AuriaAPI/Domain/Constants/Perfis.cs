namespace AuriaAPI.Domain.Constants;

/// <summary>Perfis de acesso de um usuário (gravados como texto na coluna usuario.perfil).</summary>
public static class Perfis
{
    public const string Solicitante = "Solicitante";
    public const string Tecnico = "Tecnico";
    public const string Admin = "Admin";

    /// <summary>Valor pronto para [Authorize(Roles = ...)].</summary>
    public const string TecnicoOuAdmin = Tecnico + "," + Admin;

    public static readonly IReadOnlyList<string> Todos = new[] { Solicitante, Tecnico, Admin };

    public static bool EhValido(string? perfil) => perfil != null && Todos.Contains(perfil);
}
