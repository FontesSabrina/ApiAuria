import 'package:flutter/material.dart';

import 'domain/entities/usuario.dart';
import 'pages/login_page.dart';
import 'pages/shell/auria_shell.dart';

/// Rotas nomeadas do app. Depois do login, todas as telas vivem dentro do [AuriaShell].
class AppRoutes {
  static const String login = '/login';
  static const String home = '/';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const LoginPage(),
      home: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        return args is Usuario ? AuriaShell(usuario: args) : const LoginPage();
      },
    };
  }
}
