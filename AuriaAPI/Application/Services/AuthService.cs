using AuriaAPI.Application.Common;
using AuriaAPI.Application.DTOs;
using AuriaAPI.Application.Exceptions;
using AuriaAPI.Application.Interfaces;
using AuriaAPI.Domain.Constants;
using AuriaAPI.Domain.Entities;
using AuriaAPI.Domain.Repositories;

namespace AuriaAPI.Application.Services;

public class AuthService : IAuthService
{
    private readonly IUsuarioRepository _usuarios;
    private readonly IUnitOfWork _unitOfWork;
    private readonly IPasswordHasher _passwordHasher;
    private readonly ITokenService _tokenService;

    public AuthService(IUsuarioRepository usuarios, IUnitOfWork unitOfWork, IPasswordHasher passwordHasher, ITokenService tokenService)
    {
        _usuarios = usuarios;
        _unitOfWork = unitOfWork;
        _passwordHasher = passwordHasher;
        _tokenService = tokenService;
    }

    public async Task<AuthResponseDto> RegistrarAsync(RegistrarUsuarioDto dto)
    {
        var email = Normalizacao.Email(dto.Email);
        if (await _usuarios.EmailEmUsoAsync(email))
            throw new ConflitoException("E-mail já cadastrado.");

        var usuario = new Usuario
        {
            Nome = dto.Nome.Trim(),
            Email = email,
            Senha = _passwordHasher.GerarHash(dto.Senha),
            Perfil = Perfis.Solicitante
        };

        await _usuarios.AdicionarAsync(usuario);
        await _unitOfWork.SalvarAlteracoesAsync();

        return GerarResposta(usuario);
    }

    public async Task<AuthResponseDto> LoginAsync(LoginDto dto)
    {
        var usuario = await _usuarios.ObterPorEmailAsync(Normalizacao.Email(dto.Email));
        if (usuario == null || !_passwordHasher.Verificar(dto.Senha, usuario.Senha))
            throw new CredenciaisInvalidasException();

        return GerarResposta(usuario);
    }

    private AuthResponseDto GerarResposta(Usuario usuario)
    {
        var (token, expiraEm) = _tokenService.GerarToken(usuario);
        return new AuthResponseDto(usuario.Id, token, expiraEm, usuario.Nome, usuario.Email, usuario.Perfil);
    }
}
