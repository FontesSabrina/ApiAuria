import '../../../core/network/api_client.dart';
import '../../../core/network/api_parsers.dart';
import '../../../domain/entities/item_estoque.dart';

class EstoqueRemoteDataSource {
  final ApiClient _api;

  EstoqueRemoteDataSource(this._api);

  Future<List<ItemEstoque>> buscarTodos() async {
    final data = await _api.get('/itensestoque') as List;
    return data.map((json) => _fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Itens com quantidade menor ou igual ao estoque mínimo (filtro feito pela API).
  Future<List<ItemEstoque>> buscarItensAbaixoDoMinimo() async {
    final data = await _api.get('/itensestoque/criticos') as List;
    return data.map((json) => _fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<ItemEstoque?> buscarPorId(String id) async {
    if (!idDoServidor(id)) return null;
    final data = await _api.get('/itensestoque/$id') as Map<String, dynamic>;
    return _fromJson(data);
  }

  Future<void> salvar(ItemEstoque item) async {
    // A API não tem unidadeMedida/fornecedor (só existem no app) nem um
    // "código interno" separado do nome — reaproveita o nome como código.
    final body = {
      'nome': item.nome,
      'codigoInterno': item.nome,
      'quantidadeEstoque': item.quantidade,
      'estoqueMinimo': item.nivelMinimo,
      'custoUnitario': item.precoUnitario,
    };

    if (idDoServidor(item.id)) {
      await _api.put('/itensestoque/${item.id}', body: body);
    } else {
      await _api.post('/itensestoque', body: body);
    }
  }

  Future<void> excluir(String id) async {
    await _api.delete('/itensestoque/$id');
  }

  ItemEstoque _fromJson(Map<String, dynamic> json) => ItemEstoque(
        id: json['id'].toString(),
        nome: json['nome'] as String? ?? '',
        quantidade: json['quantidadeEstoque'] as int? ?? 0,
        nivelMinimo: json['estoqueMinimo'] as int? ?? 5,
        precoUnitario: paraDouble(json['custoUnitario']),
      );
}
