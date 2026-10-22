import 'package:flutter/material.dart';

import '../../domain/entities/chamado.dart';
import '../acessibilidade/acessibilidade_controller.dart';
import 'app_theme.dart';
import 'auria_colors.dart';

/// Componentes visuais compartilhados do novo design do Auria.

/// Card de seção: título em negrito, dica em cinza e o conteúdo.
class AuriaCard extends StatelessWidget {
  final String? titulo;
  final String? dica;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Widget? acao;

  const AuriaCard({super.key, this.titulo, this.dica, required this.child, this.padding = const EdgeInsets.all(22), this.acao});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: c.superficie,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (titulo != null)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(header: true, child: Text(titulo!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
                      if (dica != null) ...[
                        const SizedBox(height: 2),
                        Text(dica!, style: TextStyle(fontSize: 13, color: c.textoSecundario)),
                      ],
                    ],
                  ),
                ),
                if (acao != null) acao!,
              ],
            ),
          if (titulo != null) const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// Superfície clicável que "sobe" 2 px e ganha sombra suave ao passar o mouse.
///
/// Acessibilidade: recebe foco pelo teclado (Tab) e mostra um anel de foco bem visível;
/// [semantica] é o resumo lido pelo leitor de tela. Com [resumir] = true, só o resumo é lido
/// (use quando o conteúdo não tem botões próprios). O movimento some com "Reduzir animações".
class HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double raio;
  final Color? cor;
  final String? semantica;
  final bool resumir;

  const HoverCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(14),
    this.raio = 14,
    this.cor,
    this.semantica,
    this.resumir = false,
  });

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _hover = false;
  bool _foco = false;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final clicavel = widget.onTap != null;
    final parado = semAnimacao(context);
    final elevado = clicavel && (_hover || _foco);

    return Semantics(
      button: clicavel,
      label: widget.semantica,
      excludeSemantics: widget.resumir && widget.semantica != null,
      // Com excludeSemantics o toque do InkWell some da árvore; repassamos a ação para o leitor de tela.
      onTap: widget.resumir && widget.semantica != null ? widget.onTap : null,
      child: MouseRegion(
        cursor: clicavel ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: AnimatedContainer(
          duration: parado ? Duration.zero : const Duration(milliseconds: 150),
          transform: Matrix4.translationValues(0, elevado && !parado ? -2 : 0, 0),
          decoration: BoxDecoration(
            color: widget.cor ?? c.superficie,
            borderRadius: BorderRadius.circular(widget.raio),
            border: Border.all(
              color: _foco ? c.azul : (elevado ? c.textoSecundario.withValues(alpha: 0.6) : c.borda),
              width: _foco ? 2.5 : 1,
            ),
            boxShadow: elevado
                ? [BoxShadow(color: const Color(0xFF141A4D).withValues(alpha: 0.10), blurRadius: 20, offset: const Offset(0, 8))]
                : const [],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(widget.raio),
            child: InkWell(
              borderRadius: BorderRadius.circular(widget.raio),
              onTap: widget.onTap,
              onFocusChange: (f) => setState(() => _foco = f),
              child: Padding(padding: widget.padding, child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}

/// Indicador numérico clicável do painel.
class KpiCard extends StatelessWidget {
  final IconData icone;
  final Color corIcone;
  final Color fundoIcone;
  final String valor;
  final String rotulo;
  final VoidCallback? onTap;

  const KpiCard({super.key, required this.icone, required this.corIcone, required this.fundoIcone, required this.valor, required this.rotulo, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return HoverCard(
      onTap: onTap,
      raio: 18,
      padding: const EdgeInsets.all(20),
      semantica: onTap != null ? '$rotulo: $valor. Abrir' : '$rotulo: $valor',
      resumir: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: fundoIcone, borderRadius: BorderRadius.circular(12)),
                child: Icon(icone, color: corIcone, size: 21),
              ),
              const Spacer(),
              if (onTap != null)
                Row(children: [
                  Text('Abrir', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.textoSecundario)),
                  Icon(Icons.chevron_right_rounded, size: 16, color: c.textoSecundario),
                ]),
            ],
          ),
          const SizedBox(height: 14),
          Text(valor, style: AppTheme.numero(tamanho: 32, cor: c.texto)),
          const SizedBox(height: 4),
          Text(rotulo, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textoSecundario)),
        ],
      ),
    );
  }
}

/// Etiqueta arredondada com ponto colorido (status, prioridade, tipo).
class Pilula extends StatelessWidget {
  final String texto;
  final Color cor;
  final Color fundo;
  final bool comPonto;

  const Pilula({super.key, required this.texto, required this.cor, required this.fundo, this.comPonto = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (comPonto) ...[
            Container(width: 6, height: 6, decoration: BoxDecoration(color: cor, shape: BoxShape.circle)),
            const SizedBox(width: 6),
          ],
          Text(texto, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: cor)),
        ],
      ),
    );
  }
}

