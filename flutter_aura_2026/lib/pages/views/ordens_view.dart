import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/ui/app_theme.dart';
import '../../core/ui/auria_colors.dart';
import '../../core/ui/botoes.dart';
import '../../core/ui/layout.dart';
import '../../core/ui/widgets.dart';
import '../../domain/entities/item_estoque.dart';
import '../../domain/entities/ordem_servico.dart';
import '../shell/app_dados.dart';

String moeda(double valor) => 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';

/// Ordens de serviço: o Admin vê todas; o técnico, as designadas a ele.
class OrdensView extends StatefulWidget {
  final AppDados dados;
  const OrdensView({super.key, required this.dados});

  @override
  State<OrdensView> createState() => _OrdensViewState();
}

class _OrdensViewState extends State<OrdensView> {
  bool _concluidas = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.dados;
    final emAndamento = d.ordensEmAndamento;
    final concluidas = d.ordensConcluidas;
    final lista = (_concluidas ? concluidas : emAndamento)
        .where((o) => d.passaNaBusca('${o.ativoNome ?? ''} ${o.descricaoProblema} ${o.tecnicoNome ?? ''} ${o.id}'))
        .toList()
      ..sort((a, b) => PilulaPrioridade.peso(a.prioridade).compareTo(PilulaPrioridade.peso(b.prioridade)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          ChipFiltro(texto: 'Em andamento (${emAndamento.length})', selecionado: !_concluidas, onTap: () => setState(() => _concluidas = false)),
          ChipFiltro(texto: 'Concluídas (${concluidas.length})', selecionado: _concluidas, onTap: () => setState(() => _concluidas = true)),
        ]),
        const SizedBox(height: 18),
        if (lista.isEmpty)
          AuriaCard(
            child: EstadoVazio(
              mensagem: _concluidas ? 'Nenhuma ordem concluída ainda.' : 'Nenhuma ordem em andamento. Bom trabalho!',
              icone: Icons.handyman_outlined,
            ),
          )
        else
          GradeResponsiva(
            larguraMinima: 300,
            maxColunas: 3,
            children: [for (final os in lista) CardOrdem(ordem: os, dados: d)],
          ),
      ],
    );
  }
}

class CardOrdem extends StatelessWidget {
  final OrdemServico ordem;
  final AppDados dados;
  const CardOrdem({super.key, required this.ordem, required this.dados});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final concluida = ordem.status == StatusOS.concluida;
    return HoverCard(
      onTap: () => abrirPainelOrdem(context, dados, ordem),
      semantica: 'Ordem de serviço ${ordem.id}',
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Wrap(spacing: 6, runSpacing: 6, children: [
                  PilulaOrdem(concluida: concluida),
                  PilulaPrioridade(prioridade: ordem.prioridade),
                ]),
              ),
              const SizedBox(width: 8),
              Text('OS #${ordem.id}', style: AppTheme.numero(tamanho: 12, cor: c.textoSecundario, peso: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 10),
          Text(ordem.ativoNome ?? 'Ativo #${ordem.ativoId}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(ordem.descricaoProblema, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: c.textoSecundario, height: 1.4)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: c.borda))),
            child: Row(
              children: [
                AvatarIniciais(nome: ordem.tecnicoNome ?? '?', cor: c.laranja, fundo: c.laranjaFundo),
                const SizedBox(width: 8),
                Expanded(child: Text(ordem.tecnicoNome ?? '—', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: c.textoSecundario))),
                if (concluida)
                  Text(moeda(ordem.custoTotal), style: AppTheme.numero(tamanho: 12.5, cor: c.texto))
                else ...[
                  Icon(Icons.schedule_rounded, size: 13, color: c.textoSecundario),
                  const SizedBox(width: 4),
                  Text(tempoDecorrido(ordem.dataInicio ?? ordem.dataAbertura), style: TextStyle(fontSize: 12, color: c.textoSecundario)),
                ],
              ],
            ),
          ),
          if (dados.podeExecutar(ordem)) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: botaoDestaque(c),
                onPressed: () => abrirPainelOrdem(context, dados, ordem),
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Executar'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PilulaOrdem extends StatelessWidget {
  final bool concluida;
  const PilulaOrdem({super.key, required this.concluida});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return concluida
        ? Pilula(texto: 'Concluída', cor: c.verde, fundo: c.verdeFundo)
        : Pilula(texto: 'Em andamento', cor: c.laranja, fundo: c.laranjaFundo);
  }
}

