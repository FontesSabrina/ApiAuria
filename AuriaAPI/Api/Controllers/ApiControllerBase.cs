using AuriaAPI.Api.Extensions;
using AuriaAPI.Application.Common;
using Microsoft.AspNetCore.Mvc;

namespace AuriaAPI.Api.Controllers;

/// <summary>
/// Base dos controllers: só monta as respostas de sucesso no formato do ResultWrapper.
/// Os erros são lançados pelos services como exceções e convertidos pelo ExceptionHandlingMiddleware.
/// </summary>
[ApiController]
[Produces("application/json")]
public abstract class ApiControllerBase : ControllerBase
{
    protected UsuarioLogado UsuarioLogado => User.ObterUsuarioLogado();

    protected OkObjectResult Sucesso<T>(T dados, string mensagem) =>
        Ok(Result<T>.SuccessResult(dados, mensagem));

    protected OkObjectResult Sucesso(string mensagem) =>
        Ok(Result<object>.SuccessResult(null, mensagem));

    protected CreatedAtActionResult Criado<T>(string acao, object rotaValores, T dados, string mensagem) =>
        CreatedAtAction(acao, rotaValores, Result<T>.SuccessResult(dados, mensagem));
}
