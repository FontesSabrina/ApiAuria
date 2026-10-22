import 'package:flutter/material.dart';

import '../../core/ui/auria_colors.dart';
import '../../core/ui/botoes.dart';
import '../../core/ui/layout.dart';
import '../../core/ui/widgets.dart';
import '../../domain/entities/chamado.dart';
import '../shell/app_dados.dart';
import '../shell/auria_shell.dart';
import 'chamados_kanban_view.dart';
import 'notificacoes_view.dart';
import 'painel_admin_view.dart';

/// Início do solicitante: atalho grande para abrir chamado e o andamento dos pedidos.
class PainelSolicitanteView extends StatelessWidget {
  final AppDados dados;
  final ValueChanged<Secao> onIrPara;
  const PainelSolicitanteView({super.key, required this.dados, required this.onIrPara});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final emAndamento = dados.chamados.where((ch) => ch.status == StatusChamado.aberto || ch.status == StatusChamado.emExecucao).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Saudacao(
          nome: dados.usuario.nome,
          fraseNeutra: emAndamento.isEmpty ? 'Algo precisa de manutenção? Abra um chamado.' : 'Acompanhe abaixo os seus pedidos em andamento.',
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: c.menu, borderRadius: BorderRadius.circular(20)),
          child: Wrap(
            spacing: 20,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Encontrou um problema?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 6),
                    Text('Ar-condicionado pingando, lâmpada queimada, porta emperrada… Conte pra gente e a equipe de manutenção resolve.',
                        style: TextStyle(fontSize: 14, color: c.menuTexto, height: 1.45)),
                  ],
                ),
              ),
              FilledButton.icon(
                style: botaoDestaque(c),
                onPressed: () => onIrPara(Secao.abrirChamado),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Abrir chamado'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GradeResponsiva(
          larguraMinima: 180,
          maxColunas: 3,
          children: [
            KpiCard(icone: Icons.hourglass_empty_rounded, corIcone: c.azul, fundoIcone: c.azulFundo, valor: '${dados.abertos}', rotulo: 'Aguardando aprovação', onTap: () => onIrPara(Secao.meusChamados)),
            KpiCard(icone: Icons.handyman_outlined, corIcone: c.laranja, fundoIcone: c.laranjaFundo, valor: '${dados.emExecucao}', rotulo: 'Em execução', onTap: () => onIrPara(Secao.meusChamados)),
            KpiCard(icone: Icons.task_alt_rounded, corIcone: c.verde, fundoIcone: c.verdeFundo, valor: '${dados.contar(StatusChamado.concluido)}', rotulo: 'Resolvidos', onTap: () => onIrPara(Secao.meusChamados)),
          ],
        ),
        const SizedBox(height: 16),
        GradeResponsiva(
          larguraMinima: 380,
          maxColunas: 2,
          children: [
            AuriaCard(
              titulo: 'Em andamento',
              acao: TextButton(onPressed: () => onIrPara(Secao.meusChamados), child: const Text('Ver todos')),
              child: emAndamento.isEmpty
                  ? const EstadoVazio(mensagem: 'Nenhum chamado em andamento.')
                  : Column(
                      children: [
                        for (final ch in emAndamento.take(4))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => abrirDetalheChamado(context, dados, ch),
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(children: [
                                      Expanded(child: Text(ch.ativo.nome, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800))),
                                      Text('#${ch.id}', style: TextStyle(fontSize: 12, color: c.textoSecundario)),
                                    ]),
                                    const SizedBox(height: 2),
                                    Text(ch.descricaoFalha, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: c.textoSecundario)),
                                    const SizedBox(height: 12),
                                    LinhaDoTempoChamado(status: ch.status),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
            AuriaCard(
              titulo: 'Avisos',
              acao: TextButton(onPressed: () => onIrPara(Secao.notificacoes), child: const Text('Ver todos')),
              child: ListaAtividade(notificacoes: dados.notificacoes.take(5).toList()),
            ),
          ],
        ),
      ],
    );
  }
}
