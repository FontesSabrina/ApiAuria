import 'package:flutter/material.dart';

import '../../core/ui/app_theme.dart';
import '../../core/ui/auria_colors.dart';
import '../../core/ui/botoes.dart';
import '../../core/ui/layout.dart';
import '../../core/ui/widgets.dart';
import '../../domain/entities/chamado.dart';
import '../../domain/entities/usuario.dart';
import '../shell/app_dados.dart';

String nomeTipo(TipoManutencao tipo) => switch (tipo) {
      TipoManutencao.corretiva => 'Corretiva',
      TipoManutencao.preventiva => 'Preventiva',
      TipoManutencao.preditiva => 'Preditiva',
    };

/// Quadro de chamados por status (kanban). Clicar num card abre o painel lateral
/// com os detalhes; o Admin escolhe o técnico e aprova ou cancela ali mesmo.
class ChamadosKanbanView extends StatefulWidget {
  final AppDados dados;
  const ChamadosKanbanView({super.key, required this.dados});

  @override
  State<ChamadosKanbanView> createState() => _ChamadosKanbanViewState();
}

class _ChamadosKanbanViewState extends State<ChamadosKanbanView> {
  String _prioridade = 'Todas';

  bool _passa(Chamado ch) {
    final prioridadeOk = _prioridade == 'Todas' || PilulaPrioridade.peso(ch.prioridade) == PilulaPrioridade.peso(_prioridade);
    return prioridadeOk && widget.dados.passaNaBusca('${ch.ativo.nome} ${ch.descricaoFalha} ${ch.ativo.ambienteNome ?? ''} ${ch.id}');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text('Prioridade', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.textoSecundario)),
            ),
            for (final p in const ['Todas', 'Alta', 'Média', 'Baixa'])
              ChipFiltro(texto: p, selecionado: _prioridade == p, onTap: () => setState(() => _prioridade = p)),
            const SizedBox(width: 8),
            Text(
              widget.dados.ehAdmin ? 'Clique num card para ver os detalhes e aprovar' : 'Clique num card para ver os detalhes',
              style: TextStyle(fontSize: 13, color: c.textoSecundario),
            ),
          ],
        ),
        const SizedBox(height: 18),
        GradeResponsiva(
          larguraMinima: 250,
          children: [
            for (final status in StatusChamado.values)
              _Coluna(
                status: status,
                chamados: widget.dados.chamados.where((ch) => ch.status == status && _passa(ch)).toList()
                  ..sort((a, b) => PilulaPrioridade.peso(a.prioridade).compareTo(PilulaPrioridade.peso(b.prioridade))),
                dados: widget.dados,
              ),
          ],
        ),
      ],
    );
  }
}

class _Coluna extends StatelessWidget {
  final StatusChamado status;
  final List<Chamado> chamados;
  final AppDados dados;
  const _Coluna({required this.status, required this.chamados, required this.dados});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final estilo = EstiloStatus.de(context, status);
    return Container(
      constraints: const BoxConstraints(minHeight: 200),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: c.superficie2, borderRadius: BorderRadius.circular(18), border: Border.all(color: c.borda)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
            child: Row(
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: estilo.ponto, shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Expanded(child: Text(estilo.rotulo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                  decoration: BoxDecoration(color: c.superficie, borderRadius: BorderRadius.circular(999), border: Border.all(color: c.borda)),
                  child: Text('${chamados.length}', style: AppTheme.numero(tamanho: 12, cor: c.textoSecundario)),
                ),
              ],
            ),
          ),
          if (chamados.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text('Nenhum chamado aqui.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: c.textoSecundario)),
            ),
          for (final ch in chamados)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CardChamado(chamado: ch, onTap: () => abrirDetalheChamado(context, dados, ch)),
            ),
        ],
      ),
    );
  }
}

/// Card de chamado (usado no kanban e em "Meus chamados").
class CardChamado extends StatelessWidget {
  final Chamado chamado;
  final VoidCallback onTap;
  final bool mostrarStatus;
  const CardChamado({super.key, required this.chamado, required this.onTap, this.mostrarStatus = false});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final tecnico = chamado.status != StatusChamado.aberto ? chamado.tecnicoResponsavel : null;
    final pessoa = tecnico?.nome ?? chamado.solicitante.nome;

