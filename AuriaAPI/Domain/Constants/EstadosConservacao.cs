namespace AuriaAPI.Domain.Constants;

/// <summary>Estados de conservação de um ativo e as regras de alerta de manutenção preventiva.</summary>
public static class EstadosConservacao
{
    public const string Novo = "Novo";
    public const string Bom = "Bom";
    public const string Regular = "Regular";
    public const string Ruim = "Ruim";
    public const string EmManutencao = "Em Manutenção";
    public const string Desativado = "Desativado";

    public static readonly IReadOnlyList<string> Todos = new[] { Novo, Bom, Regular, Ruim, EmManutencao, Desativado };

    /// <summary>Estados que, por si só, já indicam que o ativo precisa de atenção preventiva.</summary>
    public static readonly IReadOnlyList<string> QueGeramAlerta = new[] { Regular, Ruim, EmManutencao };

    /// <summary>A partir de quantos dias de uso um ativo entra no alerta de preventiva.</summary>
    public const int DiasUsoParaAlerta = 730;
}
