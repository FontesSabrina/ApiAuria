import 'package:flutter/material.dart';

/// Logo do Auria — conceito "Janela acesa": um prédio com uma janela acesa em âmbar.
///
/// As janelas são recortadas (transparentes), então o símbolo funciona sobre qualquer fundo.
/// Desenhado em código (CustomPainter), sem depender de arquivos de imagem.

const Color _ambar = Color(0xFFF2A516);
const Color _azulMarca = Color(0xFF141A4D);

/// Só o símbolo (prédio). [corPredio] muda conforme o fundo: azul-marinho no claro, branco no escuro.
class AuriaSimbolo extends StatelessWidget {
  final double tamanho;
  final Color corPredio;
  final Color corJanelaAcesa;

  const AuriaSimbolo({
    super.key,
    this.tamanho = 40,
    this.corPredio = _azulMarca,
    this.corJanelaAcesa = _ambar,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Logo Auria',
      image: true,
      child: SizedBox(
        width: tamanho,
        height: tamanho,
        child: CustomPaint(painter: _SimboloPainter(corPredio, corJanelaAcesa)),
      ),
    );
  }
}

/// Ícone do app: quadrado arredondado azul-marinho com o prédio branco dentro.
class AuriaIcone extends StatelessWidget {
  final double tamanho;
  const AuriaIcone({super.key, this.tamanho = 40});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Logo Auria',
      image: true,
      child: SizedBox(
        width: tamanho,
        height: tamanho,
        child: const CustomPaint(painter: _IconePainter()),
      ),
    );
  }
}

/// Símbolo + nome "AURIA" (+ subtítulo opcional), lado a lado.
class AuriaMarca extends StatelessWidget {
  final double tamanhoSimbolo;
  final double tamanhoTexto;
  final Color corPredio;
  final Color corTexto;
  final String? subtitulo;
  final Color? corSubtitulo;

  const AuriaMarca({
    super.key,
    this.tamanhoSimbolo = 40,
    this.tamanhoTexto = 22,
    this.corPredio = _azulMarca,
    this.corTexto = _azulMarca,
    this.subtitulo,
    this.corSubtitulo,
  });

  @override
  Widget build(BuildContext context) {
    final nome = Text(
      'AURIA',
      style: TextStyle(fontSize: tamanhoTexto, fontWeight: FontWeight.w800, letterSpacing: tamanhoTexto * 0.12, color: corTexto, height: 1.1),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AuriaSimbolo(tamanho: tamanhoSimbolo, corPredio: corPredio),
        SizedBox(width: tamanhoSimbolo * 0.3),
        if (subtitulo == null)
          nome
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              nome,
              const SizedBox(height: 2),
              Text(
                subtitulo!,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.4, color: corSubtitulo ?? corTexto.withValues(alpha: 0.7)),
              ),
            ],
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Desenho (coordenadas numa grade de 120 x 120, escaladas para o tamanho pedido)
// ---------------------------------------------------------------------------

void _desenharPredio(
  Canvas canvas, {
  required Path contorno,
  required double espessuraContorno,
  required Color corPredio,
  required List<RRect> janelas,
  required RRect janelaAcesa,
  required Color corAcesa,
  required Rect area,
}) {
  // Camada separada para que o BlendMode.clear recorte só o prédio, sem apagar o que está atrás.
  canvas.saveLayer(area, Paint());
  canvas.drawPath(contorno, Paint()..color = corPredio);
  canvas.drawPath(
    contorno,
    Paint()
      ..color = corPredio
      ..style = PaintingStyle.stroke
      ..strokeWidth = espessuraContorno
      ..strokeJoin = StrokeJoin.round,
  );
  final recorte = Paint()..blendMode = BlendMode.clear;
  for (final j in [...janelas, janelaAcesa]) {
    canvas.drawRRect(j, recorte);
  }
  canvas.drawRRect(janelaAcesa, Paint()..color = corAcesa);
  canvas.restore();
}

RRect _rr(double x, double y, double w, double h, double r) => RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r));

class _SimboloPainter extends CustomPainter {
  final Color corPredio;
  final Color corAcesa;
  _SimboloPainter(this.corPredio, this.corAcesa);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 120;
    canvas.save();
    canvas.scale(s);
    final contorno = Path()
      ..moveTo(22, 34)
      ..lineTo(60, 12)
      ..lineTo(98, 34)
      ..lineTo(98, 106)
      ..lineTo(22, 106)
      ..close();
    _desenharPredio(
      canvas,
      contorno: contorno,
      espessuraContorno: 6,
      corPredio: corPredio,
      janelas: [
        _rr(31, 42, 16, 16, 3),
        _rr(52, 42, 16, 16, 3),
        _rr(31, 64, 16, 16, 3),
        _rr(52, 64, 16, 16, 3),
        _rr(73, 64, 16, 16, 3),
        _rr(52, 86, 16, 20, 3), // porta
      ],
      janelaAcesa: _rr(73, 42, 16, 16, 3),
      corAcesa: corAcesa,
      area: const Rect.fromLTWH(0, 0, 120, 120),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SimboloPainter old) => old.corPredio != corPredio || old.corAcesa != corAcesa;
}

class _IconePainter extends CustomPainter {
  const _IconePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 120;
    canvas.save();
    canvas.scale(s);
    canvas.drawRRect(_rr(0, 0, 120, 120, 28), Paint()..color = _azulMarca);
    final contorno = Path()
      ..moveTo(32, 44)
      ..lineTo(60, 26)
      ..lineTo(88, 44)
      ..lineTo(88, 96)
      ..lineTo(32, 96)
      ..close();
    // No ícone o recorte mostraria o fundo azul do próprio quadrado, então pintamos as janelas de azul.
    canvas.drawPath(contorno, Paint()..color = Colors.white);
    canvas.drawPath(
      contorno,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeJoin = StrokeJoin.round,
    );
    final azul = Paint()..color = _azulMarca;
    for (final j in [
      _rr(40, 50, 12, 12, 2.5),
      _rr(54, 50, 12, 12, 2.5),
      _rr(40, 66, 12, 12, 2.5),
      _rr(54, 66, 12, 12, 2.5),
      _rr(68, 66, 12, 12, 2.5),
      _rr(54, 82, 12, 14, 2.5),
    ]) {
      canvas.drawRRect(j, azul);
    }
    canvas.drawRRect(_rr(68, 50, 12, 12, 2.5), Paint()..color = _ambar);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IconePainter old) => false;
}
