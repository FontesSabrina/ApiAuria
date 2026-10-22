import '../../domain/entities/chamado.dart';
import '../../domain/repositories/chamado_repository.dart';
import '../datasources/remote/chamado_remote_datasource.dart';

class ChamadoRepositoryRemoteImpl implements ChamadoRepository {
  final ChamadoRemoteDataSource remoteDataSource;

  ChamadoRepositoryRemoteImpl(this.remoteDataSource);

  @override
  Future<List<Chamado>> buscarTodos() => remoteDataSource.buscarTodos();

  @override
  Future<List<Chamado>> buscarMeusChamados() => remoteDataSource.buscarMeusChamados();

  @override
  Future<Chamado?> buscarPorId(String id) => remoteDataSource.buscarPorId(id);

  @override
  Future<void> salvar(Chamado chamado) => remoteDataSource.salvar(chamado);

  @override
  Future<void> cancelar(String idChamado) => remoteDataSource.cancelar(idChamado);
}
