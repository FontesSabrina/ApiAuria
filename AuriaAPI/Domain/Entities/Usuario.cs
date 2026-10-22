using AuriaAPI.Domain.Constants;

namespace AuriaAPI.Domain.Entities;

public class Usuario
{
    public int Id { get; set; }
    public string Nome { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;

    /// <summary>Hash BCrypt da senha — a senha em texto puro nunca é armazenada.</summary>
    public string Senha { get; set; } = string.Empty;

    public string Perfil { get; set; } = Perfis.Solicitante;

    public ICollection<Chamado> Chamados { get; set; } = new List<Chamado>();

    public bool PodeExecutarOrdens => Perfil == Perfis.Tecnico || Perfil == Perfis.Admin;
}
