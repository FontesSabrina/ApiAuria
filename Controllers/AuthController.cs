using AuriaAPI.Application.DTOs;
using AuriaAPI.Application.Services;
using AuriaAPI.Common; // Importante para usar o Result
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
}