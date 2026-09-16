namespace AuriaAPI.Application.DTOs;

public record CriarNotificacaoDto(string Titulo, string Mensagem, int UsuarioId);

public record NotificacaoResponseDto(
    int Id,
    string Titulo,
    string Mensagem,
    DateTime DataCriacao,
    bool Lida,
    int UsuarioId,
    string? UsuarioNome
);