/// Cores e rótulo de cada status de chamado.
class EstiloStatus {
  final String rotulo;
  final Color cor;
  final Color fundo;
  final Color ponto;

  const EstiloStatus(this.rotulo, this.cor, this.fundo, this.ponto);

  static EstiloStatus de(BuildContext context, StatusChamado status) {
    final c = context.cores;
    switch (status) {
      case StatusChamado.aberto:
        return EstiloStatus('Aguardando aprovação', c.azul, c.azulFundo, AuriaColors.pontoAberto);
      case StatusChamado.emExecucao:
        return EstiloStatus('Em execução', c.laranja, c.laranjaFundo, AuriaColors.pontoExecucao);
      case StatusChamado.concluido:
        return EstiloStatus('Concluídos', c.verde, c.verdeFundo, AuriaColors.pontoConcluido);
      case StatusChamado.cancelado:
        return EstiloStatus('Cancelados', c.cinza, c.cinzaFundo, AuriaColors.pontoCancelado);
    }
  }
}

class PilulaStatus extends StatelessWidget {
  final StatusChamado status;
  const PilulaStatus({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final e = EstiloStatus.de(context, status);
    return Pilula(texto: e.rotulo, cor: e.cor, fundo: e.fundo);
  }
}

class PilulaPrioridade extends StatelessWidget {
  final String prioridade;
  final String prefixo;
  const PilulaPrioridade({super.key, required this.prioridade, this.prefixo = ''});

  /// Alta → 0, Média → 1, Baixa → 2 (para ordenar).
  static int peso(String prioridade) {
    final p = prioridade.toLowerCase();
    if (p == 'alta') return 0;
    if (p.startsWith('m')) return 1;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final cores = switch (peso(prioridade)) {
      0 => (c.vermelho, c.vermelhoFundo),
      1 => (c.ambar, c.ambarFundo),
      _ => (c.cinza, c.cinzaFundo),
    };
    return Pilula(texto: '$prefixo$prioridade', cor: cores.$1, fundo: cores.$2);
  }
}

/// Círculo com as iniciais de uma pessoa.
class AvatarIniciais extends StatelessWidget {
  final String nome;
  final double tamanho;
  final Color? cor;
  final Color? fundo;

  const AvatarIniciais({super.key, required this.nome, this.tamanho = 24, this.cor, this.fundo});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    // Decorativo: o nome da pessoa já aparece em texto ao lado.
    return ExcludeSemantics(
        child: Container(
      width: tamanho,
      height: tamanho,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: fundo ?? c.azulFundo, shape: BoxShape.circle),
      child: Text(
        iniciais(nome),
        style: TextStyle(fontSize: tamanho * 0.38, fontWeight: FontWeight.w800, color: cor ?? c.azul),
      ),
    ));
  }
}

class EstadoVazio extends StatelessWidget {
  final String mensagem;
  final IconData icone;
  const EstadoVazio({super.key, required this.mensagem, this.icone = Icons.check_circle_outline_rounded});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      child: Column(
        children: [
          Icon(icone, size: 32, color: c.textoSecundario),
          const SizedBox(height: 8),
          Text(mensagem, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: c.textoSecundario)),
        ],
      ),
    );
  }
}

/// Aviso no rodapé (fundo escuro + check verde, ou vermelho em caso de erro).
/// O leitor de tela anuncia a mensagem (e diz "Erro" quando for o caso).
void mostrarToast(BuildContext context, String mensagem, {bool erro = false}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(snackAuria(mensagem, erro: erro));
}

SnackBar snackAuria(String mensagem, {bool erro = false}) => SnackBar(
      behavior: SnackBarBehavior.floating,
      width: 460,
      duration: Duration(seconds: erro ? 8 : 4),
      backgroundColor: erro ? const Color(0xFFB42318) : const Color(0xFF161A33),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      content: Semantics(
        liveRegion: true,
        label: erro ? 'Erro: $mensagem' : mensagem,
        excludeSemantics: true,
        child: Row(
          children: [
            Icon(erro ? Icons.error_outline_rounded : Icons.check_rounded, color: erro ? Colors.white : const Color(0xFF7FDBA4)),
            const SizedBox(width: 10),
            Expanded(child: Text(mensagem, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white))),
          ],
        ),
      ),
    );

String iniciais(String nome) {
  final partes = nome.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (partes.isEmpty) return '?';
  if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
  return (partes.first.substring(0, 1) + partes[1].substring(0, 1)).toUpperCase();
}

