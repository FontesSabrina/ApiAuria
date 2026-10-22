import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../acessibilidade/acessibilidade_controller.dart';
import 'app_theme.dart';
import 'auria_colors.dart';
import 'widgets.dart';

/// Distribui os filhos em colunas de largura igual (quantas couberem respeitando a largura mínima).
class GradeResponsiva extends StatelessWidget {
  final double larguraMinima;
  final double espaco;
  final int maxColunas;
  final List<Widget> children;

  const GradeResponsiva({super.key, required this.larguraMinima, required this.children, this.espaco = 16, this.maxColunas = 4});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final cabem = ((constraints.maxWidth + espaco) / (larguraMinima + espaco)).floor();
        final colunas = math.max(1, math.min(math.min(maxColunas, children.length), cabem));
        final largura = (constraints.maxWidth - espaco * (colunas - 1)) / colunas;
        return Wrap(
          spacing: espaco,
          runSpacing: espaco,
          children: [for (final filho in children) SizedBox(width: largura, child: filho)],
        );
      },
    );
  }
}

/// Chip de filtro (selecionado = fundo escuro).
class ChipFiltro extends StatelessWidget {
  final String texto;
  final bool selecionado;
  final VoidCallback onTap;

  const ChipFiltro({super.key, required this.texto, required this.selecionado, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return ChoiceChip(
      label: Text(texto),
      selected: selecionado,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selecionado ? c.superficie : c.texto),
      selectedColor: c.texto,
      backgroundColor: c.superficie,
      side: BorderSide(color: selecionado ? c.texto : c.borda),
      shape: const StadiumBorder(),
    );
  }
}

/// Rótulo pequeno em caixa alta (títulos de seção dentro de painéis).
class RotuloSecao extends StatelessWidget {
  final String texto;
  const RotuloSecao(this.texto, {super.key});

  @override
  Widget build(BuildContext context) => Semantics(
        header: true,
        label: texto,
        excludeSemantics: true,
        child: Text(
          texto.toUpperCase(),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1, color: context.cores.textoSecundario),
        ),
      );
}

/// Par "RÓTULO / valor" usado nos detalhes.
class Fato extends StatelessWidget {
  final String rotulo;
  final String valor;
  final bool numerico;
  const Fato({super.key, required this.rotulo, required this.valor, this.numerico = false});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return MergeSemantics(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(rotulo.toUpperCase(), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: c.textoSecundario)),
        const SizedBox(height: 4),
        Text(valor, style: numerico ? AppTheme.numero(tamanho: 14, cor: c.texto) : const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    ));
  }
}

/// Bloco de texto destacado (descrição de chamado, parecer técnico...).
class BlocoTexto extends StatelessWidget {
  final String texto;
  final bool secundario;
  const BlocoTexto(this.texto, {super.key, this.secundario = false});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: c.superficie2, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.borda)),
      child: Text(texto, style: TextStyle(fontSize: 14, height: 1.5, color: secundario ? c.textoSecundario : c.texto)),
    );
  }
}

/// Campo de formulário com rótulo acima (padrão dos painéis de cadastro).
///
/// Acessibilidade: o rótulo visível é ligado ao campo, então o leitor de tela diz
/// "Nome do ativo, campo de texto" em vez de ler só o campo vazio.
class CampoFormulario extends StatelessWidget {
  final String rotulo;
  final Widget campo;
  final String? ajuda;
  const CampoFormulario({super.key, required this.rotulo, required this.campo, this.ajuda});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final ehTexto = campo is TextField || campo is TextFormField || campo is DropdownButtonFormField;
    final conteudo = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(rotulo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        campo,
        if (ajuda != null) ...[
          const SizedBox(height: 4),
          Text(ajuda!, style: TextStyle(fontSize: 12, color: c.textoSecundario)),
        ],
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      // Campo de texto: junta rótulo + campo num só item. Grupo de opções: o rótulo vira o nome do grupo.
      child: ehTexto ? MergeSemantics(child: conteudo) : Semantics(container: true, label: rotulo, explicitChildNodes: true, child: conteudo),
    );
  }
}

