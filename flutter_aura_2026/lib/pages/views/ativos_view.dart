import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/ui/app_theme.dart';
import '../../core/ui/auria_colors.dart';
import '../../core/ui/botoes.dart';
import '../../core/ui/layout.dart';
import '../../core/ui/widgets.dart';
import '../../domain/entities/ambiente.dart';
import '../../domain/entities/ativo.dart';
import '../shell/app_dados.dart';

const estadosConservacao = ['Novo', 'Bom', 'Regular', 'Ruim', 'Em Manutenção', 'Desativado'];

/// Pílula colorida do estado de conservação de um ativo.
class PilulaEstado extends StatelessWidget {
  final String estado;
  const PilulaEstado({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final (cor, fundo) = switch (estado) {
      'Novo' || 'Bom' => (c.verde, c.verdeFundo),
      'Regular' => (c.ambar, c.ambarFundo),
      'Ruim' => (c.vermelho, c.vermelhoFundo),
      'Em Manutenção' => (c.laranja, c.laranjaFundo),
      _ => (c.cinza, c.cinzaFundo),
    };
    return Pilula(texto: estado.isEmpty ? '—' : estado, cor: cor, fundo: fundo);
  }
}

String dataCurta(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

class AtivosView extends StatefulWidget {
  final AppDados dados;
  const AtivosView({super.key, required this.dados});

  @override
  State<AtivosView> createState() => _AtivosViewState();
}

class _AtivosViewState extends State<AtivosView> {
  String _estado = 'Todos';

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final d = widget.dados;
    final lista = d.ativos
        .where((a) => _estado == 'Todos' || a.estadoConservacao == _estado)
        .where((a) => d.passaNaBusca('${a.nome} ${a.patrimonio} ${a.ambienteNome ?? ''}'))
        .toList()
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ChipFiltro(texto: 'Todos (${d.ativos.length})', selecionado: _estado == 'Todos', onTap: () => setState(() => _estado = 'Todos')),
            for (final e in estadosConservacao)
              if (d.ativos.any((a) => a.estadoConservacao == e))
                ChipFiltro(texto: e, selecionado: _estado == e, onTap: () => setState(() => _estado = e)),
            const SizedBox(width: 12),
            FilledButton.icon(
              style: botaoDestaque(c),
              onPressed: () => abrirFormularioAtivo(context, d),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Novo ativo'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (lista.isEmpty)
          const AuriaCard(child: EstadoVazio(mensagem: 'Nenhum ativo encontrado.', icone: Icons.devices_other_outlined))
        else
          GradeResponsiva(
            larguraMinima: 260,
            children: [
              for (final a in lista)
                HoverCard(
                  onTap: () => abrirFormularioAtivo(context, d, ativo: a),
                  semantica: 'Ativo ${a.nome}',
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(color: c.azulFundo, borderRadius: BorderRadius.circular(12)),
                            child: Icon(Icons.devices_other_outlined, color: c.azul, size: 20),
                          ),
                          const Spacer(),
                          PilulaEstado(estado: a.estadoConservacao),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(a.nome, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text('Patrimônio ${a.patrimonio}', style: AppTheme.numero(tamanho: 12, cor: c.textoSecundario, peso: FontWeight.w500)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.place_outlined, size: 15, color: c.textoSecundario),
                          const SizedBox(width: 4),
                          Expanded(child: Text(a.ambienteNome ?? '—', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: c.textoSecundario))),
                          Text('desde ${dataCurta(a.dataAquisicao)}', style: TextStyle(fontSize: 12, color: c.textoSecundario)),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

Future<void> abrirFormularioAtivo(BuildContext context, AppDados dados, {Ativo? ativo}) =>
    mostrarPainelLateral(context, builder: (_) => _FormularioAtivo(dados: dados, ativo: ativo));

class _FormularioAtivo extends StatefulWidget {
  final AppDados dados;
  final Ativo? ativo;
  const _FormularioAtivo({required this.dados, this.ativo});

  @override
  State<_FormularioAtivo> createState() => _FormularioAtivoState();
}

class _FormularioAtivoState extends State<_FormularioAtivo> {
  final _form = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.ativo?.nome ?? '');
  late final _patrimonio = TextEditingController(text: widget.ativo?.patrimonio ?? '');
  late String? _ambienteId = widget.ativo?.ambienteId;
  late String _estado = estadosConservacao.contains(widget.ativo?.estadoConservacao) ? widget.ativo!.estadoConservacao : 'Novo';
  late DateTime _aquisicao = widget.ativo?.dataAquisicao ?? DateTime.now();
  bool _enviando = false;

  @override
  void dispose() {
    _nome.dispose();
    _patrimonio.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final d = await showDatePicker(context: context, initialDate: _aquisicao, firstDate: DateTime(1990), lastDate: DateTime.now());
    if (d != null) setState(() => _aquisicao = d);
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _enviando = true);
    final ativo = Ativo(
      id: widget.ativo?.id ?? const Uuid().v4(),
      patrimonio: _patrimonio.text.trim(),
      nome: _nome.text.trim(),
      ambienteId: _ambienteId!,
      estadoConservacao: _estado,
      dataAquisicao: _aquisicao,
    );
    final ok = await executarComAviso(context, () => widget.dados.salvarAtivo(ativo), widget.ativo == null ? 'Ativo cadastrado!' : 'Ativo atualizado!');
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _enviando = false);
    }
  }

  Future<void> _excluir() async {
    final a = widget.ativo!;
    final ok = await confirmar(context,
        titulo: 'Excluir ${a.nome}?', mensagem: 'Ativos com chamados não podem ser excluídos — nesse caso, mude o estado para "Desativado".', acao: 'Excluir', perigosa: true);
    if (!ok || !mounted) return;
    if (await executarComAviso(context, () => widget.dados.excluirAtivo(a), 'Ativo excluído') && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final ambientes = widget.dados.ambientes;
    final ambienteValido = ambientes.any((a) => a.id == _ambienteId) ? _ambienteId : null;

    return Form(
      key: _form,
      child: EstruturaPainel(
        cabecalho: TituloPainel(
          titulo: widget.ativo == null ? 'Novo ativo' : widget.ativo!.nome,
          sobretitulo: widget.ativo == null ? null : 'Editar ativo',
          etiquetas: widget.ativo == null ? const [] : [PilulaEstado(estado: widget.ativo!.estadoConservacao)],
        ),
        corpo: [
          CampoFormulario(rotulo: 'Nome do equipamento', campo: TextFormField(controller: _nome, validator: (v) => (v ?? '').trim().isEmpty ? 'Informe o nome' : null)),
          CampoFormulario(rotulo: 'Número de patrimônio', campo: TextFormField(controller: _patrimonio, validator: (v) => (v ?? '').trim().isEmpty ? 'Informe o patrimônio' : null)),
          CampoFormulario(
            rotulo: 'Ambiente',
            ajuda: ambientes.isEmpty ? 'Cadastre um ambiente antes, na seção Ambientes.' : null,
            campo: DropdownButtonFormField<String>(
              initialValue: ambienteValido,
              isExpanded: true,
              items: [
                for (final Ambiente a in ambientes)
                  DropdownMenuItem(value: a.id, child: Text([a.nome, if (a.predio.isNotEmpty) a.predio].join(' · '), overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => setState(() => _ambienteId = v),
              validator: (v) => v == null ? 'Escolha o ambiente' : null,
            ),
          ),
          CampoFormulario(
            rotulo: 'Estado de conservação',
            campo: SeletorPilulas<String>(opcoes: estadosConservacao, selecionado: _estado, rotulo: (e) => e, onSelecionar: (e) => setState(() => _estado = e)),
          ),
          CampoFormulario(
            rotulo: 'Data de aquisição',
            campo: OutlinedButton.icon(
              style: botaoSecundario(c).copyWith(alignment: Alignment.centerLeft),
              onPressed: _escolherData,
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: Text(dataCurta(_aquisicao)),
            ),
          ),
        ],
        rodape: Row(
          children: [
            if (widget.ativo != null) ...[
              OutlinedButton(style: botaoSecundario(c, cor: c.vermelho), onPressed: _enviando ? null : _excluir, child: const Text('Excluir')),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: FilledButton(
                style: botaoDestaque(c),
                onPressed: _enviando || ambientes.isEmpty ? null : _salvar,
                child: Text(widget.ativo == null ? 'Cadastrar ativo' : 'Salvar alterações'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
