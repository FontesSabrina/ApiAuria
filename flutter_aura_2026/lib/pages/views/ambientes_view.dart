import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/ui/auria_colors.dart';
import '../../core/ui/botoes.dart';
import '../../core/ui/layout.dart';
import '../../core/ui/widgets.dart';
import '../../domain/entities/ambiente.dart';
import '../shell/app_dados.dart';

class AmbientesView extends StatelessWidget {
  final AppDados dados;
  const AmbientesView({super.key, required this.dados});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final lista = dados.ambientes
        .where((a) => dados.passaNaBusca('${a.nome} ${a.predio} ${a.andar} ${a.observacoes}'))
        .toList()
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('${dados.ambientes.length} ambientes cadastrados', style: TextStyle(fontSize: 13, color: c.textoSecundario))),
            FilledButton.icon(
              style: botaoDestaque(c),
              onPressed: () => abrirFormularioAmbiente(context, dados),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Novo ambiente'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (lista.isEmpty)
          const AuriaCard(child: EstadoVazio(mensagem: 'Nenhum ambiente encontrado.', icone: Icons.apartment_outlined))
        else
          GradeResponsiva(
            larguraMinima: 260,
            children: [
              for (final a in lista)
                HoverCard(
                  onTap: () => abrirFormularioAmbiente(context, dados, ambiente: a),
                  semantica: 'Ambiente ${a.nome}',
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(color: c.ambarFundo, borderRadius: BorderRadius.circular(12)),
                            child: Icon(Icons.apartment_outlined, color: c.ambar, size: 20),
                          ),
                          const Spacer(),
                          Pilula(
                            texto: '${dados.ativosNoAmbiente(a)} ${dados.ativosNoAmbiente(a) == 1 ? 'ativo' : 'ativos'}',
                            cor: c.azul,
                            fundo: c.azulFundo,
                            comPonto: false,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(a.nome, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(
                        [if (a.predio.isNotEmpty) a.predio, if (a.andar.isNotEmpty) 'Andar ${a.andar}'].join(' · ').ifEmpty('Sem prédio/andar informado'),
                        style: TextStyle(fontSize: 12.5, color: c.textoSecundario),
                      ),
                      if (a.observacoes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(a.observacoes, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: c.textoSecundario, height: 1.4)),
                      ],
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

extension _TextoVazio on String {
  String ifEmpty(String alternativa) => isEmpty ? alternativa : this;
}

Future<void> abrirFormularioAmbiente(BuildContext context, AppDados dados, {Ambiente? ambiente}) =>
    mostrarPainelLateral(context, builder: (_) => _FormularioAmbiente(dados: dados, ambiente: ambiente));

class _FormularioAmbiente extends StatefulWidget {
  final AppDados dados;
  final Ambiente? ambiente;
  const _FormularioAmbiente({required this.dados, this.ambiente});

  @override
  State<_FormularioAmbiente> createState() => _FormularioAmbienteState();
}

class _FormularioAmbienteState extends State<_FormularioAmbiente> {
  final _form = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.ambiente?.nome ?? '');
  late final _predio = TextEditingController(text: widget.ambiente?.predio ?? '');
  late final _andar = TextEditingController(text: widget.ambiente?.andar ?? '');
  late final _obs = TextEditingController(text: widget.ambiente?.observacoes ?? '');
  bool _enviando = false;

  @override
  void dispose() {
    _nome.dispose();
    _predio.dispose();
    _andar.dispose();
    _obs.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _enviando = true);
    final ambiente = Ambiente(
      id: widget.ambiente?.id ?? const Uuid().v4(),
      nome: _nome.text.trim(),
      predio: _predio.text.trim(),
      andar: _andar.text.trim(),
      observacoes: _obs.text.trim(),
    );
    final ok = await executarComAviso(context, () => widget.dados.salvarAmbiente(ambiente), widget.ambiente == null ? 'Ambiente cadastrado!' : 'Ambiente atualizado!');
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _enviando = false);
    }
  }

  Future<void> _excluir() async {
    final a = widget.ambiente!;
    final ok = await confirmar(context, titulo: 'Excluir ${a.nome}?', mensagem: 'Ambientes com ativos vinculados não podem ser excluídos.', acao: 'Excluir', perigosa: true);
    if (!ok || !mounted) return;
    if (await executarComAviso(context, () => widget.dados.excluirAmbiente(a), 'Ambiente excluído') && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Form(
      key: _form,
      child: EstruturaPainel(
        cabecalho: TituloPainel(titulo: widget.ambiente == null ? 'Novo ambiente' : widget.ambiente!.nome, sobretitulo: widget.ambiente == null ? null : 'Editar ambiente'),
        corpo: [
          CampoFormulario(
            rotulo: 'Identificação',
            campo: TextFormField(controller: _nome, decoration: const InputDecoration(hintText: 'Ex.: Sala 101'), validator: (v) => (v ?? '').trim().isEmpty ? 'Informe a identificação' : null),
          ),
          Row(
            children: [
              Expanded(child: CampoFormulario(rotulo: 'Prédio / bloco', campo: TextFormField(controller: _predio, decoration: const InputDecoration(hintText: 'Ex.: Bloco A')))),
              const SizedBox(width: 12),
              Expanded(child: CampoFormulario(rotulo: 'Andar', campo: TextFormField(controller: _andar, decoration: const InputDecoration(hintText: 'Ex.: 1º')))),
            ],
          ),
          CampoFormulario(rotulo: 'Observações', campo: TextFormField(controller: _obs, maxLines: 3)),
          if (widget.ambiente != null)
            BlocoTexto('${widget.dados.ativosNoAmbiente(widget.ambiente!)} ativo(s) instalados neste ambiente.', secundario: true),
        ],
        rodape: Row(
          children: [
            if (widget.ambiente != null) ...[
              OutlinedButton(style: botaoSecundario(c, cor: c.vermelho), onPressed: _enviando ? null : _excluir, child: const Text('Excluir')),
              const SizedBox(width: 10),
            ],
            Expanded(child: FilledButton(style: botaoDestaque(c), onPressed: _enviando ? null : _salvar, child: Text(widget.ambiente == null ? 'Cadastrar ambiente' : 'Salvar alterações'))),
          ],
        ),
      ),
    );
  }
}
