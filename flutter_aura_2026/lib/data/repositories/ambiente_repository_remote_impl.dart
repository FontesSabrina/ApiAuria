import '../../domain/entities/ambiente.dart';
import '../../domain/repositories/ambiente_repository.dart';
import '../datasources/remote/ambiente_remote_datasource.dart';

class AmbienteRepositoryRemoteImpl implements AmbienteRepository {
  final AmbienteRemoteDataSource remoteDataSource;

  AmbienteRepositoryRemoteImpl(this.remoteDataSource);

  @override
  Future<List<Ambiente>> buscarTodos() => remoteDataSource.buscarTodos();

  @override
  Future<void> salvar(Ambiente ambiente) => remoteDataSource.salvar(ambiente);

  @override
  Future<void> excluir(String id) => remoteDataSource.excluir(id);
}
