import '../entities/notificacao.dart';

/// As notificações são geradas pela própria API (chamado aberto, OS concluída, estoque baixo...);
/// o app só consulta e marca como lida.
abstract class NotificacaoRepository {
  Future<List<Notificacao>> buscarMinhasNotificacoes();
  Future<void> marcarComoLida(String id);
}
