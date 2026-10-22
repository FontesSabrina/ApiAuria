import '../entities/usuario.dart';

abstract class UsuarioRepository {
  Future<List<Usuario>> buscarTodos();
  Future<Usuario?> login(String email, String senha);
  Future<void> logout();
  Future<Usuario?> buscarPorId(String id);
  Future<List<Usuario>> buscarPorPerfil(Perfil perfil);
  /// Cria (id ainda não numérico) ou atualiza (id do servidor) um usuário.
  Future<void> salvar(Usuario usuario);
  Future<void> excluir(String id);
}
