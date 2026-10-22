import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/ui/app_theme.dart';
import '../../core/ui/auria_colors.dart';
import '../../core/ui/botoes.dart';
import '../../core/ui/layout.dart';
import '../../core/ui/widgets.dart';
import '../../domain/entities/indicadores.dart';
import '../../domain/entities/ordem_servico.dart';
import '../shell/app_dados.dart';
import 'ordens_view.dart';

/// Painel de BI: os números vêm prontos da API (GET /api/indicadores, em cache por 2 min).
class IndicadoresView extends StatelessWidget {
  final AppDados dados;
  const IndicadoresView({super.key, required this.dados});

  String _dataHora(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} às ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final ind = dados.indicadores;
    if (ind == null) {
      return AuriaCard(
        child: Column(
          children: [
            const EstadoVazio(mensagem: 'Não foi possível carregar os indicadores.', icone: Icons.insights_outlined),
            OutlinedButton.icon(style: botaoSecundario(c), onPressed: dados.carregar, icon: const Icon(Icons.refresh_rounded), label: const Text('Tentar novamente')),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Text('Calculado pela API em ${_dataHora(ind.geradoEm)}', style: TextStyle(fontSize: 13, color: c.textoSecundario)),
            Wrap(spacing: 10, children: [
              OutlinedButton.icon(style: botaoSecundario(c), onPressed: dados.carregar, icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('Atualizar')),
              FilledButton.icon(
                style: botaoDestaque(c),
                onPressed: () => _exportarPdf(context, ind, dados.ordens),
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: const Text('Exportar PDF'),
              ),
            ]),
          ],
        ),
        const SizedBox(height: 18),
        GradeResponsiva(
          larguraMinima: 210,
          children: [
            KpiCard(icone: Icons.task_alt_rounded, corIcone: c.verde, fundoIcone: c.verdeFundo, valor: '${ind.taxaConclusao.toStringAsFixed(1)}%', rotulo: 'Taxa de conclusão das ordens'),
            KpiCard(icone: Icons.payments_outlined, corIcone: c.azul, fundoIcone: c.azulFundo, valor: moeda(ind.custoTotal), rotulo: 'Custo total (ordens concluídas)'),
            KpiCard(icone: Icons.hourglass_bottom_rounded, corIcone: c.laranja, fundoIcone: c.laranjaFundo, valor: '${ind.tempoMedioAtendimentoHoras.toStringAsFixed(1)} h', rotulo: 'Tempo médio de atendimento'),
            KpiCard(icone: Icons.assignment_outlined, corIcone: c.ambar, fundoIcone: c.ambarFundo, valor: '${ind.totalOrdens}', rotulo: '${ind.ordensEmAberto} em aberto · ${ind.ordensConcluidas} concluídas'),
          ],
        ),
        const SizedBox(height: 16),
        GradeResponsiva(
          larguraMinima: 380,
          maxColunas: 2,
          children: [
            AuriaCard(
              titulo: 'Recorrência de falhas por ativo',
              dica: 'Top 5 ativos com mais ordens de serviço',
              child: _GraficoAtivos(ativos: ind.topAtivosComFalhas),
            ),
            Column(
              children: [
                AuriaCard(
                  titulo: 'Composição dos custos',
                  dica: 'Ordens concluídas',
                  child: _Custos(maoDeObra: ind.custoMaoObra, pecas: ind.custoPecas),
                ),
                const SizedBox(height: 16),
                AuriaCard(
                  titulo: 'Chamados por status',
                  child: BarraStatus(quantidades: dados.chamadosPorStatus),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        AuriaCard(
          titulo: 'Ordens pendentes mais recentes',
          child: ind.ordensPendentes.isEmpty
              ? const EstadoVazio(mensagem: 'Nenhuma ordem pendente.')
              : Column(
                  children: [
                    for (final o in ind.ordensPendentes)
                      LinhaLista(
                        icone: Icons.handyman_outlined,
                        corIcone: c.laranja,
                        fundoIcone: c.laranjaFundo,
                        titulo: '${o.ativoNome} — OS #${o.ordemServicoId}',
                        detalhe: '${o.descricaoProblema} · Técnico: ${o.tecnicoNome ?? '—'}',
                        acoes: [PilulaPrioridade(prioridade: o.prioridade)],
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _exportarPdf(BuildContext context, Indicadores ind, List<OrdemServico> ordens) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF141A4D), borderRadius: pw.BorderRadius.all(pw.Radius.circular(8))),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('AURIA — MANUTENÇÃO PREDIAL', style: pw.TextStyle(color: PdfColors.white, fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Relatório de indicadores', style: pw.TextStyle(color: PdfColors.grey300, fontSize: 10)),
                ]),
                pw.Text(_dataHora(ind.geradoEm), style: pw.TextStyle(color: PdfColors.amber100, fontSize: 10)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: ['Indicador', 'Resultado'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF2D47D9)),
            data: [
              ['Taxa de conclusão', '${ind.taxaConclusao.toStringAsFixed(1)}%'],
              ['Custo total (concluídas)', moeda(ind.custoTotal)],
              ['Mão de obra / peças', '${moeda(ind.custoMaoObra)} / ${moeda(ind.custoPecas)}'],
              ['Tempo médio de atendimento', '${ind.tempoMedioAtendimentoHoras.toStringAsFixed(1)} h'],
              ['Ordens (abertas / concluídas)', '${ind.ordensEmAberto} / ${ind.ordensConcluidas}'],
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text('Ordens de serviço', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['OS', 'Ativo', 'Problema', 'Prioridade', 'Status'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF455A64)),
            data: [
              for (final o in ordens)
                ['#${o.id}', o.ativoNome ?? '—', o.descricaoProblema, o.prioridade, o.status == StatusOS.concluida ? 'Concluída' : 'Em andamento'],
            ],
          ),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (_) async => pdf.save(), name: 'indicadores_auria.pdf');
  }
}

class _GraficoAtivos extends StatelessWidget {
  final List<AtivoFalhas> ativos;
  const _GraficoAtivos({required this.ativos});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    if (ativos.isEmpty) return const EstadoVazio(mensagem: 'Ainda não há ordens registradas.', icone: Icons.bar_chart_rounded);
    final maximo = ativos.map((a) => a.quantidadeOrdens).reduce((a, b) => a > b ? a : b).toDouble();
    // O gráfico é só desenho: para o leitor de tela, descrevemos os dados em texto.
    final resumo = 'Gráfico de barras, ordens de serviço por ativo: '
        '${ativos.map((a) => '${a.ativoNome}, ${a.quantidadeOrdens} ${a.quantidadeOrdens == 1 ? 'ordem' : 'ordens'}').join('; ')}.';
    return Semantics(
      label: resumo,
      excludeSemantics: true,
      child: SizedBox(
      height: 260,
      child: BarChart(
        BarChartData(
          maxY: maximo + 1,
          gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: c.borda, strokeWidth: 1)),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => const Color(0xFF161A33),
              getTooltipItem: (grupo, _, haste, __) => BarTooltipItem(
                '${ativos[grupo.x].ativoNome}\n${haste.toY.toInt()} ordens',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (v, _) => Text('${v.toInt()}', style: AppTheme.numero(tamanho: 11, cor: c.textoSecundario, peso: FontWeight.w500)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= ativos.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: 80,
                      child: Text(ativos[i].ativoNome, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.5, color: c.textoSecundario)),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < ativos.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: ativos[i].quantidadeOrdens.toDouble(),
                  color: c.destaque,
                  width: 26,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
              ]),
          ],
        ),
      ),
    ));
  }
}

class _Custos extends StatelessWidget {
  final double maoDeObra;
  final double pecas;
  const _Custos({required this.maoDeObra, required this.pecas});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final total = maoDeObra + pecas;
    Widget linha(String rotulo, double valor, Color cor) => Semantics(
        label: '$rotulo: ${moeda(valor)}${total == 0 ? '' : ', ${(valor / total * 100).round()}% do total'}',
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 8),
                Expanded(child: Text(rotulo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                Text(moeda(valor), style: AppTheme.numero(tamanho: 13, cor: c.texto)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : valor / total,
                  minHeight: 8,
                  backgroundColor: c.cinzaFundo,
                  valueColor: AlwaysStoppedAnimation(cor),
                ),
              ),
            ],
          ),
        ));
    return Column(children: [
      linha('Mão de obra', maoDeObra, AuriaColors.pontoAberto),
      linha('Peças', pecas, AuriaColors.pontoExecucao),
    ]);
  }
}
