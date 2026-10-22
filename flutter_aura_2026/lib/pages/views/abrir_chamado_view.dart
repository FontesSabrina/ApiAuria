import 'package:flutter/material.dart';

import '../../core/ui/auria_colors.dart';
import '../../core/ui/botoes.dart';
import '../../core/ui/layout.dart';
import '../../core/ui/widgets.dart';
import '../../domain/entities/ativo.dart';
import '../../domain/entities/chamado.dart';
import '../shell/app_dados.dart';
import '../shell/auria_shell.dart';
import 'chamados_kanban_view.dart';

/// Formulário para abrir um chamado, em etapas visuais: o quê, onde e quão urgente.
class AbrirChamadoView extends StatefulWidget {
  final AppDados dados;
  final ValueChanged<Secao> onIrPara;
  const AbrirChamadoView({super.key, required this.dados, required this.onIrPara});

  @override
  State<AbrirChamadoView> createState() => _AbrirChamadoViewState();
}

class _AbrirChamadoViewState extends State<AbrirChamadoView> {
  final _form = GlobalKey<FormState>();
  final _descricao = TextEditingController();
  final _buscaAtivo = TextEditingController();
  Ativo? _ativo;
  String _prioridade = 'Média';
  TipoManutencao _tipo = TipoManutencao.corretiva;
  bool _enviando = false;

  static const _prioridades = {
    'Baixa': 'Pode esperar alguns dias',
    'Média': 'Atrapalha o uso, mas não impede',
    'Alta': 'Impede o uso ou oferece risco',
  };

  @override
  void dispose() {
    _descricao.dispose();
    _buscaAtivo.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_ativo == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escolha o equipamento com problema.')));
      return;
    }
    if (!_form.currentState!.validate()) return;
    setState(() => _enviando = true);
    final chamado = Chamado(
      id: '',
      ativo: _ativo!,
      solicitante: widget.dados.usuario,
      descricaoFalha: _descricao.text.trim(),
      prioridade: _prioridade,
      tipo: _tipo,
      status: StatusChamado.aberto,
      dataAbertura: DateTime.now(),
    );
    final ok = await executarComAviso(context, () => widget.dados.abrirChamado(chamado), 'Chamado aberto! A equipe de manutenção foi avisada.');
    if (!mounted) return;
    setState(() => _enviando = false);
    if (ok) widget.onIrPara(widget.dados.ehSolicitante ? Secao.meusChamados : Secao.chamados);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final termo = _buscaAtivo.text.trim().toLowerCase();
    final ativos = widget.dados.ativos
        .where((a) => a.estadoConservacao != 'Desativado')
        .where((a) => termo.isEmpty || '${a.nome} ${a.ambienteNome ?? ''} ${a.patrimonio}'.toLowerCase().contains(termo))
        .toList()
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Etapa(
                numero: 1,
                titulo: 'Qual equipamento está com problema?',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _buscaAtivo,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(hintText: 'Buscar pelo nome, local ou patrimônio', prefixIcon: Icon(Icons.search_rounded, color: c.textoSecundario)),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 260),
                      child: ativos.isEmpty
                          ? const EstadoVazio(mensagem: 'Nenhum equipamento encontrado.', icone: Icons.devices_other_outlined)
                          : ListView(
                              shrinkWrap: true,
                              children: [
                                for (final a in ativos)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    // "selected" informa ao leitor de tela qual equipamento está escolhido.
                                    child: Semantics(
                                      selected: _ativo?.id == a.id,
                                      inMutuallyExclusiveGroup: true,
                                      child: Material(
                                      color: _ativo?.id == a.id ? c.azulFundo : c.superficie2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(color: _ativo?.id == a.id ? c.azul : c.borda, width: 1.5),
                                      ),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () => setState(() => _ativo = a),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          child: Row(
                                            children: [
                                              Icon(Icons.devices_other_outlined, color: _ativo?.id == a.id ? c.azul : c.textoSecundario),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(a.nome, style: const TextStyle(fontWeight: FontWeight.w700)),
                                                    Text(a.ambienteNome ?? '—', style: TextStyle(fontSize: 12.5, color: c.textoSecundario)),
                                                  ],
                                                ),
                                              ),
                                              if (_ativo?.id == a.id) Icon(Icons.check_circle_rounded, color: c.azul),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  )),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Etapa(
                numero: 2,
                titulo: 'O que está acontecendo?',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _descricao,
                      maxLines: 4,
                      decoration: const InputDecoration(hintText: 'Ex.: o ar-condicionado está pingando água sobre a bancada desde ontem.'),
                      validator: (v) => (v ?? '').trim().length < 5 ? 'Descreva o problema (mínimo 5 letras)' : null,
                    ),
                    const SizedBox(height: 14),
                    const RotuloSecao('Tipo de manutenção'),
                    const SizedBox(height: 8),
                    SeletorPilulas<TipoManutencao>(opcoes: TipoManutencao.values, selecionado: _tipo, rotulo: nomeTipo, onSelecionar: (t) => setState(() => _tipo = t)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Etapa(
                numero: 3,
                titulo: 'Qual a urgência?',
                child: GradeResponsiva(
                  larguraMinima: 180,
                  espaco: 10,
                  maxColunas: 3,
                  children: [
                    for (final p in _prioridades.entries)
                      Semantics(
                        selected: _prioridade == p.key,
                        inMutuallyExclusiveGroup: true,
                        label: 'Prioridade',
                        child: Material(
                        color: _prioridade == p.key ? c.azulFundo : c.superficie2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: _prioridade == p.key ? c.azul : c.borda, width: 1.5),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => setState(() => _prioridade = p.key),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                PilulaPrioridade(prioridade: p.key),
                                const SizedBox(height: 8),
                                Text(p.value, style: TextStyle(fontSize: 12.5, color: c.textoSecundario, height: 1.35)),
                              ],
                            ),
                          ),
                        ),
                      )),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  style: botaoDestaque(c),
                  onPressed: _enviando ? null : _enviar,
                  icon: _enviando
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, semanticsLabel: 'Enviando'))
                      : const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Enviar chamado'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Etapa extends StatelessWidget {
  final int numero;
  final String titulo;
  final Widget child;
  const _Etapa({required this.numero, required this.titulo, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return AuriaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.destaque, shape: BoxShape.circle),
                child: Text('$numero', style: TextStyle(fontWeight: FontWeight.w800, color: c.sobreDestaque)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
