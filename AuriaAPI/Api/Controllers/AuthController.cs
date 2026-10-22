using AuriaAPI.Application.DTOs;
using AuriaAPI.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AuriaAPI.Api.Controllers;

/// <summary>Endpoints públicos de autenticação: cadastro e login (geram o token JWT).</summary>
[Route("api/auth")]
[AllowAnonymous]
public class AuthController : ApiControllerBase
{
    private readonly IAuthService _authService;

    public AuthController(IAuthService authService) => _authService = authService;

    /// <summary>Cadastra um usuário (sempre com perfil Solicitante) e já devolve o token.</summary>
    [HttpPost("register")]
    public async Task<IActionResult> Registrar([FromBody] RegistrarUsuarioDto dto) =>
        Sucesso(await _authService.RegistrarAsync(dto), "Usuário cadastrado com sucesso.");

    /// <summary>Valida e-mail e senha e devolve o token JWT.</summary>
    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginDto dto) =>
        Sucesso(await _authService.LoginAsync(dto), "Login realizado com sucesso.");
}
