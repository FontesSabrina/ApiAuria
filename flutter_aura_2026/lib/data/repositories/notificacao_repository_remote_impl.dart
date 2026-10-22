import '../../domain/entities/notificacao.dart';
import '../../domain/repositories/notificacao_repository.dart';
import '../datasources/remote/notificacao_remote_datasource.dart';

class NotificacaoRepositoryRemoteImpl implements NotificacaoRepository {
  final NotificacaoRemoteDataSource remoteDataSource;

  NotificacaoRepositoryRemoteImpl(this.remoteDataSource);

  @override
  Future<List<Notificacao>> buscarMinhasNotificacoes() => remoteDataSource.buscarMinhasNotificacoes();

  @override
  Future<void> marcarComoLida(String id) => remoteDataSource.marcarComoLida(id);
}
