import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';

import 'service_locator.dart';
import 'routes.dart';
import 'core/acessibilidade/acessibilidade_controller.dart';
import 'core/theme/theme_controller.dart';
import 'core/network/auth_session.dart';
import 'core/ui/app_theme.dart';

/// Chaves globais: permitem voltar ao login e mostrar um aviso a partir de fora
/// de uma tela (ex.: quando a API responde 401 porque o token expirou).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthSession.instance.load();
  await AcessibilidadeController.instance.carregar();

  // Na web, o Flutter só cria a árvore de acessibilidade depois que o usuário clica num botão
  // escondido. Ligamos desde o início para leitores de tela (NVDA, VoiceOver...) funcionarem direto.
  if (kIsWeb) SemanticsBinding.instance.ensureSemantics();

  // Todos os dados vêm da AuriaAPI — o app não usa mais banco local.
  ServiceLocator.instance.setupRepository();

  AuthSession.instance.onSessaoExpirada = (mensagem) {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: const Color(0xFFB42318)),
    );
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = GetIt.I<ThemeController>();
    final a11y = AcessibilidadeController.instance;

    return ListenableBuilder(
      listenable: Listenable.merge([themeController, a11y]),
      builder: (context, _) {
        return MaterialApp(
          title: 'Auria',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          scaffoldMessengerKey: scaffoldMessengerKey,
          themeMode: themeController.themeMode,
          theme: AppTheme.claro(altoContraste: a11y.altoContraste, fonteLegivel: a11y.fonteLegivel, semMovimento: a11y.reduzirMovimento),
          darkTheme: AppTheme.escuro(altoContraste: a11y.altoContraste, fonteLegivel: a11y.fonteLegivel, semMovimento: a11y.reduzirMovimento),
          // Usados automaticamente quando o alto contraste está ligado no sistema operacional.
          highContrastTheme: AppTheme.claro(altoContraste: true, fonteLegivel: a11y.fonteLegivel, semMovimento: a11y.reduzirMovimento),
          highContrastDarkTheme: AppTheme.escuro(altoContraste: true, fonteLegivel: a11y.fonteLegivel, semMovimento: a11y.reduzirMovimento),
          themeAnimationDuration: a11y.reduzirMovimento ? Duration.zero : kThemeAnimationDuration,
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            // Tamanho do texto = escolha do sistema × escolha no app (com limite para não quebrar o layout).
            final doSistema = mq.textScaler.scale(100) / 100;
            final fator = math.min(AcessibilidadeController.escalaMaxima, doSistema * a11y.escalaTexto);
            return MediaQuery(
              data: mq.copyWith(
                textScaler: TextScaler.linear(fator),
                disableAnimations: mq.disableAnimations || a11y.reduzirMovimento,
              ),
              child: child!,
            );
          },
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('pt', 'BR')],
          locale: const Locale('pt', 'BR'),
          initialRoute: AppRoutes.login,
          routes: AppRoutes.getRoutes(),
        );
      },
    );
  }
}
