namespace AuriaAPI.Infra.Security;

/// <summary>Configuração do JWT (seção "Jwt"). A SecretKey NUNCA fica no código: vem de user-secrets ou variável de ambiente.</summary>
public class JwtSettings
{
    public const string Secao = "Jwt";
    public const int TamanhoMinimoChave = 32;

    public string SecretKey { get; set; } = string.Empty;
    public string Issuer { get; set; } = "AuriaAPI";
    public string Audience { get; set; } = "AuriaAPI";
    public int ExpiracaoHoras { get; set; } = 8;
}
