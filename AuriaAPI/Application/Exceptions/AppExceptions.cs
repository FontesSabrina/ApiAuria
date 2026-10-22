namespace AuriaAPI.Application.Exceptions;

/// <summary>404 — o recurso pedido não existe.</summary>
public class RecursoNaoEncontradoException : Exception
{
    public RecursoNaoEncontradoException(string mensagem) : base(mensagem) { }
}

/// <summary>403 — o usuário está autenticado, mas não pode fazer esta operação.</summary>
public class AcessoNegadoException : Exception
{
    public AcessoNegadoException(string mensagem) : base(mensagem) { }
}

/// <summary>409 — a operação conflita com o estado atual dos dados (ex.: e-mail já usado, registro com vínculos).</summary>
public class ConflitoException : Exception
{
    public ConflitoException(string mensagem) : base(mensagem) { }
}

/// <summary>401 — e-mail ou senha inválidos no login.</summary>
public class CredenciaisInvalidasException : Exception
{
    public CredenciaisInvalidasException() : base("Credenciais inválidas.") { }
}
