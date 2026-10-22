using AuriaAPI.Application.Common;
using AuriaAPI.Application.Exceptions;
using AuriaAPI.Domain.Exceptions;
using Microsoft.EntityFrameworkCore;

namespace AuriaAPI.Api.Middleware;

/// <summary>
/// Captura qualquer exceção lançada durante a requisição e devolve a resposta no formato do
/// ResultWrapper, com o status HTTP adequado. Assim os controllers não precisam de try/catch
/// e nenhuma resposta de erro sai fora do padrão (nem mesmo um erro 500).
/// </summary>
public class ExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionHandlingMiddleware> _logger;

    public ExceptionHandlingMiddleware(RequestDelegate next, ILogger<ExceptionHandlingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            if (context.Response.HasStarted)
                throw;

            var (status, mensagem) = Classificar(ex);

            if (status == StatusCodes.Status500InternalServerError)
                _logger.LogError(ex, "Erro não tratado em {Metodo} {Caminho}", context.Request.Method, context.Request.Path);
            else
                _logger.LogInformation("Requisição {Metodo} {Caminho} recusada ({Status}): {Mensagem}", context.Request.Method, context.Request.Path, status, mensagem);

            context.Response.Clear();
            context.Response.StatusCode = status;
            await context.Response.WriteAsJsonAsync(Result<object>.FailureResult(mensagem));
        }
    }

    private static (int Status, string Mensagem) Classificar(Exception ex) => ex switch
    {
        RegraDeNegocioException => (StatusCodes.Status400BadRequest, ex.Message),
        CredenciaisInvalidasException => (StatusCodes.Status401Unauthorized, ex.Message),
        AcessoNegadoException => (StatusCodes.Status403Forbidden, ex.Message),
        RecursoNaoEncontradoException => (StatusCodes.Status404NotFound, ex.Message),
        ConflitoException => (StatusCodes.Status409Conflict, ex.Message),
        DbUpdateException => (StatusCodes.Status409Conflict,
            "Não foi possível salvar as alterações: o registro está vinculado a outros dados ou viola uma restrição do banco."),
        _ => (StatusCodes.Status500InternalServerError,
            "Ocorreu um erro interno ao processar a requisição. Tente novamente mais tarde.")
    };
}
