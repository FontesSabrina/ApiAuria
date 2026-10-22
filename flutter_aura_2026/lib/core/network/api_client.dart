import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';
import 'auth_session.dart';

/// Cliente HTTP da AuriaAPI.
///
/// - Anexa `Authorization: Bearer <token>` quando há uma sessão ativa;
/// - desembrulha o ResultWrapper (`{success, message, data, errors}`) e devolve só o `data`;
/// - converte qualquer falha (regra de negócio, validação, 401/403/404/409/500 ou rede)
///   numa [ApiException] com a mensagem enviada pela API, pronta para um SnackBar;
/// - em 401 numa rota protegida (token expirado/inválido), encerra a sessão e
///   avisa o app pelo callback [AuthSession.onSessaoExpirada] para voltar ao login.
class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  static const _rotasPublicas = {'/auth/login', '/auth/register'};

  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    final token = AuthSession.instance.token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final queryParams = query?.map((k, v) => MapEntry(k, v.toString()));
    return Uri.parse('$apiBaseUrl$path').replace(queryParameters: queryParams);
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(path, () => _client.get(_uri(path, query), headers: _headers));

  Future<dynamic> post(String path, {Object? body}) => _send(
        path,
        () => _client.post(_uri(path), headers: _headers, body: body == null ? null : jsonEncode(body)),
      );

  Future<dynamic> put(String path, {Object? body}) => _send(
        path,
        () => _client.put(_uri(path), headers: _headers, body: body == null ? null : jsonEncode(body)),
      );

  Future<dynamic> delete(String path) => _send(path, () => _client.delete(_uri(path), headers: _headers));

  Future<dynamic> _send(String path, Future<http.Response> Function() request) async {
    http.Response response;
    try {
      response = await request().timeout(const Duration(seconds: 20));
    } on SocketException {
      throw ApiException('Não foi possível conectar à API. Verifique se ela está rodando e o endereço configurado.');
    } catch (e) {
      throw ApiException('Erro de rede ao falar com a API: $e');
    }

    final body = _decodificar(response);
    final success = body?['success'] as bool? ?? (response.statusCode >= 200 && response.statusCode < 300);

    if (!success) {
      final message = body?['message'] as String? ?? _mensagemPadrao(response.statusCode);
      final errors = (body?['errors'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];

      if (response.statusCode == 401 && !_rotasPublicas.contains(path)) {
        await AuthSession.instance.encerrarPorExpiracao(message);
      }

      throw ApiException(message, errors: errors, statusCode: response.statusCode);
    }

    return body?['data'];
  }

  Map<String, dynamic>? _decodificar(http.Response response) {
    if (response.body.isEmpty) return null;
    try {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      return json is Map<String, dynamic> ? json : null;
    } catch (_) {
      return null; // corpo não é JSON — segue com a mensagem padrão do status
    }
  }

  String _mensagemPadrao(int statusCode) {
    switch (statusCode) {
      case 401:
        return 'Sessão expirada ou inválida. Faça login novamente.';
      case 403:
        return 'Você não tem permissão para realizar esta ação.';
      case 404:
        return 'Registro não encontrado.';
      default:
        return 'Erro ao comunicar com a API ($statusCode).';
    }
  }
}
