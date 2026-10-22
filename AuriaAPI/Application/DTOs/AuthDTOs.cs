using System.ComponentModel.DataAnnotations;
using AuriaAPI.Domain.Constants;

namespace AuriaAPI.Application.DTOs;

public class LoginDto
{
    [Required(ErrorMessage = "O e-mail é obrigatório.")]
    [EmailAddress(ErrorMessage = "Informe um e-mail válido.")]
    public string Email { get; init; } = string.Empty;

    [Required(ErrorMessage = "A senha é obrigatória.")]
    public string Senha { get; init; } = string.Empty;
}

/// <summary>Cadastro público (POST /api/auth/register): o usuário sempre entra como Solicitante.</summary>
public class RegistrarUsuarioDto
{
    [Required(ErrorMessage = "O nome é obrigatório.")]
    [StringLength(100, MinimumLength = 3, ErrorMessage = "O nome deve ter entre 3 e 100 caracteres.")]
    public string Nome { get; init; } = string.Empty;

    [Required(ErrorMessage = "O e-mail é obrigatório.")]
    [EmailAddress(ErrorMessage = "Informe um e-mail válido.")]
    [StringLength(150, ErrorMessage = "O e-mail deve ter no máximo 150 caracteres.")]
    public string Email { get; init; } = string.Empty;

    [Required(ErrorMessage = "A senha é obrigatória.")]
    [StringLength(100, MinimumLength = 6, ErrorMessage = "A senha deve ter pelo menos 6 caracteres.")]
    public string Senha { get; init; } = string.Empty;
}

/// <summary>Cadastro feito por um Admin (POST /api/usuarios), que já define o perfil.</summary>
public class CriarUsuarioDto : RegistrarUsuarioDto
{
    [Required(ErrorMessage = "O perfil é obrigatório.")]
    [AllowedValues(Perfis.Solicitante, Perfis.Tecnico, Perfis.Admin, ErrorMessage = "Perfil inválido. Valores aceitos: Solicitante, Tecnico, Admin.")]
    public string Perfil { get; init; } = Perfis.Solicitante;
}

public class AtualizarUsuarioDto
{
    [Required(ErrorMessage = "O nome é obrigatório.")]
    [StringLength(100, MinimumLength = 3, ErrorMessage = "O nome deve ter entre 3 e 100 caracteres.")]
    public string Nome { get; init; } = string.Empty;

    [Required(ErrorMessage = "O e-mail é obrigatório.")]
    [EmailAddress(ErrorMessage = "Informe um e-mail válido.")]
    [StringLength(150, ErrorMessage = "O e-mail deve ter no máximo 150 caracteres.")]
    public string Email { get; init; } = string.Empty;

    [Required(ErrorMessage = "O perfil é obrigatório.")]
    [AllowedValues(Perfis.Solicitante, Perfis.Tecnico, Perfis.Admin, ErrorMessage = "Perfil inválido. Valores aceitos: Solicitante, Tecnico, Admin.")]
    public string Perfil { get; init; } = Perfis.Solicitante;

    /// <summary>Opcional: só troca a senha quando informado.</summary>
    [StringLength(100, MinimumLength = 6, ErrorMessage = "A nova senha deve ter pelo menos 6 caracteres.")]
    public string? NovaSenha { get; init; }
}

public class AlterarPerfilDto
{
    [Required(ErrorMessage = "O perfil é obrigatório.")]
    [AllowedValues(Perfis.Solicitante, Perfis.Tecnico, Perfis.Admin, ErrorMessage = "Perfil inválido. Valores aceitos: Solicitante, Tecnico, Admin.")]
    public string Perfil { get; init; } = string.Empty;
}

public record AuthResponseDto(int Id, string Token, DateTime ExpiraEm, string Nome, string Email, string Role);

public record UsuarioResponseDto(int Id, string Nome, string Email, string Perfil);
