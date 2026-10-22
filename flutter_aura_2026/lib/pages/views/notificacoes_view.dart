import 'package:flutter/material.dart';

import '../../core/ui/auria_colors.dart';
import '../../core/ui/botoes.dart';
import '../../core/ui/layout.dart';
import '../../core/ui/widgets.dart';
import '../../domain/entities/notificacao.dart';
import '../shell/app_dados.dart';

(Color, Color, IconData) _estiloNotificacao(BuildContext context, Notificacao n) {
  final c = context.cores;
  final t = '${n.titulo} ${n.mensagem}'.toLowerCase();
  if (t.contains('estoque')) return (c.vermelho, c.vermelhoFundo, Icons.inventory_2_outlined);
  if (t.contains('conclu')) return (c.verde, c.verdeFundo, Icons.task_alt_rounded);
  if (t.contains('cancel')) return (c.cinza, c.cinzaFundo, Icons.cancel_outlined);
  if (t.contains('execu') || t.contains('ordem') || t.contains('designad')) return (c.laranja, c.laranjaFundo, Icons.handyman_outlined);
  return (c.azul, c.azulFundo, Icons.confirmation_number_outlined);
}

/// Linha do tempo compacta de notificações (usada nos painéis).
class ListaAtividade extends StatelessWidget {
  final List<Notificacao> notificacoes;
  const ListaAtividade({super.key, required this.notificacoes});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    if (notificacoes.isEmpty) return const EstadoVazio(mensagem: 'Nenhuma notificação ainda.', icone: Icons.notifications_none_rounded);
    return Column(
      children: [
        for (var i = 0; i < notificacoes.length; i++)
          Builder(builder: (context) {
            final n = notificacoes[i];
            final (cor, fundo, icone) = _estiloNotificacao(context, n);
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(border: i == notificacoes.length - 1 ? null : Border(bottom: BorderSide(color: c.borda))),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 34, height: 34, decoration: BoxDecoration(color: fundo, shape: BoxShape.circle), child: Icon(icone, size: 17, color: cor)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.titulo, style: TextStyle(fontSize: 13.5, fontWeight: n.lida ? FontWeight.w600 : FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(n.mensagem, style: TextStyle(fontSize: 13, color: c.textoSecundario, height: 1.35)),
                        const SizedBox(height: 3),
                        Text(tempoDecorrido(n.dataCriacao), style: TextStyle(fontSize: 12, color: c.textoSecundario)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class NotificacoesView extends StatefulWidget {
  final AppDados dados;
  const NotificacoesView({super.key, required this.dados});

  @override
  State<NotificacoesView> createState() => _NotificacoesViewState();
}

class _NotificacoesViewState extends State<NotificacoesView> {
  bool _soNaoLidas = false;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final d = widget.dados;
    final lista = d.notificacoes.where((n) => !_soNaoLidas || !n.lida).toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ChipFiltro(texto: 'Todas (${d.notificacoes.length})', selecionado: !_soNaoLidas, onTap: () => setState(() => _soNaoLidas = false)),
                ChipFiltro(texto: 'Não lidas (${d.naoLidas})', selecionado: _soNaoLidas, onTap: () => setState(() => _soNaoLidas = true)),
                if (d.naoLidas > 0) ...[
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    style: botaoSecundario(c),
                    onPressed: () => executarComAviso(context, d.marcarTodasComoLidas, 'Todas as notificações foram marcadas como lidas'),
                    icon: const Icon(Icons.done_all_rounded, size: 18),
                    label: const Text('Marcar todas como lidas'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 18),
            if (lista.isEmpty)
              AuriaCard(child: EstadoVazio(mensagem: _soNaoLidas ? 'Nenhuma notificação não lida.' : 'Nenhuma notificação ainda.', icone: Icons.notifications_none_rounded))
            else
              for (final n in lista)
                Builder(builder: (context) {
                  final (cor, fundo, icone) = _estiloNotificacao(context, n);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: HoverCard(
                      onTap: n.lida ? null : () => executarComAviso(context, () => d.marcarComoLida(n), 'Notificação marcada como lida'),
                      cor: n.lida ? c.superficie : c.azulFundo.withValues(alpha: 0.55),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(width: 40, height: 40, decoration: BoxDecoration(color: fundo, shape: BoxShape.circle), child: Icon(icone, size: 19, color: cor)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(n.titulo, style: TextStyle(fontSize: 14.5, fontWeight: n.lida ? FontWeight.w600 : FontWeight.w800)),
                                const SizedBox(height: 3),
                                Text(n.mensagem, style: TextStyle(fontSize: 13.5, color: c.textoSecundario, height: 1.4)),
                                const SizedBox(height: 6),
                                Text(tempoDecorrido(n.dataCriacao), style: TextStyle(fontSize: 12, color: c.textoSecundario)),
                              ],
                            ),
                          ),
                          if (!n.lida)
                            Container(width: 10, height: 10, margin: const EdgeInsets.only(top: 6, left: 8), decoration: const BoxDecoration(color: Color(0xFF3D5AFE), shape: BoxShape.circle)),
                        ],
                      ),
                    ),
                  );
                }),
          ],
        ),
      ),
    );
  }
}
