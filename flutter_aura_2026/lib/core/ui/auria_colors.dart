import 'package:flutter/material.dart';

/// Paleta do Auria (claro e escuro). Acesse nas telas com `context.cores`.
/// Toda cor do novo design vem daqui — nada de cor fixa espalhada pelas telas.
@immutable
class AuriaColors extends ThemeExtension<AuriaColors> {
  final Color fundo;
  final Color superficie;
  final Color superficie2;
  final Color texto;
  final Color textoSecundario;
  final Color borda;
  final Color menu;
  final Color menuTexto;
  final Color menuRotulo;
  final Color destaque;
  final Color sobreDestaque;
  final Color azul, azulFundo;
  final Color laranja, laranjaFundo;
  final Color verde, verdeFundo;
  final Color cinza, cinzaFundo;
  final Color vermelho, vermelhoFundo;
  final Color ambar, ambarFundo;

  const AuriaColors({
    required this.fundo,
    required this.superficie,
    required this.superficie2,
    required this.texto,
    required this.textoSecundario,
    required this.borda,
    required this.menu,
    required this.menuTexto,
    required this.menuRotulo,
    required this.destaque,
    required this.sobreDestaque,
    required this.azul,
    required this.azulFundo,
    required this.laranja,
    required this.laranjaFundo,
    required this.verde,
    required this.verdeFundo,
    required this.cinza,
    required this.cinzaFundo,
    required this.vermelho,
    required this.vermelhoFundo,
    required this.ambar,
    required this.ambarFundo,
  });

  /// Cores fixas (iguais nos dois temas): pontos de status e barras de nível.
  static const Color pontoAberto = Color(0xFF3D5AFE);
  static const Color pontoExecucao = Color(0xFFE8833A);
  static const Color pontoConcluido = Color(0xFF2EA866);
  static const Color pontoCancelado = Color(0xFF9AA0B4);
  static const Color nivelCritico = Color(0xFFD92D20);
  static const Color nivelAtencao = Color(0xFFE8A317);
  static const Color nivelOk = Color(0xFF2EA866);

  static const claro = AuriaColors(
    fundo: Color(0xFFF4F5FA),
    superficie: Color(0xFFFFFFFF),
    superficie2: Color(0xFFF8F9FC),
    texto: Color(0xFF161A33),
    textoSecundario: Color(0xFF5B6178),
    borda: Color(0xFFE3E6EF),
    menu: Color(0xFF141A4D),
    menuTexto: Color(0xFFC9CCF0),
    menuRotulo: Color(0xFF8E93C4),
    destaque: Color(0xFFF2A516),
    sobreDestaque: Color(0xFF1B1400),
    azul: Color(0xFF2D47D9),
    azulFundo: Color(0xFFE8ECFE),
    laranja: Color(0xFFB45309),
    laranjaFundo: Color(0xFFFFF1E3),
    verde: Color(0xFF1F7A45),
    verdeFundo: Color(0xFFE4F5EA),
    cinza: Color(0xFF5F6475),
    cinzaFundo: Color(0xFFEEF0F4),
    vermelho: Color(0xFFB42318),
    vermelhoFundo: Color(0xFFFDECEB),
    ambar: Color(0xFF8A5A00),
    ambarFundo: Color(0xFFFFF4D6),
  );

  static const escuro = AuriaColors(
    fundo: Color(0xFF0E1130),
    superficie: Color(0xFF171B45),
    superficie2: Color(0xFF1C2152),
    texto: Color(0xFFEEF0FF),
    textoSecundario: Color(0xFFA9AED6),
    borda: Color(0xFF2C3170),
    menu: Color(0xFF090C25),
    menuTexto: Color(0xFFC9CCF0),
    menuRotulo: Color(0xFF8E93C4),
    destaque: Color(0xFFF2A516),
    sobreDestaque: Color(0xFF1B1400),
    azul: Color(0xFF9DB0FF),
    azulFundo: Color(0xFF232B6B),
    laranja: Color(0xFFFFB070),
    laranjaFundo: Color(0xFF3A2A1E),
    verde: Color(0xFF7FDBA4),
    verdeFundo: Color(0xFF173A2C),
    cinza: Color(0xFFB7BBD0),
    cinzaFundo: Color(0xFF262B5A),
    vermelho: Color(0xFFFF9C94),
    vermelhoFundo: Color(0xFF43202A),
    ambar: Color(0xFFFFD27A),
    ambarFundo: Color(0xFF3B321C),
  );

