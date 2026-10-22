import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../core/ui/auria_colors.dart';
import '../../core/ui/layout.dart';
import '../../core/ui/widgets.dart';
import '../../domain/entities/alerta_preventiva.dart';
import '../../domain/entities/ordem_servico.dart';
import '../../domain/repositories/planejamento_repository.dart';
import '../shell/app_dados.dart';
import 'ordens_view.dart';

const _diasSemana = ['segunda', 'terça', 'quarta', 'quinta', 'sexta', 'sábado', 'domingo'];
const _meses = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];

/// Planejamento preventivo: cronograma do dia (calculado pela API) e alertas de ativos.
class PreventivasView extends StatefulWidget {
  final AppDados dados;
  const PreventivasView({super.key, required this.dados});

  @override
  State<PreventivasView> createState() => _PreventivasViewState();
}

class _PreventivasViewState extends State<PreventivasView> {
  final _repo = GetIt.I<PlanejamentoRepository>();
  DateTime _dia = DateTime.now();
  late Future<List<OrdemServico>> _cronograma;
  late final Future<List<AlertaPreventiva>> _alertas = _repo.buscarAlertas();

  @override
  void initState() {
    super.initState();
    _cronograma = _repo.buscarCronograma(_dia);
  }

  void _mudarDia(DateTime dia) {
    setState(() {
      _dia = dia;
      _cronograma = _repo.buscarCronograma(dia);
    });
  }

  Future<void> _escolherData() async {
    final data = await showDatePicker(context: context, initialDate: _dia, firstDate: DateTime(2020), lastDate: DateTime(2035));
    if (data != null) _mudarDia(data);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final hoje = DateUtils.isSameDay(_dia, DateTime.now());

    return GradeResponsiva(
      larguraMinima: 420,
      maxColunas: 2,
      children: [
        AuriaCard(
          titulo: 'Cronograma',
          dica: 'Ordens de chamados preventivos abertos no dia',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: c.superficie2, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.borda)),
                child: Row(
                  children: [
                    IconButton(tooltip: 'Dia anterior', onPressed: () => _mudarDia(_dia.subtract(const Duration(days: 1))), icon: const Icon(Icons.chevron_left_rounded)),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: _escolherData,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            children: [
                              Text(hoje ? 'Hoje' : _diasSemana[_dia.weekday - 1], style: TextStyle(fontSize: 12, color: c.textoSecundario, fontWeight: FontWeight.w600)),
                              Text('${_dia.day} de ${_meses[_dia.month - 1]} de ${_dia.year}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    IconButton(tooltip: 'Próximo dia', onPressed: () => _mudarDia(_dia.add(const Duration(days: 1))), icon: const Icon(Icons.chevron_right_rounded)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<OrdemServico>>(
                future: _cronograma,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(semanticsLabel: 'Carregando')));
                  }
                  if (snap.hasError) return BlocoTexto('${snap.error}', secundario: true);
                  final ordens = snap.data ?? [];
                  if (ordens.isEmpty) {
                    return const EstadoVazio(mensagem: 'Nenhuma preventiva neste dia.', icone: Icons.event_available_outlined);
                  }
                  return Column(
                    children: [
                      for (final os in ordens)
                        LinhaLista(
                          icone: Icons.build_circle_outlined,
                          corIcone: os.status == StatusOS.concluida ? c.verde : c.azul,
                          fundoIcone: os.status == StatusOS.concluida ? c.verdeFundo : c.azulFundo,
                          titulo: os.ativoNome ?? 'Ativo #${os.ativoId}',
                          detalhe: 'Técnico: ${os.tecnicoNome ?? '—'} · ${os.descricaoProblema}',
                          onTap: () => abrirPainelOrdem(context, widget.dados, os),
                          acoes: [PilulaOrdem(concluida: os.status == StatusOS.concluida)],
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        AuriaCard(
          titulo: 'Alertas',
          dica: 'Ativos que precisam de manutenção preventiva',
          child: FutureBuilder<List<AlertaPreventiva>>(
            future: _alertas,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(semanticsLabel: 'Carregando')));
              }
              if (snap.hasError) return BlocoTexto('${snap.error}', secundario: true);
              final alertas = snap.data ?? [];
              if (alertas.isEmpty) return const EstadoVazio(mensagem: 'Nenhum ativo precisando de atenção.');
              return Column(
                children: [
                  for (final a in alertas)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: c.superficie2, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.borda)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(color: c.ambarFundo, borderRadius: BorderRadius.circular(11)),
                            child: Icon(Icons.warning_amber_rounded, size: 19, color: c.ambar),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.nome, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                Text('${a.ambienteNome ?? 'Sem ambiente'} · Patrimônio ${a.patrimonio}', style: TextStyle(fontSize: 12.5, color: c.textoSecundario)),
                                const SizedBox(height: 8),
                                Wrap(spacing: 6, runSpacing: 6, children: [
                                  for (final m in a.motivos) Pilula(texto: m, cor: c.ambar, fundo: c.ambarFundo, comPonto: false),
                                ]),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
