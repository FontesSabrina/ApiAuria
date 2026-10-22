import '../entities/item_estoque.dart';
import '../repositories/estoque_repository.dart';

/// A baixa de estoque não é feita aqui: ela acontece na API, ao registrar o consumo
/// de peças numa ordem de serviço (POST /api/ordemservico/{id}/itens).
class EstoqueDomainServices {
  final EstoqueRepository _repository;

  EstoqueDomainServices(this._repository);

  Future<List<ItemEstoque>> buscarTodos() => _repository.buscarTodos();

  Future<List<ItemEstoque>> buscarItensCriticos() => _repository.buscarItensAbaixoDoMinimo();

  Future<void> salvar(ItemEstoque item) => _repository.salvar(item);
}
