import '../entities/ordem_servico.dart';
import '../repositories/ordem_servico_repository.dart';

class OrdemServicoDomainServices {
  final OrdemServicoRepository _repository;

  OrdemServicoDomainServices(this._repository);

  Future<List<OrdemServico>> buscarTodos() => _repository.buscarTodos();

  Future<List<OrdemServico>> buscarMinhas() => _repository.buscarMinhas();
}