    return HoverCard(
      onTap: onTap,
      semantica: 'Chamado ${chamado.id}: ${chamado.ativo.nome}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Wrap(spacing: 6, runSpacing: 6, children: [
                  if (mostrarStatus) PilulaStatus(status: chamado.status),
                  PilulaPrioridade(prioridade: chamado.prioridade),
                  Pilula(texto: nomeTipo(chamado.tipo), cor: c.cinza, fundo: c.cinzaFundo, comPonto: false),
                ]),
              ),
              const SizedBox(width: 8),
              Text('#${chamado.id}', style: AppTheme.numero(tamanho: 12, cor: c.textoSecundario, peso: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 10),
          Text(chamado.ativo.nome, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, height: 1.3)),
          const SizedBox(height: 2),
          Text(chamado.descricaoFalha, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: c.textoSecundario, height: 1.4)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: c.borda))),
            child: Row(
              children: [
                AvatarIniciais(nome: pessoa, cor: tecnico != null ? c.laranja : c.azul, fundo: tecnico != null ? c.laranjaFundo : c.azulFundo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(tecnico != null ? 'Técnico: $pessoa' : 'Solicitante: $pessoa',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: c.textoSecundario)),
                ),
                Icon(Icons.schedule_rounded, size: 13, color: c.textoSecundario),
                const SizedBox(width: 4),
                Text(tempoDecorrido(chamado.dataAbertura), style: TextStyle(fontSize: 12, color: c.textoSecundario)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Abre o painel lateral de um chamado (kanban, painel do Admin e "Meus chamados").
Future<void> abrirDetalheChamado(BuildContext context, AppDados dados, Chamado chamado) =>
    mostrarPainelLateral(context, largura: 460, builder: (_) => _PainelChamado(chamado: chamado, dados: dados));

class _PainelChamado extends StatefulWidget {
  final Chamado chamado;
  final AppDados dados;
  const _PainelChamado({required this.chamado, required this.dados});

  @override
  State<_PainelChamado> createState() => _PainelChamadoState();
}

class _PainelChamadoState extends State<_PainelChamado> {
  Usuario? _tecnico;
  bool _enviando = false;

  Future<void> _executar(Future<void> Function() acao, String sucesso) async {
    setState(() => _enviando = true);
    final ok = await executarComAviso(context, acao, sucesso);
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
    final ch = widget.chamado;
    final d = widget.dados;
    final aberto = ch.status == StatusChamado.aberto;
    final podeAprovar = aberto && d.ehAdmin;
    final podeCancelar = aberto && (d.ehAdmin || ch.solicitante.id == d.usuario.id);

    return EstruturaPainel(
      cabecalho: TituloPainel(
        titulo: ch.ativo.nome,
        sobretitulo: 'Chamado #${ch.id} · ${nomeTipo(ch.tipo)}',
        etiquetas: [PilulaStatus(status: ch.status), PilulaPrioridade(prioridade: ch.prioridade, prefixo: 'Prioridade ')],
      ),
      corpo: [
        BlocoTexto('“${ch.descricaoFalha}”'),
        const SizedBox(height: 20),
        GradeResponsiva(
          larguraMinima: 160,
          espaco: 14,
          maxColunas: 2,
          children: [
            Fato(rotulo: 'Local', valor: ch.ativo.ambienteNome ?? '—'),
            Fato(rotulo: 'Aberto', valor: tempoDecorrido(ch.dataAbertura)),
            Fato(rotulo: 'Solicitante', valor: ch.solicitante.nome),
            Fato(rotulo: 'Técnico', valor: ch.tecnicoResponsavel?.nome ?? 'Ainda não designado'),
          ],
        ),
        const SizedBox(height: 24),
        LinhaDoTempoChamado(status: ch.status),
        const SizedBox(height: 24),
        if (podeAprovar) ...[
          const RotuloSecao('Designar técnico'),
          const SizedBox(height: 10),
          if (d.tecnicos.isEmpty) Text('Nenhum técnico cadastrado. Cadastre um em Usuários.', style: TextStyle(color: c.textoSecundario)),
          for (final t in d.tecnicos)
            _OpcaoTecnico(tecnico: t, carga: d.cargaDoTecnico(t), selecionado: _tecnico?.id == t.id, onTap: () => setState(() => _tecnico = t)),
        ] else if (aberto)
          BlocoTexto('Aguardando o administrador aprovar e designar um técnico.', secundario: true),
      ],
      rodape: !(podeAprovar || podeCancelar)
          ? null
          : Row(
              children: [
                if (podeAprovar)
                  Expanded(
                    child: FilledButton.icon(
                      style: botaoDestaque(c),
                      onPressed: _tecnico == null || _enviando
                          ? null
                          : () => _executar(() => d.aprovar(ch, _tecnico!), 'Chamado #${ch.id} aprovado e enviado para ${_tecnico!.nome}'),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Aprovar e designar'),
                    ),
                  ),
                if (podeAprovar && podeCancelar) const SizedBox(width: 10),
                if (podeCancelar)
                  OutlinedButton(
                    style: botaoSecundario(c, cor: c.vermelho),
                    onPressed: _enviando
                        ? null
                        : () async {
                            final ok = await confirmar(context,
                                titulo: 'Cancelar chamado #${ch.id}?',
                                mensagem: 'O chamado sai da fila de aprovação. Essa ação não pode ser desfeita.',
                                acao: 'Cancelar chamado',
                                perigosa: true);
                            if (ok && mounted) _executar(() => d.cancelar(ch), 'Chamado #${ch.id} cancelado');
                          },
                    child: const Text('Cancelar chamado'),
                  ),
              ],
            ),
    );
  }
}

/// Etapas do chamado: Aberto → Em execução → Concluído (ou Cancelado).
class LinhaDoTempoChamado extends StatelessWidget {
  final StatusChamado status;
  const LinhaDoTempoChamado({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    if (status == StatusChamado.cancelado) {
      return Row(children: [
        Icon(Icons.cancel_outlined, color: c.cinza, size: 20),
        const SizedBox(width: 8),
        Text('Chamado cancelado', style: TextStyle(fontWeight: FontWeight.w700, color: c.cinza)),
      ]);
    }
    const etapas = ['Aberto', 'Em execução', 'Concluído'];
    final atual = switch (status) {
      StatusChamado.aberto => 0,
      StatusChamado.emExecucao => 1,
      _ => 2,
    };
    return Row(
      children: [
        for (var i = 0; i < etapas.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(height: 3, margin: const EdgeInsets.symmetric(horizontal: 6), color: i <= atual ? AuriaColors.pontoConcluido : c.borda),
            ),
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i <= atual ? AuriaColors.pontoConcluido : c.superficie,
                  border: Border.all(color: i <= atual ? AuriaColors.pontoConcluido : c.borda, width: 2),
                ),
                child: i <= atual ? const Icon(Icons.check_rounded, size: 15, color: Colors.white) : null,
              ),
              const SizedBox(height: 6),
              Text(etapas[i], style: TextStyle(fontSize: 12, fontWeight: i == atual ? FontWeight.w800 : FontWeight.w500, color: i <= atual ? c.texto : c.textoSecundario)),
            ],
          ),
        ],
      ],
    );
  }
}

class _OpcaoTecnico extends StatelessWidget {
  final Usuario tecnico;
  final int carga;
  final bool selecionado;
  final VoidCallback onTap;
  const _OpcaoTecnico({required this.tecnico, required this.carga, required this.selecionado, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selecionado ? c.azulFundo : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: selecionado ? c.azul : c.borda, width: 1.5)),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Semantics(
            selected: selecionado,
            button: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  AvatarIniciais(nome: tecnico.nome, tamanho: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tecnico.nome, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        Text(carga == 0 ? 'Livre agora' : '$carga ${carga == 1 ? 'manutenção em andamento' : 'manutenções em andamento'}',
                            style: TextStyle(fontSize: 12, color: c.textoSecundario)),
                      ],
                    ),
                  ),
                  Icon(selecionado ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded, color: selecionado ? c.azul : c.textoSecundario),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
