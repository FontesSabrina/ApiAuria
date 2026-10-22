using AuriaAPI.Application.DTOs;
using AuriaAPI.Application.Interfaces;
using AuriaAPI.Domain.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AuriaAPI.Api.Controllers;

/// <summary>Gestão de usuários — exclusiva do perfil Admin.</summary>
[Route("api/usuarios")]
[Authorize(Roles = Perfis.Admin)]
public class UsuariosController : ApiControllerBase
{
    private readonly IUsuarioService _usuarioService;

    public UsuariosController(IUsuarioService usuarioService) => _usuarioService = usuarioService;

    /// <summary>Lista os usuários. Filtro opcional: ?perfil=Tecnico</summary>
    [HttpGet]
    public async Task<IActionResult> ObterTodos([FromQuery] string? perfil) =>
        Sucesso(await _usuarioService.ObterTodosAsync(perfil), "Usuários recuperados com sucesso.");

    [HttpGet("{id:int}")]
    public async Task<IActionResult> ObterPorId(int id) =>
        Sucesso(await _usuarioService.ObterPorIdAsync(id), "Usuário recuperado com sucesso.");

    /// <summary>Cria um usuário já com o perfil definido (ex.: um técnico).</summary>
    [HttpPost]
    public async Task<IActionResult> Criar([FromBody] CriarUsuarioDto dto)
    {
        var criado = await _usuarioService.CriarAsync(dto);
        return Criado(nameof(ObterPorId), new { id = criado.Id }, criado, "Usuário cadastrado com sucesso.");
    }

    /// <summary>Atualiza nome, e-mail, perfil e (opcionalmente) a senha.</summary>
    [HttpPut("{id:int}")]
    public async Task<IActionResult> Atualizar(int id, [FromBody] AtualizarUsuarioDto dto) =>
        Sucesso(await _usuarioService.AtualizarAsync(id, dto, UsuarioLogado), "Usuário atualizado com sucesso.");

    [HttpPut("{id:int}/perfil")]
    public async Task<IActionResult> AlterarPerfil(int id, [FromBody] AlterarPerfilDto dto) =>
        Sucesso(await _usuarioService.AlterarPerfilAsync(id, dto.Perfil, UsuarioLogado), "Perfil atualizado com sucesso.");

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Remover(int id)
    {
        await _usuarioService.RemoverAsync(id, UsuarioLogado);
        return Sucesso("Usuário removido com sucesso.");
    }
}
