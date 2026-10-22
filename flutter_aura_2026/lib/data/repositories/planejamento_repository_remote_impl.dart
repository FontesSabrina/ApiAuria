import '../../domain/entities/alerta_preventiva.dart';
import '../../domain/entities/ordem_servico.dart';
import '../../domain/repositories/planejamento_repository.dart';
import '../datasources/remote/planejamento_remote_datasource.dart';

class PlanejamentoRepositoryRemoteImpl implements PlanejamentoRepository {
  final PlanejamentoRemoteDataSource remoteDataSource;

  PlanejamentoRepositoryRemoteImpl(this.remoteDataSource);

  @override
  Future<List<OrdemServico>> buscarCronograma(DateTime data) => remoteDataSource.buscarCronograma(data);

  @override
  Future<List<AlertaPreventiva>> buscarAlertas() => remoteDataSource.buscarAlertas();
}
