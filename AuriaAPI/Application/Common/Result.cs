namespace AuriaAPI.Application.Common;

/// <summary>
/// ResultWrapper: formato único de TODAS as respostas da API (sucesso e erro).
/// <code>
/// { "success": true, "message": "...", "data": { ... }, "errors": [] }
/// </code>
/// Sucesso: criado nos controllers. Erros: criados pelo ExceptionHandlingMiddleware,
/// pela validação automática dos DTOs (400) e pelos eventos do JWT (401/403).
/// </summary>
public class Result<T>
{
    public bool Success { get; set; }
    public string Message { get; set; } = string.Empty;
    public T? Data { get; set; }
    public List<string> Errors { get; set; } = new();

    public static Result<T> SuccessResult(T? data, string message = "Operação realizada com sucesso.") => new()
    {
        Success = true,
        Message = message,
        Data = data,
        Errors = new()
    };

    public static Result<T> FailureResult(string message, IEnumerable<string>? errors = null)
    {
        var listaErros = errors?.ToList() ?? new List<string>();
        if (listaErros.Count == 0)
            listaErros.Add(message);

        return new Result<T>
        {
            Success = false,
            Message = message,
            Data = default,
            Errors = listaErros
        };
    }
}
