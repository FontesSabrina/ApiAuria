import '../entities/ambiente.dart';

abstract class AmbienteRepository {
  Future<List<Ambiente>> buscarTodos();
  Future<void> salvar(Ambiente ambiente);
  Future<void> excluir(String id);
}