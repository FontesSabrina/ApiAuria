import '../entities/usuario.dart';
import '../repositories/usuario_repository.dart';

class UsuarioDomainServices {
  final UsuarioRepository _repository;

  UsuarioDomainServices(this._repository);

  Future<Usuario?> autenticar(String email, String senha) async {
    if (email.isEmpty || senha.isEmpty) return null;
    
    return await _repository.login(email.trim(), senha.trim());
  }

  Future<Usuario?> buscarPorId(String id) async => await _repository.buscarPorId(id);
}