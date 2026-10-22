import '../../../core/network/api_client.dart';
import '../../../core/network/api_parsers.dart';
import '../../../core/network/auth_session.dart';
import '../../../domain/entities/usuario.dart';

String perfilToApi(Perfil perfil) {
  switch (perfil) {
    case Perfil.administrador:
      return 'Admin';
    case Perfil.tecnicoResponsavel:
      return 'Tecnico';
    case Perfil.solicitante:
      return 'Solicitante';
  }
}

Perfil _perfilFromApi(String? perfil) {
  switch (perfil?.toLowerCase()) {
    case 'admin':
      return Perfil.administrador;
    case 'tecnico':
      return Perfil.tecnicoResponsavel;
    default:
      return Perfil.solicitante;
  }
}

class UsuarioRemoteDataSource {
  final ApiClient _api;

  UsuarioRemoteDataSource(this._api);

  Future<List<Usuario>> buscarTodos() async {
    final data = await _api.get('/usuarios') as List;
    return data.map((json) => _fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Usuario?> buscarPorId(String id) async {
    if (!idDoServidor(id)) return null;
    final data = await _api.get('/usuarios/$id') as Map<String, dynamic>;
    return _fromJson(data);
  }

  Future<List<Usuario>> buscarPorPerfil(Perfil perfil) async {
    final data = await _api.get('/usuarios', query: {'perfil': perfilToApi(perfil)}) as List;
    return data.map((json) => _fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Usuario?> login(String email, String senha) async {
    final data = await _api.post('/auth/login', body: {'email': email, 'senha': senha}) as Map<String, dynamic>;
    await AuthSession.instance.save(token: data['token'] as String, userId: data['id'].toString());
    return Usuario(
      id: data['id'].toString(),
      nome: data['nome'] as String,
      email: data['email'] as String,
      senha: '',
      perfil: _perfilFromApi(data['role'] as String?),
    );
  }

  Future<void> logout() => AuthSession.instance.clear();

  /// Usuário novo (id provisório) → POST /usuarios já com o perfil escolhido.
  /// Usuário existente → PUT /usuarios/{id}; a senha só é trocada se for informada.
  Future<void> salvar(Usuario usuario) async {
    if (idDoServidor(usuario.id)) {
      await _api.put('/usuarios/${usuario.id}', body: {
        'nome': usuario.nome,
        'email': usuario.email,
        'perfil': perfilToApi(usuario.perfil),
        'novaSenha': usuario.senha.isEmpty ? null : usuario.senha,
      });
      return;
    }

    await _api.post('/usuarios', body: {
      'nome': usuario.nome,
      'email': usuario.email,
      'senha': usuario.senha,
      'perfil': perfilToApi(usuario.perfil),
    });
  }

  Future<void> excluir(String id) async {
    await _api.delete('/usuarios/$id');
  }

  Usuario _fromJson(Map<String, dynamic> json) => Usuario(
        id: json['id'].toString(),
        nome: json['nome'] as String? ?? '',
        email: json['email'] as String? ?? '',
        senha: '',
        perfil: _perfilFromApi(json['perfil'] as String?),
      );
}