/// Seletor em "pílulas" (substitui dropdowns curtos: prioridade, perfil, estado...).
class SeletorPilulas<T> extends StatelessWidget {
  final List<T> opcoes;
  final T? selecionado;
  final String Function(T) rotulo;
  final ValueChanged<T> onSelecionar;

  const SeletorPilulas({super.key, required this.opcoes, required this.selecionado, required this.rotulo, required this.onSelecionar});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in opcoes) ChipFiltro(texto: rotulo(o), selecionado: o == selecionado, onTap: () => onSelecionar(o)),
      ],
    );
  }
}

/// Abre um painel que desliza da direita (detalhes e formulários).
/// O [builder] recebe o contexto do painel; feche com `Navigator.pop(context, resultado)`.
Future<T?> mostrarPainelLateral<T>(BuildContext context, {required WidgetBuilder builder, double largura = 480}) {
  final parado = semAnimacao(context);
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fechar',
    barrierColor: const Color(0xFF0A0D26).withValues(alpha: 0.45),
    transitionDuration: parado ? Duration.zero : const Duration(milliseconds: 220),
    pageBuilder: (context, _, __) {
      final c = context.cores;
      final w = math.min(largura, MediaQuery.sizeOf(context).width);
      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: c.superficie,
          elevation: 16,
          // Painel = diálogo: o leitor de tela fica preso aqui dentro até fechar (Esc também fecha).
          child: Semantics(
            scopesRoute: true,
            namesRoute: true,
            explicitChildNodes: true,
            label: 'Painel',
            child: SizedBox(width: w, height: double.infinity, child: SafeArea(child: Builder(builder: builder))),
          ),
        ),
      );
    },
    transitionBuilder: (context, animacao, _, child) => SlideTransition(
      position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: animacao, curve: Curves.easeOutCubic)),
      child: child,
    ),
  );
}

/// Estrutura padrão de um painel lateral: cabeçalho, corpo rolável e rodapé com ações.
class EstruturaPainel extends StatelessWidget {
  final Widget cabecalho;
  final List<Widget> corpo;
  final Widget? rodape;

  const EstruturaPainel({super.key, required this.cabecalho, required this.corpo, this.rodape});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 22, 14, 18),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.borda))),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cabecalho),
              IconButton(tooltip: 'Fechar', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
            ],
          ),
        ),
        Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(24, 20, 24, 24), children: corpo)),
        if (rodape != null)
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: c.borda))),
            child: rodape,
          ),
      ],
    );
  }
}

/// Título padrão do cabeçalho de um painel lateral.
class TituloPainel extends StatelessWidget {
  final String titulo;
  final String? sobretitulo;
  final List<Widget> etiquetas;
  const TituloPainel({super.key, required this.titulo, this.sobretitulo, this.etiquetas = const []});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (etiquetas.isNotEmpty) ...[
          Wrap(spacing: 8, runSpacing: 8, children: etiquetas),
          const SizedBox(height: 10),
        ],
        if (sobretitulo != null) ...[
          Text(sobretitulo!, style: AppTheme.numero(tamanho: 12, cor: c.textoSecundario, peso: FontWeight.w500)),
          const SizedBox(height: 4),
        ],
        Semantics(header: true, child: Text(titulo, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800))),
      ],
    );
  }
}

/// Executa uma ação assíncrona mostrando o toast de sucesso ou o erro da API.
/// Devolve true se deu certo.
Future<bool> executarComAviso(BuildContext context, Future<void> Function() acao, String mensagemSucesso) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await acao();
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(snackAuria(mensagemSucesso));
    return true;
  } catch (e) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(snackAuria('$e', erro: true));
    return false;
  }
}

/// Confirmação simples (excluir, cancelar...).
Future<bool> confirmar(BuildContext context, {required String titulo, required String mensagem, String acao = 'Confirmar', bool perigosa = false}) async {
  final c = context.cores;
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: c.superficie,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w800)),
      content: Text(mensagem, style: TextStyle(color: c.textoSecundario, height: 1.4)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Voltar')),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: perigosa ? const Color(0xFFB42318) : c.destaque,
            foregroundColor: perigosa ? Colors.white : c.sobreDestaque,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(acao),
        ),
      ],
    ),
  );
  return r == true;
}
