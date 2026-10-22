import '../../domain/entities/usuario.dart';
import '../../domain/repositories/usuario_repository.dart';
import '../datasources/remote/usuario_remote_datasource.dart';

class UsuarioRepositoryRemoteImpl implements UsuarioRepository {
  final UsuarioRemoteDataSource remoteDataSource;

  UsuarioRepositoryRemoteImpl(this.remoteDataSource);

  @override
  Future<List<Usuario>> buscarTodos() => remoteDataSource.buscarTodos();

  @override
  Future<Usuario?> login(String email, String senha) => remoteDataSource.login(email, senha);

  @override
  Future<void> logout() => remoteDataSource.logout();

  @override
  Future<Usuario?> buscarPorId(String id) => remoteDataSource.buscarPorId(id);

  @override
  Future<List<Usuario>> buscarPorPerfil(Perfil perfil) => remoteDataSource.buscarPorPerfil(perfil);

  @override
  Future<void> salvar(Usuario usuario) => remoteDataSource.salvar(usuario);

  @override
  Future<void> excluir(String id) => remoteDataSource.excluir(id);
}
