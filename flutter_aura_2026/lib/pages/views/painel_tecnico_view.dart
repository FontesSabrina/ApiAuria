import 'package:flutter/material.dart';

import '../../core/ui/auria_colors.dart';
import '../../core/ui/botoes.dart';
import '../../core/ui/layout.dart';
import '../../core/ui/widgets.dart';
import '../shell/app_dados.dart';
import '../shell/auria_shell.dart';
import 'notificacoes_view.dart';
import 'ordens_view.dart';
import 'painel_admin_view.dart';

/// "Meu dia" do técnico: ordens em andamento (prontas para executar), números e avisos.
class PainelTecnicoView extends StatelessWidget {
  final AppDados dados;
  final ValueChanged<Secao> onIrPara;
  const PainelTecnicoView({super.key, required this.dados, required this.onIrPara});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final emAndamento = dados.ordensEmAndamento
      ..sort((a, b) => PilulaPrioridade.peso(a.prioridade).compareTo(PilulaPrioridade.peso(b.prioridade)));
    final n = emAndamento.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Saudacao(
          nome: dados.usuario.nome,
          frase: n == 0 ? null : '$n ${n == 1 ? 'ordem de serviço' : 'ordens de serviço'}',
          fraseNeutra: 'Nenhuma ordem pendente. Bom trabalho!',
          acoes: [
            FilledButton.icon(
              style: botaoDestaque(c),
              onPressed: () => onIrPara(Secao.ordens),
              icon: const Icon(Icons.handyman_outlined, size: 18),
              label: const Text('Minhas ordens'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        GradeResponsiva(
          larguraMinima: 210,
          maxColunas: 3,
          children: [
            KpiCard(
              icone: Icons.handyman_outlined,
              corIcone: c.laranja,
              fundoIcone: c.laranjaFundo,
              valor: '$n',
              rotulo: 'Ordens em andamento',
              onTap: () => onIrPara(Secao.ordens),
            ),
            KpiCard(
              icone: Icons.task_alt_rounded,
              corIcone: c.verde,
              fundoIcone: c.verdeFundo,
              valor: '${dados.ordensConcluidas.length}',
              rotulo: 'Ordens concluídas por você',
              onTap: () => onIrPara(Secao.ordens),
            ),
            KpiCard(
              icone: Icons.inventory_2_outlined,
              corIcone: c.vermelho,
              fundoIcone: c.vermelhoFundo,
              valor: '${dados.criticos.length}',
              rotulo: 'Peças abaixo do mínimo',
              onTap: () => onIrPara(Secao.estoque),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GradeResponsiva(
          larguraMinima: 380,
          maxColunas: 2,
          children: [
            AuriaCard(
              titulo: 'Próximas ordens',
              dica: 'Ordenadas por prioridade',
              child: emAndamento.isEmpty
                  ? const EstadoVazio(mensagem: 'Nenhuma ordem em andamento.')
                  : Column(
                      children: [
                        for (final os in emAndamento.take(5))
                          LinhaLista(
                            icone: Icons.handyman_outlined,
                            corIcone: c.laranja,
                            fundoIcone: c.laranjaFundo,
                            titulo: os.ativoNome ?? 'Ativo #${os.ativoId}',
                            detalhe: 'OS #${os.id} · ${os.descricaoProblema}',
                            onTap: () => abrirPainelOrdem(context, dados, os),
                            acoes: [
                              PilulaPrioridade(prioridade: os.prioridade),
                              OutlinedButton(style: botaoPequeno(c), onPressed: () => abrirPainelOrdem(context, dados, os), child: const Text('Executar')),
                            ],
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
