import '../../../core/network/api_client.dart';
import '../../../core/network/api_parsers.dart';
import '../../../domain/entities/indicadores.dart';

class IndicadoresRemoteDataSource {
  final ApiClient _api;

  IndicadoresRemoteDataSource(this._api);

  /// Os números são calculados pela API (resultado em cache por 2 minutos).
  Future<Indicadores> buscarResumo() async {
    final json = await _api.get('/indicadores') as Map<String, dynamic>;

    final porStatus = (json['chamadosPorStatus'] as Map<String, dynamic>? ?? const {})
        .map((status, quantidade) => MapEntry(status, (quantidade as num).toInt()));

    final top = (json['topAtivosComFalhas'] as List? ?? const [])
        .map((a) => a as Map<String, dynamic>)
        .map((a) => AtivoFalhas(
              ativoId: a['ativoId'].toString(),
              ativoNome: a['ativoNome'] as String? ?? '',
              quantidadeOrdens: a['quantidadeOrdens'] as int? ?? 0,
            ))
        .toList();

    final pendentes = (json['ordensPendentes'] as List? ?? const [])
        .map((o) => o as Map<String, dynamic>)
        .map((o) => OrdemPendente(
              ordemServicoId: o['ordemServicoId'].toString(),
              ativoNome: o['ativoNome'] as String? ?? '',
              descricaoProblema: o['descricaoProblema'] as String? ?? '',
              prioridade: o['prioridade'] as String? ?? '',
              tecnicoNome: o['tecnicoNome'] as String?,
            ))
        .toList();

    return Indicadores(
      totalOrdens: json['totalOrdens'] as int? ?? 0,
      ordensConcluidas: json['ordensConcluidas'] as int? ?? 0,
      ordensEmAberto: json['ordensEmAberto'] as int? ?? 0,
      taxaConclusao: paraDouble(json['taxaConclusao']),
      custoTotal: paraDouble(json['custoTotal']),
      custoMaoObra: paraDouble(json['custoMaoObra']),
      custoPecas: paraDouble(json['custoPecas']),
      tempoMedioAtendimentoHoras: paraDouble(json['tempoMedioAtendimentoHoras']),
      tempoMedioExecucaoHoras: paraDouble(json['tempoMedioExecucaoHoras']),
      chamadosPorStatus: porStatus,
      topAtivosComFalhas: top,
      ordensPendentes: pendentes,
      geradoEm: dataDoServidor(json['geradoEm'] as String),
    );
  }
}
