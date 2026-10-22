import '../../domain/entities/ativo.dart';
import '../../domain/repositories/ativo_repository.dart';
import '../datasources/remote/ativo_remote_datasource.dart';

class AtivoRepositoryRemoteImpl implements AtivoRepository {
  final AtivoRemoteDataSource remoteDataSource;

  AtivoRepositoryRemoteImpl(this.remoteDataSource);

  @override
  Future<List<Ativo>> buscarTodos() => remoteDataSource.buscarTodos();

  @override
  Future<Ativo?> buscarPorId(String id) => remoteDataSource.buscarPorId(id);

  @override
  Future<void> salvar(Ativo ativo) => remoteDataSource.salvar(ativo);

  @override
  Future<List<Ativo>> buscarPorAmbiente(String ambienteId) => remoteDataSource.buscarTodos(ambienteId: ambienteId);

  @override
  Future<void> excluir(String id) => remoteDataSource.excluir(id);
}
