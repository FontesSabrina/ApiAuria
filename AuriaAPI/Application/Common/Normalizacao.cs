namespace AuriaAPI.Application.Common;

public static class Normalizacao
{
    /// <summary>E-mails são comparados e gravados sempre sem espaços e em minúsculas.</summary>
    public static string Email(string email) => email.Trim().ToLowerInvariant();
}
