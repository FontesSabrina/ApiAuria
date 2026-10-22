using AuriaAPI.Application.Common;
using AuriaAPI.Application.DTOs;

namespace AuriaAPI.Application.Interfaces;

public interface IAuthService
{
    Task<AuthResponseDto> RegistrarAsync(RegistrarUsuarioDto dto);
    Task<AuthResponseDto> LoginAsync(LoginDto dto);
}

public interface IUsuarioService
{
    Task<IReadOnlyList<UsuarioResponseDto>> ObterTodosAsync(string? perfil);
    Task<UsuarioResponseDto> ObterPorIdAsync(int id);
    Task<UsuarioResponseDto> CriarAsync(CriarUsuarioDto dto);
    Task<UsuarioResponseDto> AtualizarAsync(int id, AtualizarUsuarioDto dto, UsuarioLogado usuarioLogado);
    Task<UsuarioResponseDto> AlterarPerfilAsync(int id, string perfil, UsuarioLogado usuarioLogado);
    Task RemoverAsync(int id, UsuarioLogado usuarioLogado);
}

public interface IAmbienteService
{
    Task<IReadOnlyList<AmbienteResponseDto>> ObterTodosAsync();
    Task<AmbienteResponseDto> ObterPorIdAsync(int id);
    Task<AmbienteResponseDto> CriarAsync(SalvarAmbienteDto dto);
    Task<AmbienteResponseDto> AtualizarAsync(int id, SalvarAmbienteDto dto);
    Task RemoverAsync(int id);
}

public interface IAtivoService
{
    Task<IReadOnlyList<AtivoResponseDto>> ObterTodosAsync(int? ambienteId);
    Task<AtivoResponseDto> ObterPorIdAsync(int id);
    Task<AtivoResponseDto> CriarAsync(SalvarAtivoDto dto);
    Task<AtivoResponseDto> AtualizarAsync(int id, SalvarAtivoDto dto);
    Task RemoverAsync(int id);
}

public interface IChamadoService
{
    Task<IReadOnlyList<ChamadoResponseDto>> ObterTodosAsync(string? status);
    Task<IReadOnlyList<ChamadoResponseDto>> ObterDoSolicitanteAsync(int solicitanteId);
    Task<ChamadoResponseDto> ObterPorIdAsync(int id, UsuarioLogado usuarioLogado);
    Task<ChamadoResponseDto> CriarAsync(CriarChamadoDto dto, UsuarioLogado usuarioLogado);
    Task<ChamadoResponseDto> CancelarAsync(int id, UsuarioLogado usuarioLogado);
}

public interface IOrdemServicoService
{
    Task<IReadOnlyList<OrdemServicoResponseDto>> ObterTodasAsync();
    Task<IReadOnlyList<OrdemServicoResponseDto>> ObterDoTecnicoAsync(int tecnicoId);
    Task<OrdemServicoResponseDto> ObterPorIdAsync(int id);
    Task<OrdemServicoResponseDto> CriarAsync(CriarOrdemServicoDto dto);
    Task<OrdemServicoResponseDto> RegistrarConsumoAsync(int id, RegistrarConsumoDto dto, UsuarioLogado usuarioLogado);
    Task<OrdemServicoResponseDto> ConcluirAsync(int id, ConcluirOrdemServicoDto dto, UsuarioLogado usuarioLogado);
}

public interface IItemEstoqueService
{
    Task<IReadOnlyList<ItemEstoqueResponseDto>> ObterTodosAsync();
    Task<IReadOnlyList<ItemEstoqueResponseDto>> ObterAbaixoDoMinimoAsync();
    Task<ItemEstoqueResponseDto> ObterPorIdAsync(int id);
    Task<ItemEstoqueResponseDto> CriarAsync(SalvarItemEstoqueDto dto);
    Task<ItemEstoqueResponseDto> AtualizarAsync(int id, SalvarItemEstoqueDto dto);
    Task RemoverAsync(int id);
}

public interface INotificacaoService
{
    Task<IReadOnlyList<NotificacaoResponseDto>> ObterDoUsuarioAsync(int usuarioId);
    Task<NotificacaoResponseDto> CriarAsync(CriarNotificacaoDto dto);
    Task MarcarComoLidaAsync(int id, UsuarioLogado usuarioLogado);
    Task RemoverAsync(int id, UsuarioLogado usuarioLogado);
}

/// <summary>
/// Usado pelos outros services para gerar notificações automáticas dentro de uma operação maior
/// (ex.: abrir chamado avisa os admins). Só adiciona as notificações: quem chama é que salva tudo junto.
/// </summary>
public interface INotificador
{
    Task NotificarUsuarioAsync(int usuarioId, string titulo, string mensagem);
    Task NotificarPerfilAsync(string perfil, string titulo, string mensagem);
}

public interface IIndicadorService
{
    Task<IndicadoresDto> ObterResumoAsync();
}

public interface IPlanejamentoService
{
    Task<IReadOnlyList<OrdemServicoResponseDto>> ObterCronogramaPreventivasAsync(DateOnly data);
    Task<IReadOnlyList<AlertaPreventivaDto>> ObterAlertasAsync();
}
