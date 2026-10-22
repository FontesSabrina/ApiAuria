using System.ComponentModel.DataAnnotations;

namespace AuriaAPI.Application.DTOs;

/// <summary>Criação manual de notificação por um Admin. As notificações do fluxo (chamado aberto, OS concluída etc.) são geradas pela própria API.</summary>
public class CriarNotificacaoDto
{
    [Required(ErrorMessage = "O título é obrigatório.")]
    [StringLength(150, ErrorMessage = "O título deve ter no máximo 150 caracteres.")]
    public string Titulo { get; init; } = string.Empty;

    [Required(ErrorMessage = "A mensagem é obrigatória.")]
    [StringLength(1000, ErrorMessage = "A mensagem deve ter no máximo 1000 caracteres.")]
    public string Mensagem { get; init; } = string.Empty;

    [Range(1, int.MaxValue, ErrorMessage = "Informe o usuário (UsuarioId) que vai receber a notificação.")]
    public int UsuarioId { get; init; }
}

public record NotificacaoResponseDto(
    int Id,
    string Titulo,
    string Mensagem,
    DateTime DataCriacao,
    bool Lida,
    int UsuarioId,
    string? UsuarioNome
);
