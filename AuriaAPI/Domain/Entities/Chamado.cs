using AuriaAPI.Domain.Constants;
using AuriaAPI.Domain.Exceptions;

namespace AuriaAPI.Domain.Entities;

public class Chamado
{
    public int Id { get; set; }
    public string Descricao { get; set; } = string.Empty;

    public string? LocalizacaoDetalhada { get; set; }

    public string TipoManutencao { get; set; } = TiposManutencao.Corretiva;
    public string Prioridade { get; set; } = Prioridades.Baixa;
    public string Status { get; set; } = StatusChamado.Aberto;

    public DateTime DataAbertura { get; set; } = DateTime.UtcNow;
    public DateTime? DataFechamento { get; set; }

    public int SolicitanteId { get; set; }
    public Usuario? Solicitante { get; set; }

    public int AtivoId { get; set; }
    public Ativo? Ativo { get; set; }

    public ICollection<OrdemServico> OrdensServico { get; set; } = new List<OrdemServico>();

    /// <summary>Um chamado só pode receber uma ordem de serviço enquanto está "Aberto".</summary>
    public void IniciarExecucao()
    {
        if (Status != StatusChamado.Aberto)
            throw new RegraDeNegocioException($"Só é possível gerar ordem de serviço para chamados com status '{StatusChamado.Aberto}'. Status atual: '{Status}'.");

        Status = StatusChamado.EmExecucao;
    }

    public void Concluir()
    {
        if (Status != StatusChamado.EmExecucao)
            throw new RegraDeNegocioException($"Só é possível concluir chamados com status '{StatusChamado.EmExecucao}'. Status atual: '{Status}'.");

        Status = StatusChamado.Concluido;
        DataFechamento = DateTime.UtcNow;
    }

    /// <summary>
    /// Só chamados ainda "Aberto" podem ser cancelados. Um chamado em execução já tem
    /// uma ordem de serviço em andamento e deve ser encerrado pela conclusão da OS.
    /// </summary>
    public void Cancelar()
    {
        if (Status != StatusChamado.Aberto)
            throw new RegraDeNegocioException($"Só é possível cancelar chamados com status '{StatusChamado.Aberto}'. Status atual: '{Status}'.");

        Status = StatusChamado.Cancelado;
        DataFechamento = DateTime.UtcNow;
    }
}
