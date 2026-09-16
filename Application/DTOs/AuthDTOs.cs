namespace AuriaAPI.Application.DTOs;

public record LoginDto(string Email, string Senha);


public record RegisterDto(string Nome, string Email, string Senha);

public record AuthResponseDto(string Token, string Nome, string Email, string Role);
