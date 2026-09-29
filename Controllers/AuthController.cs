using AuriaAPI.Application.DTOs;
using AuriaAPI.Application.Services;
using AuriaAPI.Common;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AuriaAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly AuthService _authService;

    public AuthController(AuthService authService)
    {
        _authService = authService;
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterDto dto)
    {
        var result = await _authService.RegisterAsync(dto);
        if (result == null) 
            return BadRequest(Result<object>.FailureResult("Email já cadastrado."));

        return Ok(Result<object>.SuccessResult(result, "Usuário cadastrado com sucesso."));
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginDto dto)
    {
        var result = await _authService.LoginAsync(dto);
        if (result == null)
            return Unauthorized(Result<object>.FailureResult("Credenciais inválidas."));

        return Ok(Result<object>.SuccessResult(result, "Login realizado com sucesso."));
    }

    [HttpGet("usuarios")]
    [Authorize]
    public async Task<IActionResult> ObterUsuarios()
    {
        var usuarios = await _authService.ObterTodosAsync();
        return Ok(Result<IEnumerable<UsuarioResponseDto>>.SuccessResult(usuarios, "Usuários recuperados com sucesso."));
    }

    [HttpPut("usuarios/{id}/perfil")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> AtualizarPerfil(int id, [FromBody] AtualizarPerfilDto dto)
    {
        if (!AuthService.PerfisValidos.Contains(dto.Perfil))
            return BadRequest(Result<object>.FailureResult($"Perfil inválido. Valores aceitos: {string.Join(", ", AuthService.PerfisValidos)}."));

        var usuario = await _authService.AtualizarPerfilAsync(id, dto.Perfil);
        if (usuario == null)
            return NotFound(Result<object>.FailureResult("Usuário não encontrado."));

        return Ok(Result<UsuarioResponseDto>.SuccessResult(usuario, "Perfil atualizado com sucesso."));
    }
}