import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../core/ui/app_theme.dart';
import '../../core/ui/auria_colors.dart';
import '../../core/ui/botoes.dart';
import '../../core/ui/layout.dart';
import '../../core/ui/widgets.dart';
import '../../domain/entities/item_estoque.dart';
import '../shell/app_dados.dart';
import 'ordens_view.dart';

enum _Nivel { critico, atencao, ok }

_Nivel _nivelDe(ItemEstoque i) {
  if (i.quantidade <= i.nivelMinimo) return _Nivel.critico;
  if (i.quantidade <= i.nivelMinimo * 1.5) return _Nivel.atencao;
  return _Nivel.ok;
}

/// Estoque com barra de nível por item. Admin cadastra, edita e dá entrada; técnico só consulta.
class EstoqueView extends StatefulWidget {
  final AppDados dados;
  const EstoqueView({super.key, required this.dados});

  @override
  State<EstoqueView> createState() => _EstoqueViewState();
}

class _EstoqueViewState extends State<EstoqueView> {
  bool _soCriticos = false;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final d = widget.dados;
    final itens = d.estoque
        .where((i) => !_soCriticos || _nivelDe(i) == _Nivel.critico)
        .where((i) => d.passaNaBusca(i.nome))
        .toList()
      ..sort((a, b) => _nivelDe(a).index.compareTo(_nivelDe(b).index));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ChipFiltro(texto: 'Todos os itens (${d.estoque.length})', selecionado: !_soCriticos, onTap: () => setState(() => _soCriticos = false)),
            ChipFiltro(texto: 'Abaixo do mínimo (${d.criticos.length})', selecionado: _soCriticos, onTap: () => setState(() => _soCriticos = true)),
            const SizedBox(width: 12),
            _legenda(c, AuriaColors.nivelCritico, 'Abaixo do mínimo'),
            _legenda(c, AuriaColors.nivelAtencao, 'Atenção'),
            _legenda(c, AuriaColors.nivelOk, 'Ok'),
            if (d.ehAdmin) ...[
              const SizedBox(width: 12),
              FilledButton.icon(
                style: botaoDestaque(c),
                onPressed: () => abrirFormularioItem(context, d),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Novo item'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 18),
        AuriaCard(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
          child: itens.isEmpty
              ? EstadoVazio(mensagem: _soCriticos ? 'Nenhum item abaixo do mínimo.' : 'Nenhum item encontrado.', icone: Icons.inventory_2_outlined)
              : Column(
                  children: [
                    for (var i = 0; i < itens.length; i++) _LinhaItem(item: itens[i], ultimo: i == itens.length - 1, dados: d),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _legenda(AuriaColors c, Color cor, String texto) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 6),
          Text(texto, style: TextStyle(fontSize: 13, color: c.textoSecundario)),
        ],
      );
}

class _LinhaItem extends StatefulWidget {
  final ItemEstoque item;
  final bool ultimo;
  final AppDados dados;
  const _LinhaItem({required this.item, required this.ultimo, required this.dados});

  @override
  State<_LinhaItem> createState() => _LinhaItemState();
}

class _LinhaItemState extends State<_LinhaItem> {
  bool _enviando = false;

  Future<void> _entrada() async {
    setState(() => _enviando = true);
    await executarComAviso(context, () => widget.dados.registrarEntrada(widget.item, 10), 'Entrada registrada: +10 ${widget.item.nome}');
    if (mounted) setState(() => _enviando = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final item = widget.item;
    final (corBarra, rotulo, corPilula, fundoPilula) = switch (_nivelDe(item)) {
      _Nivel.critico => (AuriaColors.nivelCritico, 'Repor já', c.vermelho, c.vermelhoFundo),
      _Nivel.atencao => (AuriaColors.nivelAtencao, 'Atenção', c.ambar, c.ambarFundo),
      _Nivel.ok => (AuriaColors.nivelOk, 'Ok', c.verde, c.verdeFundo),
    };
    final referencia = item.nivelMinimo <= 0 ? 10 : item.nivelMinimo * 3;
    final proporcao = (item.quantidade / referencia).clamp(0.04, 1.0).toDouble();

    final nome = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(item.nome, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text('${moeda(item.precoUnitario)} por unidade', style: AppTheme.numero(tamanho: 12, cor: c.textoSecundario, peso: FontWeight.w500)),
      ],
    );

    final barra = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('${item.quantidade}', style: AppTheme.numero(tamanho: 13, cor: c.texto)),
            Text(' em estoque', style: TextStyle(fontSize: 12.5, color: c.textoSecundario)),
            const Spacer(),
            Text('mínimo ${item.nivelMinimo}', style: TextStyle(fontSize: 12.5, color: c.textoSecundario)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(value: proporcao, minHeight: 10, backgroundColor: c.cinzaFundo, valueColor: AlwaysStoppedAnimation(corBarra)),
        ),
      ],
    );

    final acoes = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Pilula(texto: rotulo, cor: corPilula, fundo: fundoPilula),
        if (widget.dados.ehAdmin) ...[
          const SizedBox(width: 12),
          OutlinedButton.icon(
            style: botaoPequeno(c),
            onPressed: _enviando ? null : _entrada,
            icon: _enviando ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, semanticsLabel: 'Salvando')) : const Icon(Icons.add_rounded, size: 16),
            label: const Text('Entrada +10'),
          ),
          const SizedBox(width: 6),
          IconButton(tooltip: 'Editar item', onPressed: () => abrirFormularioItem(context, widget.dados, item: item), icon: Icon(Icons.edit_outlined, color: c.textoSecundario)),
        ],
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(border: widget.ultimo ? null : Border(bottom: BorderSide(color: c.borda))),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 680) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [nome, const SizedBox(height: 10), barra, const SizedBox(height: 10), Align(alignment: Alignment.centerLeft, child: acoes)],
            );
          }
          return Row(children: [Expanded(flex: 2, child: nome), const SizedBox(width: 18), Expanded(flex: 3, child: barra), const SizedBox(width: 18), acoes]);
        },
      ),
    );
  }
}

