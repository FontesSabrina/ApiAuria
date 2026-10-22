import '../entities/ordem_servico.dart';

abstract class OrdemServicoRepository {
  Future<List<OrdemServico>> buscarTodos();
  /// Ordens designadas ao técnico logado.
  Future<List<OrdemServico>> buscarMinhas();
  Future<OrdemServico?> buscarPorId(String id);
  /// Abre a OS de um chamado "Aberto", designando o técnico.
  Future<void> abrir({required String chamadoId, required String tecnicoId});
  /// Registra peças consumidas (a API debita o estoque e recalcula o custo de peças).
  Future<OrdemServico> registrarConsumo({required String ordemId, required String itemEstoqueId, required int quantidade});
  Future<void> concluir({
    required String ordemId,
    required String parecerTecnico,
    required int tempoGastoMinutos,
    required double custoMaoDeObra,
  });
}
