using AuriaAPI.Application.DTOs;
using AuriaAPI.Domain.Entities;

namespace AuriaAPI.Application.Mappings;

/// <summary>Conversão entidade → DTO de resposta, num lugar só (as entidades nunca são devolvidas direto pela API).</summary>
public static class Mapeamentos
{
    public static UsuarioResponseDto ParaDto(this Usuario u) => new(u.Id, u.Nome, u.Email, u.Perfil);

    public static AmbienteResponseDto ParaDto(this Ambiente a) =>
        new(a.Id, a.Identificacao, a.PredioBloco, a.Andar, a.Observacoes);

    public static AtivoResponseDto ParaDto(this Ativo a) => new(
        a.Id, a.Patrimonio, a.Nome, a.EstadoConservacao,
        a.DataAquisicao, a.PrazoGarantia, a.VidaUtilEstimadaAnos,
        a.AmbienteId, a.Ambiente?.Identificacao);

    public static ItemEstoqueResponseDto ParaDto(this ItemEstoque i) => new(
        i.Id, i.Nome, i.CodigoInterno, i.QuantidadeEstoque, i.EstoqueMinimo, i.CustoUnitario, i.EstaAbaixoDoMinimo);

    public static NotificacaoResponseDto ParaDto(this Notificacao n) => new(
        n.Id, n.Titulo, n.Mensagem, n.DataCriacao, n.Lida, n.UsuarioId, n.Usuario?.Nome);

    public static ChamadoResponseDto ParaDto(this Chamado c)
    {
        var ordemAtual = OrdemMaisRecente(c);
        return new ChamadoResponseDto(
            c.Id,
            c.Descricao,
            c.TipoManutencao,
            c.Prioridade,
            c.Status,
            c.DataAbertura,
            c.DataFechamento,
            c.SolicitanteId,
            c.Solicitante?.Nome ?? "Desconhecido",
            ordemAtual?.Id,
            ordemAtual?.TecnicoId,
            ordemAtual?.Tecnico?.Nome,
            c.AtivoId,
            c.Ativo?.Nome,
            c.Ativo?.Ambiente?.Identificacao ?? "Desconhecido",
            c.LocalizacaoDetalhada);
    }

    public static OrdemServicoResponseDto ParaDto(this OrdemServico os) => new(
        os.Id,
        os.ChamadoId,
        os.TecnicoId,
        os.Tecnico?.Nome,
        os.TempoGastoMinutos,
        os.ParecerTecnico,
        os.CustoMaoObra,
        os.CustoPecas,
        os.CustoTotal,
        os.DataInicio,
        os.DataConclusao,
        os.EstaConcluida,
        os.Chamado?.Status,
        os.Chamado?.Descricao,
        os.Chamado?.Prioridade,
        os.Chamado?.TipoManutencao,
        os.Chamado?.DataAbertura,
        os.Chamado?.AtivoId,
        os.Chamado?.Ativo?.Nome,
        os.Chamado?.SolicitanteId,
        os.Chamado?.Solicitante?.Nome,
        os.OrdensServicoItens
            .Select(i =>
            {
                var custoUnitario = i.ItemEstoque?.CustoUnitario ?? 0m;
                return new ItemUtilizadoResponseDto(i.ItemEstoqueId, i.ItemEstoque?.Nome, i.QuantidadeUtilizada, custoUnitario, custoUnitario * i.QuantidadeUtilizada);
            })
            .ToList());

    /// <summary>A OS "atual" do chamado: a que ainda está aberta ou, se todas fecharam, a mais recente.</summary>
    private static OrdemServico? OrdemMaisRecente(Chamado c) =>
        c.OrdensServico
            .OrderBy(os => os.EstaConcluida)
            .ThenByDescending(os => os.DataInicio)
            .FirstOrDefault();
}
