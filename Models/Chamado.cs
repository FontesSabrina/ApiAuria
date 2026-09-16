namespace AuriaAPI.Models;

public class Chamado
{
    public int Id { get; set; }
    public string Descricao { get; set; } = string.Empty;
    
    // Novo campo adicionado conforme o diagrama do banco de dados
    public string? LocalizacaoDetalhada { get; set; }

    public string TipoManutencao { get; set; } = "Corretiva";
    public string Prioridade { get; set; } = "Baixa";
    public string Status { get; set; } = "Aberto";

    public DateTime DataAbertura { get; set; } = DateTime.UtcNow;
    public DateTime? DataFechamento { get; set; }

    public int SolicitanteId { get; set; }
    public Usuario? Solicitante { get; set; }

    public int AtivoId { get; set; }
    public Ativo? Ativo { get; set; }

    public ICollection<OrdemServico> OrdensServico { get; set; } = new List<OrdemServico>();
}
