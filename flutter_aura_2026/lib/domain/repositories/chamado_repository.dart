import '../entities/chamado.dart';

abstract class ChamadoRepository {
  /// Todos os chamados (apenas técnicos e administradores).
  Future<List<Chamado>> buscarTodos();
  /// Chamados abertos pelo usuário logado (identificado pelo token).
  Future<List<Chamado>> buscarMeusChamados();
  Future<Chamado?> buscarPorId(String id);
  /// Abre um novo chamado (o solicitante é o usuário logado).
  Future<void> salvar(Chamado chamado);
  Future<void> cancelar(String idChamado);
}
