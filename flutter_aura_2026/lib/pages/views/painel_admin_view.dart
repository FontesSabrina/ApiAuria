import 'package:flutter/material.dart';

import '../../core/ui/auria_colors.dart';
import '../../core/ui/botoes.dart';
import '../../core/ui/layout.dart';
import '../../core/ui/widgets.dart';
import '../../domain/entities/chamado.dart';
import '../../domain/entities/item_estoque.dart';
import '../shell/app_dados.dart';
import '../shell/auria_shell.dart';
import 'chamados_kanban_view.dart';
import 'notificacoes_view.dart';

/// Tela inicial do Admin: números do dia, pendências resolvíveis ali mesmo,
/// atividade recente e gráficos rápidos.
class PainelAdminView extends StatelessWidget {
  final AppDados dados;
  final ValueChanged<Secao> onIrPara;
  const PainelAdminView({super.key, required this.dados, required this.onIrPara});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final pendentes = dados.chamados.where((ch) => ch.status == StatusChamado.aberto).toList()
      ..sort((a, b) => PilulaPrioridade.peso(a.prioridade).compareTo(PilulaPrioridade.peso(b.prioridade)));
    final criticos = dados.criticos;
    final total = pendentes.length + criticos.length;

    final ranking = (dados.indicadores?.topAtivosComFalhas ?? const [])
        .take(4)
        .map((a) => (a.ativoNome, a.quantidadeOrdens))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Saudacao(
          nome: dados.usuario.nome,
          frase: total == 0 ? null : '$total ${total == 1 ? 'pendência' : 'pendências'}',
          acoes: [
            FilledButton.icon(
              style: botaoDestaque(c),
              onPressed: () => onIrPara(Secao.chamados),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Ver quadro de chamados'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        GradeResponsiva(
          larguraMinima: 210,
          children: [
            KpiCard(
              icone: Icons.confirmation_number_outlined,
              corIcone: c.azul,
              fundoIcone: c.azulFundo,
              valor: '${dados.abertos}',
              rotulo: 'Chamados aguardando aprovação',
              onTap: () => onIrPara(Secao.chamados),
            ),
            KpiCard(
              icone: Icons.handyman_outlined,
              corIcone: c.laranja,
              fundoIcone: c.laranjaFundo,
              valor: '${dados.ordensEmAndamento.length}',
              rotulo: 'Manutenções em execução',
              onTap: () => onIrPara(Secao.ordens),
            ),
            KpiCard(
              icone: Icons.warning_amber_rounded,
              corIcone: c.vermelho,
              fundoIcone: c.vermelhoFundo,
              valor: '${criticos.length}',
              rotulo: 'Itens abaixo do estoque mínimo',
              onTap: () => onIrPara(Secao.estoque),
            ),
            KpiCard(
              icone: Icons.task_alt_rounded,
              corIcone: c.verde,
              fundoIcone: c.verdeFundo,
              valor: '${dados.taxaConclusao}%',
              rotulo: 'Taxa de conclusão das ordens',
              onTap: () => onIrPara(Secao.indicadores),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GradeResponsiva(
          larguraMinima: 380,
          children: [
            AuriaCard(
              titulo: 'Precisa da sua atenção',
              dica: 'Resolva direto daqui — sem trocar de tela.',
              child: total == 0
                  ? const EstadoVazio(mensagem: 'Tudo em dia! Nenhuma pendência no momento.')
                  : Column(
                      children: [
                        for (final ch in pendentes.take(5))
                          LinhaLista(
                            icone: Icons.confirmation_number_outlined,
                            corIcone: c.azul,
                            fundoIcone: c.azulFundo,
                            titulo: ch.ativo.nome,
                            detalhe: '#${ch.id} · ${ch.descricaoFalha}',
                            onTap: () => abrirDetalheChamado(context, dados, ch),
                            acoes: [
                              PilulaPrioridade(prioridade: ch.prioridade),
                              OutlinedButton(style: botaoPequeno(c), onPressed: () => abrirDetalheChamado(context, dados, ch), child: const Text('Aprovar')),
                            ],
                          ),
                        for (final item in criticos.take(4)) _LinhaEstoqueCritico(item: item, dados: dados),
                      ],
                    ),
            ),
            AuriaCard(
              titulo: 'Atividade recente',
              dica: 'Notificações geradas pelo sistema.',
              acao: TextButton(onPressed: () => onIrPara(Secao.notificacoes), child: const Text('Ver todas')),
              child: ListaAtividade(notificacoes: dados.notificacoes.take(6).toList()),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GradeResponsiva(
          larguraMinima: 380,
          children: [
            AuriaCard(
              titulo: 'Chamados por status',
              dica: '${dados.chamados.length} chamados registrados',
              child: BarraStatus(quantidades: dados.chamadosPorStatus),
            ),
            AuriaCard(
              titulo: 'Ativos com mais ocorrências',
              dica: 'Candidatos a manutenção preventiva',
              child: RankingBarras(itens: ranking, mensagemVazia: 'Ainda não há ocorrências registradas.'),
            ),
          ],
        ),
      ],
    );
  }
}

class _LinhaEstoqueCritico extends StatelessWidget {
  final ItemEstoque item;
  final AppDados dados;
  const _LinhaEstoqueCritico({required this.item, required this.dados});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return LinhaLista(
      icone: Icons.inventory_2_outlined,
      corIcone: c.vermelho,
      fundoIcone: c.vermelhoFundo,
      titulo: item.nome,
      detalhe: '${item.quantidade} em estoque · mínimo ${item.nivelMinimo}',
      acoes: [
        Pilula(texto: 'Estoque', cor: c.vermelho, fundo: c.vermelhoFundo),
        OutlinedButton(
          style: botaoPequeno(c),
          onPressed: () => executarComAviso(context, () => dados.registrarEntrada(item, 10), 'Entrada registrada: +10 ${item.nome}'),
          child: const Text('Repor +10'),
        ),
      ],
    );
  }
}

/// Cabeçalho de boas-vindas dos painéis ("Bom dia, Fulano" + frase + ações).
class Saudacao extends StatelessWidget {
  final String nome;
  /// Quando informado, aparece "Você tem `frase` esperando por você." com a frase em vermelho.
  final String? frase;
  final String? fraseNeutra;
  final List<Widget> acoes;

  const Saudacao({super.key, required this.nome, this.frase, this.fraseNeutra, this.acoes = const []});

  static String saudacaoDoHorario() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bom dia';
    if (h < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final primeiroNome = nome.trim().split(' ').first;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${saudacaoDoHorario()}, $primeiroNome', style: TextStyle(fontSize: 15, color: c.textoSecundario)),
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                children: frase == null
                    ? [TextSpan(text: fraseNeutra ?? 'Tudo em dia por aqui.')]
                    : [
                        const TextSpan(text: 'Você tem '),
                        TextSpan(text: frase, style: TextStyle(color: c.vermelho)),
                        const TextSpan(text: ' esperando por você.'),
                      ],
              ),
            ),
          ],
        ),
        if (acoes.isNotEmpty) Wrap(spacing: 10, runSpacing: 10, children: acoes),
      ],
    );
  }
}
