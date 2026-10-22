import '../entities/item_estoque.dart';

abstract class EstoqueRepository {
  Future<List<ItemEstoque>> buscarTodos();
  Future<ItemEstoque?> buscarPorId(String id);
  Future<void> salvar(ItemEstoque item);
  Future<void> excluir(String id);
  Future<List<ItemEstoque>> buscarItensAbaixoDoMinimo();
}
