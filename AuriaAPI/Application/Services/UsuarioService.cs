using AuriaAPI.Application.Common;
using AuriaAPI.Application.DTOs;
using AuriaAPI.Application.Exceptions;
using AuriaAPI.Application.Interfaces;
using AuriaAPI.Application.Mappings;
using AuriaAPI.Domain.Constants;
using AuriaAPI.Domain.Entities;
using AuriaAPI.Domain.Exceptions;
using AuriaAPI.Domain.Repositories;

namespace AuriaAPI.Application.Services;

public class UsuarioService : IUsuarioService
{
    private readonly IUsuarioRepository _usuarios;
    private readonly IUnitOfWork _unitOfWork;
    private readonly IPasswordHasher _passwordHasher;

    public UsuarioService(IUsuarioRepository usuarios, IUnitOfWork unitOfWork, IPasswordHasher passwordHasher)
    {
        _usuarios = usuarios;
        _unitOfWork = unitOfWork;
        _passwordHasher = passwordHasher;
    }

    public async Task<IReadOnlyList<UsuarioResponseDto>> ObterTodosAsync(string? perfil)
    {
        IReadOnlyList<Usuario> usuarios;
        if (string.IsNullOrWhiteSpace(perfil))
        {
            usuarios = await _usuarios.ObterTodosAsync();
        }
        else
        {
            if (!Perfis.EhValido(perfil))
                throw new RegraDeNegocioException($"Perfil inválido. Valores aceitos: {string.Join(", ", Perfis.Todos)}.");
            usuarios = await _usuarios.ObterPorPerfilAsync(perfil);
        }

        return usuarios.OrderBy(u => u.Nome).Select(u => u.ParaDto()).ToList();
    }

    public async Task<UsuarioResponseDto> ObterPorIdAsync(int id) => (await ObterEntidadeAsync(id)).ParaDto();

    public async Task<UsuarioResponseDto> CriarAsync(CriarUsuarioDto dto)
    {
        var email = Normalizacao.Email(dto.Email);
        if (await _usuarios.EmailEmUsoAsync(email))
            throw new ConflitoException("E-mail já cadastrado.");

        var usuario = new Usuario
        {
            Nome = dto.Nome.Trim(),
            Email = email,
            Senha = _passwordHasher.GerarHash(dto.Senha),
            Perfil = dto.Perfil
        };

        await _usuarios.AdicionarAsync(usuario);
        await _unitOfWork.SalvarAlteracoesAsync();
        return usuario.ParaDto();
    }

    public async Task<UsuarioResponseDto> AtualizarAsync(int id, AtualizarUsuarioDto dto, UsuarioLogado usuarioLogado)
    {
        var usuario = await ObterEntidadeAsync(id);
        var email = Normalizacao.Email(dto.Email);

        if (await _usuarios.EmailEmUsoAsync(email, ignorarUsuarioId: id))
            throw new ConflitoException("E-mail já cadastrado para outro usuário.");

        GarantirQueAdminNaoRebaixaASiMesmo(id, dto.Perfil, usuarioLogado);

        usuario.Nome = dto.Nome.Trim();
        usuario.Email = email;
        usuario.Perfil = dto.Perfil;
        if (!string.IsNullOrWhiteSpace(dto.NovaSenha))
            usuario.Senha = _passwordHasher.GerarHash(dto.NovaSenha);

        await _unitOfWork.SalvarAlteracoesAsync();
        return usuario.ParaDto();
    }

    public async Task<UsuarioResponseDto> AlterarPerfilAsync(int id, string perfil, UsuarioLogado usuarioLogado)
    {
        var usuario = await ObterEntidadeAsync(id);
        GarantirQueAdminNaoRebaixaASiMesmo(id, perfil, usuarioLogado);

        usuario.Perfil = perfil;
        await _unitOfWork.SalvarAlteracoesAsync();
        return usuario.ParaDto();
    }

    public async Task RemoverAsync(int id, UsuarioLogado usuarioLogado)
    {
        if (id == usuarioLogado.Id)
            throw new RegraDeNegocioException("Você não pode excluir o seu próprio usuário.");

        var usuario = await ObterEntidadeAsync(id);

        // Sem esta verificação, o banco apagaria em cascata os chamados e ordens de serviço do usuário.
        if (await _usuarios.PossuiVinculosAsync(id))
            throw new ConflitoException("Este usuário possui chamados ou ordens de serviço vinculados e não pode ser excluído. Altere o perfil dele, se necessário.");

        _usuarios.Remover(usuario);
        await _unitOfWork.SalvarAlteracoesAsync();
    }

    private async Task<Usuario> ObterEntidadeAsync(int id) =>
        await _usuarios.ObterPorIdAsync(id) ?? throw new RecursoNaoEncontradoException("Usuário não encontrado.");

    /// <summary>Evita que o sistema fique sem administrador por engano.</summary>
    private static void GarantirQueAdminNaoRebaixaASiMesmo(int usuarioAlteradoId, string novoPerfil, UsuarioLogado usuarioLogado)
    {
        if (usuarioAlteradoId == usuarioLogado.Id && usuarioLogado.EhAdmin && novoPerfil != Perfis.Admin)
            throw new RegraDeNegocioException("Você não pode remover o seu próprio perfil de administrador.");
    }
}
