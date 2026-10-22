import 'package:get_it/get_it.dart';

import 'core/network/api_client.dart';
import 'core/theme/theme_controller.dart';

import 'data/datasources/remote/ambiente_remote_datasource.dart';
import 'data/datasources/remote/ativo_remote_datasource.dart';
import 'data/datasources/remote/chamado_remote_datasource.dart';
import 'data/datasources/remote/estoque_remote_datasource.dart';
import 'data/datasources/remote/indicadores_remote_datasource.dart';
import 'data/datasources/remote/notificacao_remote_datasource.dart';
import 'data/datasources/remote/ordem_servico_remote_datasource.dart';
import 'data/datasources/remote/planejamento_remote_datasource.dart';
import 'data/datasources/remote/usuario_remote_datasource.dart';

import 'data/repositories/ambiente_repository_remote_impl.dart';
import 'data/repositories/ativo_repository_remote_impl.dart';
import 'data/repositories/chamado_repository_remote_impl.dart';
import 'data/repositories/estoque_repository_remote_impl.dart';
import 'data/repositories/indicadores_repository_remote_impl.dart';
import 'data/repositories/notificacao_repository_remote_impl.dart';
import 'data/repositories/ordem_servico_repository_remote_impl.dart';
import 'data/repositories/planejamento_repository_remote_impl.dart';
import 'data/repositories/usuario_repository_remote_impl.dart';

import 'domain/repositories/ambiente_repository.dart';
import 'domain/repositories/ativo_repository.dart';
import 'domain/repositories/chamado_repository.dart';
import 'domain/repositories/estoque_repository.dart';
import 'domain/repositories/indicadores_repository.dart';
import 'domain/repositories/notificacao_repository.dart';
import 'domain/repositories/ordem_servico_repository.dart';
import 'domain/repositories/planejamento_repository.dart';
import 'domain/repositories/usuario_repository.dart';
import 'domain/services/chamado_domain_services.dart';
import 'domain/services/estoque_domain_services.dart';
import 'domain/services/ordem_servico_domain_services.dart';

/// Registra as dependências do app. Todos os repositórios falam com a AuriaAPI via HTTP
/// (os dados ficam no servidor/MySQL — o app não guarda mais nada localmente, só o token).
class ServiceLocator {
  ServiceLocator._internal();
  static final ServiceLocator _instance = ServiceLocator._internal();
  static ServiceLocator get instance => _instance;

  void setupRepository() {
    final sl = GetIt.instance;

    if (sl.isRegistered<ThemeController>()) {
      return;
    }

    sl.registerSingleton<ThemeController>(ThemeController());

    sl.registerLazySingleton<ApiClient>(() => ApiClient());

    // --- Datasources (HTTP) ---
    sl.registerLazySingleton(() => AmbienteRemoteDataSource(sl<ApiClient>()));
    sl.registerLazySingleton(() => AtivoRemoteDataSource(sl<ApiClient>()));
    sl.registerLazySingleton(() => ChamadoRemoteDataSource(sl<ApiClient>()));
    sl.registerLazySingleton(() => EstoqueRemoteDataSource(sl<ApiClient>()));
    sl.registerLazySingleton(() => NotificacaoRemoteDataSource(sl<ApiClient>()));
    sl.registerLazySingleton(() => UsuarioRemoteDataSource(sl<ApiClient>()));
    sl.registerLazySingleton(() => OrdemServicoRemoteDataSource(sl<ApiClient>()));
    sl.registerLazySingleton(() => IndicadoresRemoteDataSource(sl<ApiClient>()));
    sl.registerLazySingleton(() => PlanejamentoRemoteDataSource(sl<ApiClient>()));

    // --- Repositórios ---
    sl.registerLazySingleton<AmbienteRepository>(() => AmbienteRepositoryRemoteImpl(sl<AmbienteRemoteDataSource>()));
    sl.registerLazySingleton<AtivoRepository>(() => AtivoRepositoryRemoteImpl(sl<AtivoRemoteDataSource>()));
    sl.registerLazySingleton<ChamadoRepository>(() => ChamadoRepositoryRemoteImpl(sl<ChamadoRemoteDataSource>()));
    sl.registerLazySingleton<EstoqueRepository>(() => EstoqueRepositoryRemoteImpl(sl<EstoqueRemoteDataSource>()));
    sl.registerLazySingleton<NotificacaoRepository>(() => NotificacaoRepositoryRemoteImpl(sl<NotificacaoRemoteDataSource>()));
    sl.registerLazySingleton<UsuarioRepository>(() => UsuarioRepositoryRemoteImpl(sl<UsuarioRemoteDataSource>()));
    sl.registerLazySingleton<OrdemServicoRepository>(() => OrdemServicoRepositoryRemoteImpl(sl<OrdemServicoRemoteDataSource>()));
    sl.registerLazySingleton<IndicadoresRepository>(() => IndicadoresRepositoryRemoteImpl(sl<IndicadoresRemoteDataSource>()));
    sl.registerLazySingleton<PlanejamentoRepository>(() => PlanejamentoRepositoryRemoteImpl(sl<PlanejamentoRemoteDataSource>()));

    // --- Domain Services ---
    sl.registerLazySingleton(() => OrdemServicoDomainServices(sl<OrdemServicoRepository>()));
    sl.registerLazySingleton(() => ChamadoDomainServices(sl<OrdemServicoRepository>(), sl<ChamadoRepository>()));
    sl.registerLazySingleton(() => EstoqueDomainServices(sl<EstoqueRepository>()));
  }
}
