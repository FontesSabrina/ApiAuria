namespace AuriaAPI.Domain.Entities;

public class Notificacao
{
    public int Id { get; set; }
    public string Titulo { get; set; } = string.Empty;
    public string Mensagem { get; set; } = string.Empty;
    public DateTime DataCriacao { get; set; } = DateTime.UtcNow;
    public bool Lida { get; set; } = false;

    public int UsuarioId { get; set; }
    public Usuario? Usuario { get; set; }

    public static Notificacao Criar(int usuarioId, string titulo, string mensagem) => new()
    {
        UsuarioId = usuarioId,
        Titulo = titulo,
        Mensagem = mensagem,
        DataCriacao = DateTime.UtcNow,
        Lida = false
    };
}
