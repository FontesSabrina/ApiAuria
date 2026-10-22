import '../entities/chamado.dart';
import '../entities/usuario.dart';
import '../entities/ordem_servico.dart';
import '../repositories/ordem_servico_repository.dart';
import '../repositories/chamado_repository.dart';

/// Casos de uso do fluxo de chamado no app. As regras de negócio (status permitido,
/// permissões, baixa de estoque) e as notificações ao solicitante ficam na API;
/// aqui só há validações de interface para dar um retorno rápido ao usuário.
class ChamadoDomainServices {
  final OrdemServicoRepository _osRepository;
  final ChamadoRepository _chamadoRepository;

  ChamadoDomainServices(this._osRepository, this._chamadoRepository);

  Future<List<Chamado>> buscarTodos() => _chamadoRepository.buscarTodos();

  Future<void> registrarChamado(Chamado chamado) => _chamadoRepository.salvar(chamado);

  Future<void> cancelarChamado(Chamado chamado) => _chamadoRepository.cancelar(chamado.id);

  Future<void> aprovarChamadoEGerarOS({
    required Chamado chamado,
    required Usuario tecnico,
    required Usuario usuarioLogado,
  }) async {
    if (usuarioLogado.perfil != Perfil.administrador) {
      throw Exception("Acesso Negado: Apenas administradores podem designar técnicos.");
    }

    await _osRepository.abrir(chamadoId: chamado.id, tecnicoId: tecnico.id);
  }

  Future<void> finalizarOS({
    required OrdemServico ordem,
    required String relato,
    required double custoMaoDeObra,
    required DateTime dataInicio,
    required DateTime dataFim,
  }) async {
    if (dataFim.isBefore(dataInicio)) {
      throw Exception("A data final não pode ser anterior à inicial.");
    }

    await _osRepository.concluir(
      ordemId: ordem.id,
      parecerTecnico: relato,
      tempoGastoMinutos: dataFim.difference(dataInicio).inMinutes,
      custoMaoDeObra: custoMaoDeObra,
    );
  }
}
