import '../entities/indicadores.dart';

abstract class IndicadoresRepository {
  Future<Indicadores> buscarResumo();
}
