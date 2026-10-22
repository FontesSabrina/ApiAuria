namespace AuriaAPI.Domain.Exceptions;

/// <summary>
/// Lançada quando uma operação viola uma regra do domínio
/// (ex.: cancelar um chamado já concluído, debitar mais do que há em estoque).
/// A API converte esta exceção em uma resposta 400 no formato do ResultWrapper.
/// </summary>
public class RegraDeNegocioException : Exception
{
    public RegraDeNegocioException(string mensagem) : base(mensagem) { }
}