/// Formulário de item de estoque (novo ou edição) num painel lateral.
Future<void> abrirFormularioItem(BuildContext context, AppDados dados, {ItemEstoque? item}) =>
    mostrarPainelLateral(context, builder: (_) => _FormularioItem(dados: dados, item: item));

class _FormularioItem extends StatefulWidget {
  final AppDados dados;
  final ItemEstoque? item;
  const _FormularioItem({required this.dados, this.item});

  @override
  State<_FormularioItem> createState() => _FormularioItemState();
}

class _FormularioItemState extends State<_FormularioItem> {
  final _form = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.item?.nome ?? '');
  late final _qtd = TextEditingController(text: '${widget.item?.quantidade ?? 0}');
  late final _minimo = TextEditingController(text: '${widget.item?.nivelMinimo ?? 5}');
  late final _preco = TextEditingController(text: widget.item == null ? '' : widget.item!.precoUnitario.toStringAsFixed(2));
  bool _enviando = false;

  @override
  void dispose() {
    _nome.dispose();
    _qtd.dispose();
    _minimo.dispose();
    _preco.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _enviando = true);
    final item = ItemEstoque(
      id: widget.item?.id ?? const Uuid().v4(),
      nome: _nome.text.trim(),
      quantidade: int.tryParse(_qtd.text) ?? 0,
      nivelMinimo: int.tryParse(_minimo.text) ?? 0,
      precoUnitario: double.tryParse(_preco.text.replaceAll(',', '.')) ?? 0,
    );
    final ok = await executarComAviso(context, () => widget.dados.salvarItem(item), widget.item == null ? 'Item cadastrado!' : 'Item atualizado!');
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _enviando = false);
    }
  }

  Future<void> _excluir() async {
    final item = widget.item!;
    final ok = await confirmar(context, titulo: 'Excluir ${item.nome}?', mensagem: 'Itens já usados em ordens de serviço não podem ser excluídos.', acao: 'Excluir', perigosa: true);
    if (!ok || !mounted) return;
    if (await executarComAviso(context, () => widget.dados.excluirItem(item), 'Item excluído') && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final numero = [FilteringTextInputFormatter.digitsOnly];
    String? obrigatorioNumero(String? v) => int.tryParse(v ?? '') == null ? 'Informe um número' : null;

    return Form(
      key: _form,
      child: EstruturaPainel(
        cabecalho: TituloPainel(titulo: widget.item == null ? 'Novo item de estoque' : widget.item!.nome, sobretitulo: widget.item == null ? null : 'Editar item'),
        corpo: [
          CampoFormulario(
            rotulo: 'Nome',
            campo: TextFormField(controller: _nome, validator: (v) => (v ?? '').trim().isEmpty ? 'Informe o nome' : null),
          ),
          Row(
            children: [
              Expanded(child: CampoFormulario(rotulo: 'Quantidade', campo: TextFormField(controller: _qtd, keyboardType: TextInputType.number, inputFormatters: numero, validator: obrigatorioNumero))),
              const SizedBox(width: 12),
              Expanded(child: CampoFormulario(rotulo: 'Estoque mínimo', campo: TextFormField(controller: _minimo, keyboardType: TextInputType.number, inputFormatters: numero, validator: obrigatorioNumero))),
            ],
          ),
          CampoFormulario(
            rotulo: 'Custo unitário (R\$)',
            campo: TextFormField(
              controller: _preco,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              decoration: const InputDecoration(hintText: '0,00'),
            ),
            ajuda: 'Usado para calcular o custo das peças nas ordens de serviço.',
          ),
        ],
        rodape: Row(
          children: [
            if (widget.item != null) ...[
              OutlinedButton(style: botaoSecundario(c, cor: c.vermelho), onPressed: _enviando ? null : _excluir, child: const Text('Excluir')),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: FilledButton(style: botaoDestaque(c), onPressed: _enviando ? null : _salvar, child: Text(widget.item == null ? 'Cadastrar item' : 'Salvar alterações')),
            ),
          ],
        ),
      ),
    );
  }
}
