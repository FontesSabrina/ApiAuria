import '../entities/alerta_preventiva.dart';
import '../entities/ordem_servico.dart';

abstract class PlanejamentoRepository {
  Future<List<OrdemServico>> buscarCronograma(DateTime data);
  Future<List<AlertaPreventiva>> buscarAlertas();
}