Future<void> abrirPainelOrdem(BuildContext context, AppDados dados, OrdemServico ordem) =>
    mostrarPainelLateral(context, largura: 520, builder: (_) => _PainelOrdem(ordem: ordem, dados: dados));

class _PainelOrdem extends StatefulWidget {
  final OrdemServico ordem;
  final AppDados dados;
  const _PainelOrdem({required this.ordem, required this.dados});

  @override
  State<_PainelOrdem> createState() => _PainelOrdemState();
}

class _PainelOrdemState extends State<_PainelOrdem> {
  late OrdemServico _os = widget.ordem;
  final _form = GlobalKey<FormState>();
  final _parecer = TextEditingController();
  final _minutos = TextEditingController();
  final _maoDeObra = TextEditingController();
  final _qtdPeca = TextEditingController(text: '1');
  ItemEstoque? _peca;
  int _versaoPeca = 0;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _parecer.text = _os.relatotecnico ?? '';
    _maoDeObra.text = _os.custoMaoDeObra > 0 ? _os.custoMaoDeObra.toStringAsFixed(2) : '';
    final decorridos = DateTime.now().difference(_os.dataInicio ?? DateTime.now()).inMinutes;
    _minutos.text = _os.tempoGastoMinutos > 0 ? '${_os.tempoGastoMinutos}' : '${decorridos.clamp(0, 600)}';
  }

  @override
  void dispose() {
    _parecer.dispose();
    _minutos.dispose();
    _maoDeObra.dispose();
    _qtdPeca.dispose();
    super.dispose();
  }

  Future<void> _adicionarPeca() async {
    final item = _peca;
    final qtd = int.tryParse(_qtdPeca.text) ?? 0;
    if (item == null || qtd <= 0) return;
    setState(() => _enviando = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final atualizada = await widget.dados.registrarConsumo(_os, item, qtd);
      if (!mounted) return;
      setState(() {
        _os = atualizada;
        _peca = null;
        _versaoPeca++;
        _qtdPeca.text = '1';
      });
      messenger.showSnackBar(SnackBar(content: Text('$qtd × ${item.nome} registrado na OS')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e'), backgroundColor: const Color(0xFFB42318)));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _concluir() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _enviando = true);
    final ok = await executarComAviso(
      context,
      () => widget.dados.concluirOrdem(
        _os,
        parecer: _parecer.text.trim(),
        minutos: int.tryParse(_minutos.text) ?? 0,
        maoDeObra: double.tryParse(_maoDeObra.text.replaceAll(',', '.')) ?? 0,
      ),
      'OS #${_os.id} concluída. O solicitante foi avisado.',
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final d = widget.dados;
    final os = _os;
    final concluida = os.status == StatusOS.concluida;
    final podeExecutar = d.podeExecutar(os);
    final disponiveis = d.estoque.where((i) => i.quantidade > 0).toList();

    return Form(
      key: _form,
      child: EstruturaPainel(
        cabecalho: TituloPainel(
          titulo: os.ativoNome ?? 'Ativo #${os.ativoId}',
          sobretitulo: 'OS #${os.id} · Chamado #${os.chamadoId} · ${os.tipoManutencao}',
          etiquetas: [PilulaOrdem(concluida: concluida), PilulaPrioridade(prioridade: os.prioridade, prefixo: 'Prioridade ')],
        ),
        corpo: [
          BlocoTexto('“${os.descricaoProblema}”'),
          const SizedBox(height: 20),
          GradeResponsiva(
            larguraMinima: 140,
            espaco: 14,
            maxColunas: 3,
            children: [
              Fato(rotulo: 'Técnico', valor: os.tecnicoNome ?? '—'),
              Fato(rotulo: 'Iniciada', valor: tempoDecorrido(os.dataInicio ?? os.dataAbertura)),
              Fato(rotulo: 'Custo atual', valor: moeda(os.custoTotal), numerico: true),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(child: RotuloSecao('Peças utilizadas')),
              Text(moeda(os.custoPecas), style: AppTheme.numero(tamanho: 13, cor: c.texto)),
            ],
          ),
          const SizedBox(height: 10),
          if (os.pecasUtilizadas.isEmpty)
            Text('Nenhuma peça registrada.', style: TextStyle(color: c.textoSecundario))
          else
            for (final p in os.pecasUtilizadas)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 18, color: c.textoSecundario),
                    const SizedBox(width: 10),
                    Expanded(child: Text(p.nome, style: const TextStyle(fontWeight: FontWeight.w600))),
                    Text('${p.quantidade} × ${moeda(p.precoUnitario)}', style: AppTheme.numero(tamanho: 12.5, cor: c.textoSecundario, peso: FontWeight.w500)),
                  ],
                ),
              ),
          if (podeExecutar) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: c.superficie2, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.borda)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<ItemEstoque>(
                      // A chave muda quando a peça é registrada, para o campo voltar a ficar vazio.
                      key: ValueKey('peca-$_versaoPeca'),
                      initialValue: _peca,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Peça do estoque', isDense: true),
                      items: [
                        for (final i in disponiveis)
                          DropdownMenuItem(value: i, child: Text('${i.nome} (${i.quantidade} disp.)', overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (v) => setState(() => _peca = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 70,
                    child: TextField(
                      controller: _qtdPeca,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'Qtd.', isDense: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: botaoPequeno(c).copyWith(minimumSize: const WidgetStatePropertyAll(Size(0, 44))),
                    onPressed: _peca == null || _enviando ? null : _adicionarPeca,
                    child: const Text('Adicionar'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text('A API debita o estoque e avisa o Admin se o item ficar abaixo do mínimo.', style: TextStyle(fontSize: 12, color: c.textoSecundario)),
          ],
          const SizedBox(height: 24),
          if (concluida) ...[
            const RotuloSecao('Parecer técnico'),
            const SizedBox(height: 10),
            BlocoTexto(os.relatotecnico?.isNotEmpty == true ? os.relatotecnico! : 'Sem parecer registrado.', secundario: os.relatotecnico?.isNotEmpty != true),
            const SizedBox(height: 16),
            GradeResponsiva(
              larguraMinima: 140,
              espaco: 14,
              maxColunas: 3,
              children: [
                Fato(rotulo: 'Tempo gasto', valor: '${os.tempoGastoMinutos} min', numerico: true),
                Fato(rotulo: 'Mão de obra', valor: moeda(os.custoMaoDeObra), numerico: true),
                Fato(rotulo: 'Concluída', valor: os.dataFim == null ? '—' : tempoDecorrido(os.dataFim!)),
              ],
            ),
          ] else if (podeExecutar) ...[
            const RotuloSecao('Concluir manutenção'),
            const SizedBox(height: 12),
            CampoFormulario(
              rotulo: 'Tempo gasto (minutos)',
              campo: TextFormField(
                controller: _minutos,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => (int.tryParse(v ?? '') ?? -1) < 0 ? 'Informe o tempo em minutos' : null,
              ),
            ),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final m in const [30, 60, 90, 120, 240])
                ChipFiltro(texto: m < 60 ? '$m min' : '${m ~/ 60} h${m % 60 == 0 ? '' : ' ${m % 60}'}', selecionado: _minutos.text == '$m', onTap: () => setState(() => _minutos.text = '$m')),
            ]),
            const SizedBox(height: 16),
            CampoFormulario(
              rotulo: 'Parecer técnico',
              campo: TextFormField(
                controller: _parecer,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'O que foi feito, peças trocadas, recomendações…'),
                validator: (v) => (v ?? '').trim().length < 5 ? 'Descreva o serviço realizado' : null,
              ),
            ),
            CampoFormulario(
              rotulo: 'Custo de mão de obra (R\$)',
              campo: TextFormField(
                controller: _maoDeObra,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                decoration: const InputDecoration(hintText: '0,00'),
              ),
              ajuda: 'O custo das peças é calculado automaticamente.',
            ),
          ] else
            BlocoTexto('Esta ordem está designada a outro técnico.', secundario: true),
        ],
        rodape: podeExecutar
            ? FilledButton.icon(
                style: botaoDestaque(c),
                onPressed: _enviando ? null : _concluir,
                icon: const Icon(Icons.task_alt_rounded, size: 18),
                label: const Text('Concluir ordem de serviço'),
              )
            : null,
      ),
    );
  }
}
