using AuriaAPI.Application.DTOs;
using AuriaAPI.Core.Security;
using AuriaAPI.Domain.Repository;
using AuriaAPI.Models;
using BCrypt.Net;

namespace AuriaAPI.Application.Services;

public class AuthService
{
    public static readonly string[] PerfisValidos = { "Solicitante", "Tecnico", "Admin" };

    private readonly IUsuarioRepository _usuarioRepo;
    private readonly JwtTokenGenerator _jwtGenerator;

    public AuthService(IUsuarioRepository usuarioRepo, JwtTokenGenerator jwtGenerator)
    {
        _usuarioRepo = usuarioRepo;
        _jwtGenerator = jwtGenerator;
    }

    public async Task<AuthResponseDto?> RegisterAsync(RegisterDto dto)
    {
        var usuarioExistente = await _usuarioRepo.GetByEmailAsync(dto.Email);
        if (usuarioExistente != null) return null;

        // Cadastro público sempre entra como "Solicitante".
        // Promoção para outros perfis (ex.: Tecnico, Admin) deve ser feita
        // por um endpoint administrativo separado, protegido por [Authorize(Roles = "Admin")].
        var novoUsuario = new Usuario
        {
            Nome = dto.Nome,
            Email = dto.Email,
            Senha = BCrypt.Net.BCrypt.HashPassword(dto.Senha),
            Perfil = "Solicitante"
        };

        await _usuarioRepo.AddAsync(novoUsuario);
        await _usuarioRepo.SaveChangesAsync();

        var token = _jwtGenerator.GenerateToken(novoUsuario);
        return new AuthResponseDto(token, novoUsuario.Nome, novoUsuario.Email, novoUsuario.Perfil);
    }

    public async Task<AuthResponseDto?> LoginAsync(LoginDto dto)
    {
        var usuario = await _usuarioRepo.GetByEmailAsync(dto.Email);
        if (usuario == null || !BCrypt.Net.BCrypt.Verify(dto.Senha, usuario.Senha))
            return null;

        var token = _jwtGenerator.GenerateToken(usuario);
        return new AuthResponseDto(token, usuario.Nome, usuario.Email, usuario.Perfil);
    }

    // Único caminho para promover um usuário a Tecnico/Admin — protegido por
    // [Authorize(Roles = "Admin")] no controller. Cadastro público sempre entra como Solicitante.
    public async Task<UsuarioResponseDto?> AtualizarPerfilAsync(int usuarioId, string perfil)
    {
        if (!PerfisValidos.Contains(perfil)) return null;

        var usuario = await _usuarioRepo.GetByIdAsync(usuarioId);
        if (usuario == null) return null;

        usuario.Perfil = perfil;
        _usuarioRepo.Update(usuario);
        await _usuarioRepo.SaveChangesAsync();

        return new UsuarioResponseDto(usuario.Id, usuario.Nome, usuario.Email, usuario.Perfil);
    }
}
