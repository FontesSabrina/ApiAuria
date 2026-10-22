import '../../domain/entities/indicadores.dart';
import '../../domain/repositories/indicadores_repository.dart';
import '../datasources/remote/indicadores_remote_datasource.dart';

class IndicadoresRepositoryRemoteImpl implements IndicadoresRepository {
  final IndicadoresRemoteDataSource remoteDataSource;

  IndicadoresRepositoryRemoteImpl(this.remoteDataSource);

  @override
  Future<Indicadores> buscarResumo() => remoteDataSource.buscarResumo();
}
