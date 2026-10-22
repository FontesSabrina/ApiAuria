import '../../../core/network/api_client.dart';
import '../../../core/network/api_parsers.dart';
import '../../../domain/entities/ativo.dart';

class AtivoRemoteDataSource {
  final ApiClient _api;

  AtivoRemoteDataSource(this._api);

  Future<List<Ativo>> buscarTodos({String? ambienteId}) async {
    final data = await _api.get('/ativos', query: ambienteId == null ? null : {'ambienteId': ambienteId}) as List;
    return data.map((json) => _fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Ativo?> buscarPorId(String id) async {
    if (!idDoServidor(id)) return null;
    final data = await _api.get('/ativos/$id') as Map<String, dynamic>;
    return _fromJson(data);
  }

  Future<void> salvar(Ativo ativo) async {
    final body = {
      'patrimonio': ativo.patrimonio,
      'nome': ativo.nome,
      'estadoConservacao': ativo.estadoConservacao,
      'dataAquisicao': ativo.dataAquisicao.toIso8601String(),
      'prazoGarantia': null,
      'vidaUtilEstimadaAnos': null,
      'ambienteId': int.parse(ativo.ambienteId),
    };

    if (idDoServidor(ativo.id)) {
      await _api.put('/ativos/${ativo.id}', body: body);
    } else {
      await _api.post('/ativos', body: body);
    }
  }

  Future<void> excluir(String id) async {
    await _api.delete('/ativos/$id');
  }

  Ativo _fromJson(Map<String, dynamic> json) => Ativo(
        id: json['id'].toString(),
        patrimonio: json['patrimonio'] as String? ?? '',
        nome: json['nome'] as String? ?? '',
        ambienteId: json['ambienteId'].toString(),
        ambienteNome: json['ambienteIdentificacao'] as String?,
        estadoConservacao: json['estadoConservacao'] as String? ?? 'Novo',
        dataAquisicao: json['dataAquisicao'] != null ? DateTime.parse(json['dataAquisicao'] as String) : DateTime.now(),
      );
}
