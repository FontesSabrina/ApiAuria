import '../../../core/network/api_client.dart';
import '../../../core/network/api_parsers.dart';
import '../../../domain/entities/ativo.dart';
import '../../../domain/entities/chamado.dart';
import '../../../domain/entities/usuario.dart';

String _tipoToApi(TipoManutencao tipo) {
  switch (tipo) {
    case TipoManutencao.corretiva:
      return 'Corretiva';
    case TipoManutencao.preventiva:
      return 'Preventiva';
    case TipoManutencao.preditiva:
      return 'Preditiva';
  }
}

TipoManutencao _tipoFromApi(String? tipo) {
  switch (tipo?.toLowerCase()) {
    case 'preventiva':
      return TipoManutencao.preventiva;
    case 'preditiva':
      return TipoManutencao.preditiva;
    default:
      return TipoManutencao.corretiva;
  }
}

StatusChamado _statusFromApi(String status) {
  switch (status.toLowerCase()) {
    case 'em execucao':
      return StatusChamado.emExecucao;
    case 'concluido':
      return StatusChamado.concluido;
    case 'cancelado':
      return StatusChamado.cancelado;
    default:
      return StatusChamado.aberto;
  }
}

class ChamadoRemoteDataSource {
  final ApiClient _api;

  ChamadoRemoteDataSource(this._api);

  Future<List<Chamado>> buscarTodos() async {
    final data = await _api.get('/chamados') as List;
    return data.map((json) => _fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<Chamado>> buscarMeusChamados() async {
    final data = await _api.get('/chamados/meus') as List;
    return data.map((json) => _fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Chamado?> buscarPorId(String id) async {
    if (!idDoServidor(id)) return null;
    final data = await _api.get('/chamados/$id') as Map<String, dynamic>;
    return _fromJson(data);
  }

  /// A API só cria chamados; o status muda por endpoints próprios
  /// (cancelar, abrir OS e concluir OS).
  Future<void> salvar(Chamado chamado) async {
    await _api.post('/chamados', body: {
      'descricao': chamado.descricaoFalha,
      'prioridade': chamado.prioridade,
      'ativoId': int.parse(chamado.ativo.id),
      'tipoManutencao': _tipoToApi(chamado.tipo),
    });
  }

  Future<void> cancelar(String id) async {
    await _api.put('/chamados/$id/cancelar');
  }

  Chamado _fromJson(Map<String, dynamic> json) {
    final ativo = Ativo(
      id: json['ativoId'].toString(),
      patrimonio: '',
      nome: json['ativoNome'] as String? ?? 'Ativo removido',
      ambienteId: '',
      ambienteNome: json['ambienteNome'] as String?,
      estadoConservacao: '',
      dataAquisicao: DateTime.now(),
    );

    final solicitante = Usuario(
      id: json['solicitanteId'].toString(),
      nome: json['solicitanteNome'] as String? ?? 'Desconhecido',
      email: '',
      senha: '',
      perfil: Perfil.solicitante,
    );

    final tecnicoNome = json['tecnicoNome'] as String?;
    final tecnicoResponsavel = tecnicoNome == null
        ? null
        : Usuario(
            id: json['tecnicoId']?.toString() ?? '',
            nome: tecnicoNome,
            email: '',
            senha: '',
            perfil: Perfil.tecnicoResponsavel,
          );

    return Chamado(
      id: json['id'].toString(),
      ativo: ativo,
      solicitante: solicitante,
      descricaoFalha: json['descricao'] as String? ?? '',
      prioridade: json['prioridade'] as String? ?? 'Baixa',
      tipo: _tipoFromApi(json['tipoManutencao'] as String?),
      status: _statusFromApi(json['status'] as String? ?? 'Aberto'),
      dataAbertura: dataDoServidor(json['dataAbertura'] as String),
      tecnicoResponsavel: tecnicoResponsavel,
    );
  }
}
