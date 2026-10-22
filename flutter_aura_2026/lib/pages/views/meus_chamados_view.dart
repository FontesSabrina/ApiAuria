import 'package:flutter/material.dart';

import '../../core/ui/auria_colors.dart';
import '../../core/ui/botoes.dart';
import '../../core/ui/layout.dart';
import '../../core/ui/widgets.dart';
import '../../domain/entities/chamado.dart';
import '../shell/app_dados.dart';
import '../shell/auria_shell.dart';
import 'chamados_kanban_view.dart';

/// Chamados abertos pelo usuário logado, com filtro por status.
class MeusChamadosView extends StatefulWidget {
  final AppDados dados;
  final ValueChanged<Secao> onIrPara;
  const MeusChamadosView({super.key, required this.dados, required this.onIrPara});

  @override
  State<MeusChamadosView> createState() => _MeusChamadosViewState();
}

class _MeusChamadosViewState extends State<MeusChamadosView> {
  StatusChamado? _status;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final d = widget.dados;
    final lista = d.chamados
        .where((ch) => _status == null || ch.status == _status)
        .where((ch) => d.passaNaBusca('${ch.ativo.nome} ${ch.descricaoFalha} ${ch.id}'))
        .toList()
      ..sort((a, b) => b.dataAbertura.compareTo(a.dataAbertura));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ChipFiltro(texto: 'Todos (${d.chamados.length})', selecionado: _status == null, onTap: () => setState(() => _status = null)),
            for (final s in StatusChamado.values)
              ChipFiltro(
                texto: '${EstiloStatus.de(context, s).rotulo} (${d.contar(s)})',
                selecionado: _status == s,
                onTap: () => setState(() => _status = s),
              ),
            const SizedBox(width: 12),
            FilledButton.icon(
              style: botaoDestaque(c),
              onPressed: () => widget.onIrPara(Secao.abrirChamado),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Abrir chamado'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (lista.isEmpty)
          AuriaCard(
            child: EstadoVazio(
              mensagem: d.chamados.isEmpty ? 'Você ainda não abriu nenhum chamado.' : 'Nenhum chamado com esse filtro.',
              icone: Icons.confirmation_number_outlined,
            ),
          )
        else
          GradeResponsiva(
            larguraMinima: 300,
            maxColunas: 3,
            children: [
              for (final ch in lista) CardChamado(chamado: ch, mostrarStatus: true, onTap: () => abrirDetalheChamado(context, d, ch)),
            ],
          ),
      ],
    );
  }
}
