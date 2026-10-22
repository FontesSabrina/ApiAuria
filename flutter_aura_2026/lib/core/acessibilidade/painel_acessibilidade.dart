import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../theme/theme_controller.dart';
import '../ui/auria_colors.dart';
import '../ui/botoes.dart';
import '../ui/layout.dart';
import '../ui/widgets.dart';
import 'acessibilidade_controller.dart';

/// Botão do cabeçalho (e da tela de login) que abre os ajustes de acessibilidade.
class BotaoAcessibilidade extends StatelessWidget {
  const BotaoAcessibilidade({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AcessibilidadeController.instance,
      builder: (context, _) => BotaoIcone(
        icone: Icons.accessibility_new_rounded,
        rotulo: AcessibilidadeController.instance.personalizado ? 'Acessibilidade (ajustes ativos)' : 'Acessibilidade',
        onPressed: () => abrirPainelAcessibilidade(context),
      ),
    );
  }
}

/// Painel lateral com as opções de acessibilidade. As mudanças valem na hora e ficam salvas.
Future<void> abrirPainelAcessibilidade(BuildContext context) {
  return mostrarPainelLateral<void>(
    context,
    largura: 460,
    builder: (ctx) => const _PainelAcessibilidade(),
  );
}

class _PainelAcessibilidade extends StatelessWidget {
  const _PainelAcessibilidade();

  @override
  Widget build(BuildContext context) {
    final a = AcessibilidadeController.instance;
    final tema = GetIt.I<ThemeController>();

    return ListenableBuilder(
      listenable: Listenable.merge([a, tema]),
      builder: (context, _) {
        final c = context.cores;
        return EstruturaPainel(
          cabecalho: const TituloPainel(titulo: 'Acessibilidade', sobretitulo: 'Ajustes salvos neste aparelho'),
          corpo: [
            const RotuloSecao('Tamanho do texto'),
            const SizedBox(height: 10),
            SeletorPilulas<double>(
              opcoes: AcessibilidadeController.escalas,
              selecionado: a.escalaTexto,
              rotulo: AcessibilidadeController.nomeEscala,
              onSelecionar: a.definirEscala,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: c.superficie2, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.borda)),
              child: Text(
                'Exemplo: Chamado #12 — o ar-condicionado da Sala 3 está pingando.',
                style: TextStyle(fontSize: 14, height: 1.5, color: c.texto),
              ),
            ),
            const SizedBox(height: 24),
            const RotuloSecao('Visão'),
            const SizedBox(height: 4),
            _Opcao(
              titulo: 'Alto contraste',
              descricao: 'Texto preto ou branco, bordas mais escuras e cores mais fortes. Ajuda quem tem baixa visão.',
              valor: a.altoContraste,
              onChanged: a.definirAltoContraste,
            ),
            _Opcao(
              titulo: 'Fonte de leitura facilitada',
              descricao: 'Usa a Atkinson Hyperlegible, que deixa letras parecidas (I, l, 1) bem diferentes. Ajuda na baixa visão e na dislexia.',
              valor: a.fonteLegivel,
              onChanged: a.definirFonteLegivel,
            ),
            _Opcao(
              titulo: 'Tema escuro',
              descricao: 'Fundo escuro, mais confortável para quem tem sensibilidade à luz.',
              valor: tema.themeMode == ThemeMode.dark,
              onChanged: (_) => tema.toggleTheme(),
            ),
            const SizedBox(height: 16),
            const RotuloSecao('Movimento'),
            const SizedBox(height: 4),
            _Opcao(
              titulo: 'Reduzir animações',
              descricao: 'Desliga transições e efeitos de movimento. Ajuda quem sente tontura ou se distrai com movimento.',
              valor: a.reduzirMovimento,
              onChanged: a.definirReduzirMovimento,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: c.azulFundo, borderRadius: BorderRadius.circular(12)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: c.azul, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'O Auria também segue as configurações do seu aparelho: tamanho da fonte, texto em negrito, '
                      'alto contraste, remover animações e leitores de tela (TalkBack, VoiceOver e NVDA). '
                      'Dá para usar tudo só pelo teclado: Tab avança, Shift+Tab volta e Enter ou Espaço ativa.',
                      style: TextStyle(fontSize: 13, height: 1.45, color: c.texto),
                    ),
                  ),
                ],
              ),
            ),
          ],
          rodape: Wrap(
            alignment: WrapAlignment.end,
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton(
                style: botaoSecundario(c),
                onPressed: a.personalizado
                    ? () async {
                        await a.restaurarPadrao();
                        if (context.mounted) mostrarToast(context, 'Ajustes de acessibilidade restaurados.');
                      }
                    : null,
                child: const Text('Restaurar padrão'),
              ),
              FilledButton(style: botaoDestaque(c), onPressed: () => Navigator.pop(context), child: const Text('Pronto')),
            ],
          ),
        );
      },
    );
  }
}

class _Opcao extends StatelessWidget {
  final String titulo;
  final String descricao;
  final bool valor;
  final ValueChanged<bool> onChanged;

  const _Opcao({required this.titulo, required this.descricao, required this.valor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: valor,
      onChanged: onChanged,
      title: Text(titulo, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(descricao, style: TextStyle(fontSize: 13, height: 1.4, color: c.textoSecundario)),
      ),
    );
  }
}
