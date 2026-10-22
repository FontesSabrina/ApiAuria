import '../../../core/network/api_client.dart';
import '../../../core/network/api_parsers.dart';
import '../../../domain/entities/item_estoque.dart';
import '../../../domain/entities/ordem_servico.dart';

/// A API já devolve a OS com os dados do chamado vinculado (ativo, solicitante,
/// prioridade, descrição) e com o custo das peças calculado.
class OrdemServicoRemoteDataSource {
  final ApiClient _api;

  OrdemServicoRemoteDataSource(this._api);

  Future<List<OrdemServico>> buscarTodos() async {
    final data = await _api.get('/ordemservico') as List;
    return data.map((json) => ordemServicoFromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<OrdemServico>> buscarMinhas() async {
    final data = await _api.get('/ordemservico/minhas') as List;
    return data.map((json) => ordemServicoFromJson(json as Map<String, dynamic>)).toList();
  }

  Future<OrdemServico?> buscarPorId(String id) async {
    if (!idDoServidor(id)) return null;
    final data = await _api.get('/ordemservico/$id') as Map<String, dynamic>;
    return ordemServicoFromJson(data);
  }

  Future<void> abrir({required String chamadoId, required String tecnicoId}) async {
    await _api.post('/ordemservico', body: {
      'chamadoId': int.parse(chamadoId),
      'tecnicoId': int.parse(tecnicoId),
      'tempoGastoMinutos': 0,
      'custoMaoObra': 0,
    });
  }

  Future<OrdemServico> registrarConsumo({required String ordemId, required String itemEstoqueId, required int quantidade}) async {
    final data = await _api.post('/ordemservico/$ordemId/itens', body: {
      'itens': [
        {'itemEstoqueId': int.parse(itemEstoqueId), 'quantidadeUtilizada': quantidade},
      ],
    }) as Map<String, dynamic>;
    return ordemServicoFromJson(data);
  }

  Future<void> concluir({
    required String ordemId,
    required String parecerTecnico,
    required int tempoGastoMinutos,
    required double custoMaoDeObra,
  }) async {
    await _api.put('/ordemservico/$ordemId/concluir', body: {
      'tempoGastoMinutos': tempoGastoMinutos,
      'parecerTecnico': parecerTecnico,
      'custoMaoObra': custoMaoDeObra,
    });
  }
}

/// Também usado pelo PlanejamentoRemoteDataSource (o cronograma devolve ordens de serviço).
OrdemServico ordemServicoFromJson(Map<String, dynamic> json) {
  final dataInicio = dataDoServidor(json['dataInicio'] as String);
  final itens = (json['itensUtilizados'] as List? ?? const [])
      .map((i) => i as Map<String, dynamic>)
      .map((i) => ItemEstoque(
            id: i['itemEstoqueId'].toString(),
            nome: i['itemNome'] as String? ?? '',
            quantidade: i['quantidadeUtilizada'] as int? ?? 0,
            precoUnitario: paraDouble(i['custoUnitario']),
          ))
      .toList();

  return OrdemServico(
    id: json['id'].toString(),
    chamadoId: json['chamadoId'].toString(),
    ativoId: json['ativoId']?.toString() ?? '',
    ativoNome: json['ativoNome'] as String?,
    solicitanteId: json['solicitanteId']?.toString() ?? '',
    descricaoProblema: json['descricaoProblema'] as String? ?? '',
    dataAbertura: dataDoServidorOuNula(json['dataAbertura']) ?? dataInicio,
    prioridade: json['prioridade'] as String? ?? 'Baixa',
    tipoManutencao: json['tipoManutencao'] as String? ?? 'Corretiva',
    tecnicoResponsavelId: json['tecnicoId'].toString(),
    tecnicoNome: json['tecnicoNome'] as String?,
    status: json['concluida'] == true ? StatusOS.concluida : StatusOS.aberta,
    relatotecnico: json['parecerTecnico'] as String?,
    dataInicio: dataInicio,
    dataFim: dataDoServidorOuNula(json['dataConclusao']),
    tempoGastoMinutos: json['tempoGastoMinutos'] as int? ?? 0,
    custoPecas: paraDouble(json['custoPecas']),
    custoMaoDeObra: paraDouble(json['custoMaoObra']),
    pecasUtilizadas: itens,
  );
}