/// "agora", "há 25 min", "há 2 h", "ontem", "há 3 dias".
String tempoDecorrido(DateTime data) {
  final d = DateTime.now().difference(data);
  if (d.inMinutes < 1) return 'agora';
  if (d.inMinutes < 60) return 'há ${d.inMinutes} min';
  if (d.inHours < 24) return 'há ${d.inHours} h';
  if (d.inDays == 1) return 'ontem';
  if (d.inDays < 7) return 'há ${d.inDays} dias';
  if (d.inDays < 14) return 'há 1 semana';
  return 'há ${d.inDays ~/ 7} semanas';
}

/// Barra horizontal segmentada com a quantidade de chamados por status + legenda.
class BarraStatus extends StatelessWidget {
  final Map<StatusChamado, int> quantidades;
  const BarraStatus({super.key, required this.quantidades});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final segmentos = [for (final s in StatusChamado.values) (EstiloStatus.de(context, s), quantidades[s] ?? 0)];
    final comValor = segmentos.where((s) => s.$2 > 0).toList();
    final resumo = 'Chamados por status: ${segmentos.map((s) => '${s.$1.rotulo}, ${s.$2}').join('; ')}';

    return Semantics(
      label: resumo,
      excludeSemantics: true,
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 14,
            child: comValor.isEmpty
                ? Container(color: c.cinzaFundo)
                : Row(
                    children: [
                      for (var i = 0; i < comValor.length; i++) ...[
                        if (i > 0) const SizedBox(width: 3),
                        Expanded(flex: comValor[i].$2, child: Container(color: comValor[i].$1.ponto)),
                      ],
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 18,
          runSpacing: 8,
          children: [
            for (final s in segmentos)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: s.$1.ponto, borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 6),
                  Text(s.$1.rotulo, style: TextStyle(fontSize: 13, color: c.textoSecundario)),
                  const SizedBox(width: 6),
                  Text('${s.$2}', style: AppTheme.numero(tamanho: 13, cor: c.texto)),
                ],
              ),
          ],
        ),
      ],
    ));
  }
}

/// Barras horizontais simples (ranking).
class RankingBarras extends StatelessWidget {
  final List<(String, int)> itens;
  final String mensagemVazia;
  const RankingBarras({super.key, required this.itens, this.mensagemVazia = 'Ainda não há dados.'});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    if (itens.isEmpty) return EstadoVazio(mensagem: mensagemVazia, icone: Icons.bar_chart_rounded);
    final maximo = itens.map((i) => i.$2).fold<int>(1, (a, b) => b > a ? b : a);
    return Column(
      children: [
        for (final r in itens)
          Semantics(
            label: '${r.$1}: ${r.$2}',
            excludeSemantics: true,
            child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: r.$2 / maximo,
                          minHeight: 10,
                          backgroundColor: c.cinzaFundo,
                          valueColor: AlwaysStoppedAnimation(c.destaque),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 40, child: Text('${r.$2}', textAlign: TextAlign.right, style: AppTheme.numero(tamanho: 13, cor: c.texto))),
              ],
            ),
          )),
      ],
    );
  }
}

/// Linha de lista com ícone colorido, título, detalhe e área de ações à direita.
class LinhaLista extends StatelessWidget {
  final IconData icone;
  final Color corIcone;
  final Color fundoIcone;
  final String titulo;
  final String detalhe;
  final List<Widget> acoes;
  final VoidCallback? onTap;

  const LinhaLista({
    super.key,
    required this.icone,
    required this.corIcone,
    required this.fundoIcone,
    required this.titulo,
    required this.detalhe,
    this.acoes = const [],
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: HoverCard(
        onTap: onTap,
        cor: c.superficie2,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: fundoIcone, borderRadius: BorderRadius.circular(11)),
              child: Icon(icone, size: 18, color: corIcone),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(detalhe, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: c.textoSecundario)),
                ],
              ),
            ),
            for (final a in acoes) ...[const SizedBox(width: 10), a],
          ],
        ),
      ),
    );
  }
}

/// Botão quadrado só com ícone (44×44), com tooltip, rótulo acessível e anel de foco do teclado.
class BotaoIcone extends StatefulWidget {
  final IconData icone;
  final String rotulo;
  final VoidCallback onPressed;
  const BotaoIcone({super.key, required this.icone, required this.rotulo, required this.onPressed});

  @override
  State<BotaoIcone> createState() => _BotaoIconeState();
}

class _BotaoIconeState extends State<BotaoIcone> {
  bool _foco = false;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Tooltip(
      message: widget.rotulo,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        label: widget.rotulo,
        excludeSemantics: true,
        onTap: widget.onPressed,
        child: Material(
          color: c.superficie,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: _foco ? c.azul : c.borda, width: _foco ? 2.5 : 1),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.onPressed,
            onFocusChange: (f) => setState(() => _foco = f),
            child: SizedBox(width: 44, height: 44, child: Icon(widget.icone, size: 20, color: c.texto)),
          ),
        ),
      ),
    );
  }
}
