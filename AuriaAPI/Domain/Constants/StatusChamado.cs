namespace AuriaAPI.Domain.Constants;

/// <summary>Ciclo de vida de um chamado: Aberto → Em Execucao → Concluido, ou Aberto/Em Execucao → Cancelado.</summary>
public static class StatusChamado
{
    public const string Aberto = "Aberto";
    public const string EmExecucao = "Em Execucao";
    public const string Concluido = "Concluido";
    public const string Cancelado = "Cancelado";

    public static readonly IReadOnlyList<string> Todos = new[] { Aberto, EmExecucao, Concluido, Cancelado };

    public static bool EstaFinalizado(string status) => status == Concluido || status == Cancelado;
}
