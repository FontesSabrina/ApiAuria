import '../../../core/network/api_client.dart';
import '../../../core/network/api_parsers.dart';
import '../../../domain/entities/alerta_preventiva.dart';
import '../../../domain/entities/ordem_servico.dart';
import 'ordem_servico_remote_datasource.dart';

class PlanejamentoRemoteDataSource {
  final ApiClient _api;

  PlanejamentoRemoteDataSource(this._api);

  /// Ordens de serviço de chamados preventivos abertos no dia informado.
  Future<List<OrdemServico>> buscarCronograma(DateTime data) async {
    final lista = await _api.get('/planejamento/cronograma', query: {'data': dataParaApi(data)}) as List;
    return lista.map((json) => ordemServicoFromJson(json as Map<String, dynamic>)).toList();
  }

  /// Ativos que precisam de preventiva (regra calculada pela API).
  Future<List<AlertaPreventiva>> buscarAlertas() async {
    final lista = await _api.get('/planejamento/alertas') as List;
    return lista
        .map((json) => json as Map<String, dynamic>)
        .map((json) => AlertaPreventiva(
              ativoId: json['ativoId'].toString(),
              nome: json['nome'] as String? ?? '',
              patrimonio: json['patrimonio'] as String? ?? '',
              estadoConservacao: json['estadoConservacao'] as String? ?? '',
              ambienteNome: json['ambienteNome'] as String?,
              motivos: (json['motivos'] as List? ?? const []).map((m) => m.toString()).toList(),
            ))
        .toList();
  }
}