  /// Alto contraste (claro): texto preto, bordas escuras e cores de status mais fortes.
  /// Usado quando a pessoa liga "Alto contraste" no app ou no sistema operacional.
  static const altoContrasteClaro = AuriaColors(
    fundo: Color(0xFFFFFFFF),
    superficie: Color(0xFFFFFFFF),
    superficie2: Color(0xFFF2F3F7),
    texto: Color(0xFF000000),
    textoSecundario: Color(0xFF2E3247),
    borda: Color(0xFF4B5068),
    menu: Color(0xFF0A0E33),
    menuTexto: Color(0xFFFFFFFF),
    menuRotulo: Color(0xFFD6D9FF),
    destaque: Color(0xFFF2A516),
    sobreDestaque: Color(0xFF000000),
    azul: Color(0xFF1A2FB0),
    azulFundo: Color(0xFFE8ECFE),
    laranja: Color(0xFF7A3500),
    laranjaFundo: Color(0xFFFFF1E3),
    verde: Color(0xFF0E5A2F),
    verdeFundo: Color(0xFFE4F5EA),
    cinza: Color(0xFF33374A),
    cinzaFundo: Color(0xFFE6E8EE),
    vermelho: Color(0xFF8E1A10),
    vermelhoFundo: Color(0xFFFDECEB),
    ambar: Color(0xFF5E3D00),
    ambarFundo: Color(0xFFFFF4D6),
  );

  /// Alto contraste (escuro): fundo preto, texto branco e cores claras e saturadas.
  static const altoContrasteEscuro = AuriaColors(
    fundo: Color(0xFF000000),
    superficie: Color(0xFF0B0D1F),
    superficie2: Color(0xFF14173A),
    texto: Color(0xFFFFFFFF),
    textoSecundario: Color(0xFFE1E4FF),
    borda: Color(0xFF9AA0D6),
    menu: Color(0xFF000000),
    menuTexto: Color(0xFFFFFFFF),
    menuRotulo: Color(0xFFD6D9FF),
    destaque: Color(0xFFFFC53D),
    sobreDestaque: Color(0xFF000000),
    azul: Color(0xFFC9D3FF),
    azulFundo: Color(0xFF1A2366),
    laranja: Color(0xFFFFCB9A),
    laranjaFundo: Color(0xFF3A2412),
    verde: Color(0xFFA8F0C4),
    verdeFundo: Color(0xFF0F3322),
    cinza: Color(0xFFE0E3F0),
    cinzaFundo: Color(0xFF262B5A),
    vermelho: Color(0xFFFFC2BC),
    vermelhoFundo: Color(0xFF4A1018),
    ambar: Color(0xFFFFE2A3),
    ambarFundo: Color(0xFF3B2F10),
  );

  @override
  AuriaColors copyWith({Color? destaque}) => AuriaColors(
        fundo: fundo,
        superficie: superficie,
        superficie2: superficie2,
        texto: texto,
        textoSecundario: textoSecundario,
        borda: borda,
        menu: menu,
        menuTexto: menuTexto,
        menuRotulo: menuRotulo,
        destaque: destaque ?? this.destaque,
        sobreDestaque: sobreDestaque,
        azul: azul,
        azulFundo: azulFundo,
        laranja: laranja,
        laranjaFundo: laranjaFundo,
        verde: verde,
        verdeFundo: verdeFundo,
        cinza: cinza,
        cinzaFundo: cinzaFundo,
        vermelho: vermelho,
        vermelhoFundo: vermelhoFundo,
        ambar: ambar,
        ambarFundo: ambarFundo,
      );

  @override
  AuriaColors lerp(ThemeExtension<AuriaColors>? other, double t) {
    if (other is! AuriaColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AuriaColors(
      fundo: l(fundo, other.fundo),
      superficie: l(superficie, other.superficie),
      superficie2: l(superficie2, other.superficie2),
      texto: l(texto, other.texto),
      textoSecundario: l(textoSecundario, other.textoSecundario),
      borda: l(borda, other.borda),
      menu: l(menu, other.menu),
      menuTexto: l(menuTexto, other.menuTexto),
      menuRotulo: l(menuRotulo, other.menuRotulo),
      destaque: l(destaque, other.destaque),
      sobreDestaque: l(sobreDestaque, other.sobreDestaque),
      azul: l(azul, other.azul),
      azulFundo: l(azulFundo, other.azulFundo),
      laranja: l(laranja, other.laranja),
      laranjaFundo: l(laranjaFundo, other.laranjaFundo),
      verde: l(verde, other.verde),
      verdeFundo: l(verdeFundo, other.verdeFundo),
      cinza: l(cinza, other.cinza),
      cinzaFundo: l(cinzaFundo, other.cinzaFundo),
      vermelho: l(vermelho, other.vermelho),
      vermelhoFundo: l(vermelhoFundo, other.vermelhoFundo),
      ambar: l(ambar, other.ambar),
      ambarFundo: l(ambarFundo, other.ambarFundo),
    );
  }
}

extension AuriaColorsContext on BuildContext {
  AuriaColors get cores => Theme.of(this).extension<AuriaColors>() ?? AuriaColors.claro;
}
