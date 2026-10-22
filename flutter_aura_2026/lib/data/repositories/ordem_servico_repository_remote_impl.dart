import '../../domain/entities/ordem_servico.dart';
import '../../domain/repositories/ordem_servico_repository.dart';
import '../datasources/remote/ordem_servico_remote_datasource.dart';

class OrdemServicoRepositoryRemoteImpl implements OrdemServicoRepository {
  final OrdemServicoRemoteDataSource remoteDataSource;

  OrdemServicoRepositoryRemoteImpl(this.remoteDataSource);

  @override
  Future<List<OrdemServico>> buscarTodos() => remoteDataSource.buscarTodos();

  @override
  Future<List<OrdemServico>> buscarMinhas() => remoteDataSource.buscarMinhas();

  @override
  Future<OrdemServico?> buscarPorId(String id) => remoteDataSource.buscarPorId(id);

  @override
  Future<void> abrir({required String chamadoId, required String tecnicoId}) =>
      remoteDataSource.abrir(chamadoId: chamadoId, tecnicoId: tecnicoId);

  @override
  Future<OrdemServico> registrarConsumo({required String ordemId, required String itemEstoqueId, required int quantidade}) =>
      remoteDataSource.registrarConsumo(ordemId: ordemId, itemEstoqueId: itemEstoqueId, quantidade: quantidade);

  @override
  Future<void> concluir({
    required String ordemId,
    required String parecerTecnico,
    required int tempoGastoMinutos,
    required double custoMaoDeObra,
  }) =>
      remoteDataSource.concluir(
        ordemId: ordemId,
        parecerTecnico: parecerTecnico,
        tempoGastoMinutos: tempoGastoMinutos,
        custoMaoDeObra: custoMaoDeObra,
      );
}
