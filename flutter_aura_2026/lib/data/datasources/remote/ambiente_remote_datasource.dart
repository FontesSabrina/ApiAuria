import '../../../core/network/api_client.dart';
import '../../../core/network/api_parsers.dart';
import '../../../domain/entities/ambiente.dart';

class AmbienteRemoteDataSource {
  final ApiClient _api;

  AmbienteRemoteDataSource(this._api);

  /// A API devolve esta lista do cache (5 min) quando possível.
  Future<List<Ambiente>> buscarTodos() async {
    final data = await _api.get('/ambientes') as List;
    return data.map((json) => _fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<void> salvar(Ambiente ambiente) async {
    final body = {
      'identificacao': ambiente.nome,
      'predioBloco': ambiente.predio.isEmpty ? null : ambiente.predio,
      'andar': ambiente.andar.isEmpty ? null : ambiente.andar,
      'observacoes': ambiente.observacoes.isEmpty ? null : ambiente.observacoes,
    };

    if (idDoServidor(ambiente.id)) {
      await _api.put('/ambientes/${ambiente.id}', body: body);
    } else {
      await _api.post('/ambientes', body: body);
    }
  }

  Future<void> excluir(String id) async {
    await _api.delete('/ambientes/$id');
  }

  Ambiente _fromJson(Map<String, dynamic> json) => Ambiente(
        id: json['id'].toString(),
        nome: json['identificacao'] as String? ?? '',
        predio: json['predioBloco'] as String? ?? '',
        andar: json['andar'] as String? ?? '',
        observacoes: json['observacoes'] as String? ?? '',
      );
}
