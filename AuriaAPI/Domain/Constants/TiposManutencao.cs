namespace AuriaAPI.Domain.Constants;

public static class TiposManutencao
{
    public const string Corretiva = "Corretiva";
    public const string Preventiva = "Preventiva";
    public const string Preditiva = "Preditiva";

    public static readonly IReadOnlyList<string> Todos = new[] { Corretiva, Preventiva, Preditiva };
}
