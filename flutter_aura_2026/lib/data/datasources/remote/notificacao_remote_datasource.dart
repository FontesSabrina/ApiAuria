import '../../../core/network/api_client.dart';
import '../../../core/network/api_parsers.dart';
import '../../../domain/entities/notificacao.dart';

class NotificacaoRemoteDataSource {
  final ApiClient _api;

  NotificacaoRemoteDataSource(this._api);

  /// A API devolve só as notificações do usuário do token.
  Future<List<Notificacao>> buscarMinhasNotificacoes() async {
    final data = await _api.get('/notificacoes') as List;
    return data.map((json) => _fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<void> marcarComoLida(String id) async {
    await _api.put('/notificacoes/$id/lida');
  }

  Notificacao _fromJson(Map<String, dynamic> json) => Notificacao(
        id: json['id'].toString(),
        titulo: json['titulo'] as String? ?? '',
        mensagem: json['mensagem'] as String? ?? '',
        dataCriacao: dataDoServidor(json['dataCriacao'] as String),
        lida: json['lida'] as bool? ?? false,
        usuarioId: json['usuarioId'].toString(),
      );
}
