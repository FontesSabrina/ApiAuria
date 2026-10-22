import '../../domain/entities/item_estoque.dart';
import '../../domain/repositories/estoque_repository.dart';
import '../datasources/remote/estoque_remote_datasource.dart';

class EstoqueRepositoryRemoteImpl implements EstoqueRepository {
  final EstoqueRemoteDataSource remoteDataSource;

  EstoqueRepositoryRemoteImpl(this.remoteDataSource);

  @override
  Future<List<ItemEstoque>> buscarTodos() => remoteDataSource.buscarTodos();

  @override
  Future<ItemEstoque?> buscarPorId(String id) => remoteDataSource.buscarPorId(id);

  @override
  Future<void> salvar(ItemEstoque item) => remoteDataSource.salvar(item);

  @override
  Future<void> excluir(String id) => remoteDataSource.excluir(id);

  @override
  Future<List<ItemEstoque>> buscarItensAbaixoDoMinimo() => remoteDataSource.buscarItensAbaixoDoMinimo();
}
