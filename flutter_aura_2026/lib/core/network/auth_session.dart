import 'package:shared_preferences/shared_preferences.dart';

/// Guarda o token JWT da sessão atual em memória (para o ApiClient anexar em cada
/// requisição) e o persiste via `shared_preferences`.
class AuthSession {
  AuthSession._internal();
  static final AuthSession instance = AuthSession._internal();

  static const _kToken = 'auria_token';
  static const _kUserId = 'auria_user_id';

  String? _token;
  String? _userId;

  /// Chamado quando a API responde 401 numa rota protegida (token expirado ou inválido).
  /// O main.dart usa isso para voltar à tela de login mostrando a mensagem recebida.
  void Function(String mensagem)? onSessaoExpirada;

  String? get token => _token;
  String? get userId => _userId;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_kToken);
    _userId = prefs.getString(_kUserId);
  }

  Future<void> save({required String token, required String userId}) async {
    _token = token;
    _userId = userId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
    await prefs.setString(_kUserId, userId);
  }

  Future<void> clear() async {
    _token = null;
    _userId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kUserId);
  }

  Future<void> encerrarPorExpiracao(String mensagem) async {
    final estavaLogado = isAuthenticated;
    await clear();
    if (estavaLogado) onSessaoExpirada?.call(mensagem);
  }
}
