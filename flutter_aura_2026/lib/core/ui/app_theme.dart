import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'auria_colors.dart';

/// Tema do app: Plus Jakarta Sans no texto, JetBrains Mono nos números ([AppTheme.numero]).
///
/// Opções de acessibilidade:
/// - [altoContraste]: troca a paleta pela versão de alto contraste;
/// - [fonteLegivel]: usa a Atkinson Hyperlegible, fonte criada para pessoas com baixa visão
///   (letras parecidas como I, l e 1 ficam bem diferentes);
/// - [semMovimento]: troca de tela sem animação.
class AppTheme {
  AppTheme._();

  static ThemeData claro({bool altoContraste = false, bool fonteLegivel = false, bool semMovimento = false}) => _criar(
        Brightness.light,
        altoContraste ? AuriaColors.altoContrasteClaro : AuriaColors.claro,
        altoContraste: altoContraste,
        fonteLegivel: fonteLegivel,
        semMovimento: semMovimento,
      );

  static ThemeData escuro({bool altoContraste = false, bool fonteLegivel = false, bool semMovimento = false}) => _criar(
        Brightness.dark,
        altoContraste ? AuriaColors.altoContrasteEscuro : AuriaColors.escuro,
        altoContraste: altoContraste,
        fonteLegivel: fonteLegivel,
        semMovimento: semMovimento,
      );

  static ThemeData _criar(
    Brightness brilho,
    AuriaColors c, {
    required bool altoContraste,
    required bool fonteLegivel,
    required bool semMovimento,
  }) {
    final base = ThemeData(useMaterial3: true, brightness: brilho);
    final esquema = ColorScheme.fromSeed(
      seedColor: const Color(0xFF141A4D),
      brightness: brilho,
    ).copyWith(surface: c.superficie, onSurface: c.texto, outline: c.borda, primary: c.azul);

    final textos = fonteLegivel
        ? GoogleFonts.getTextTheme('Atkinson Hyperlegible', base.textTheme)
        : GoogleFonts.plusJakartaSansTextTheme(base.textTheme);

    final larguraBorda = altoContraste ? 1.6 : 1.0;
    // Anel de foco do teclado: bem visível (WCAG 2.4.7 — foco visível).
    final corFoco = altoContraste ? c.texto : c.azul;

    return base.copyWith(
      colorScheme: esquema,
      scaffoldBackgroundColor: c.fundo,
      cardColor: c.superficie,
      dividerColor: c.borda,
      hintColor: c.textoSecundario,
      focusColor: corFoco.withValues(alpha: 0.18),
      // Áreas de toque de no mínimo 48 px em celulares.
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      textTheme: textos.apply(bodyColor: c.texto, displayColor: c.texto),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.superficie,
        hintStyle: TextStyle(color: c.textoSecundario),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.borda, width: larguraBorda)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.borda, width: larguraBorda)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: corFoco, width: 2.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.vermelho, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.vermelho, width: 2.5)),
        errorStyle: TextStyle(color: c.vermelho, fontWeight: FontWeight.w600),
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: WidgetStatePropertyAll(c.borda),
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 400),
        textStyle: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
        decoration: BoxDecoration(color: const Color(0xFF161A33), borderRadius: BorderRadius.circular(8)),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      pageTransitionsTheme: semMovimento
          ? const PageTransitionsTheme(builders: {
              TargetPlatform.android: _SemTransicao(),
              TargetPlatform.iOS: _SemTransicao(),
              TargetPlatform.linux: _SemTransicao(),
              TargetPlatform.macOS: _SemTransicao(),
              TargetPlatform.windows: _SemTransicao(),
              TargetPlatform.fuchsia: _SemTransicao(),
            })
          : base.pageTransitionsTheme,
      extensions: [c],
    );
  }

  /// Estilo para números, IDs e quantidades.
  static TextStyle numero({double tamanho = 14, FontWeight peso = FontWeight.w600, Color? cor}) =>
      GoogleFonts.jetBrainsMono(fontSize: tamanho, fontWeight: peso, color: cor);
}

/// Troca de tela instantânea (opção "Reduzir animações").
class _SemTransicao extends PageTransitionsBuilder {
  const _SemTransicao();

  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation, Widget child) =>
      child;
}
