namespace AuriaAPI.Application.DTOs;

public record LoginDto(string Email, string Senha);


public record RegisterDto(string Nome, string Email, string Senha);

public record AuthResponseDto(string Token, string Nome, string Email, string Role);

public record AtualizarPerfilDto(string Perfil);

public record UsuarioResponseDto(int Id, string Nome, string Email, string Perfil);
