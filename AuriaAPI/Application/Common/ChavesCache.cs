namespace AuriaAPI.Application.Common;

/// <summary>Chaves usadas no cache, centralizadas para que leitura e invalidação usem sempre o mesmo nome.</summary>
public static class ChavesCache
{
    public const string ListaAmbientes = "ambientes:lista";
    public const string Indicadores = "indicadores:resumo";
}
