namespace AuriaAPI.Domain.Constants;

public static class Prioridades
{
    public const string Baixa = "Baixa";
    public const string Media = "Média";
    public const string Alta = "Alta";

    public static readonly IReadOnlyList<string> Todos = new[] { Baixa, Media, Alta };
}
