import 'package:flutter/material.dart';

import 'auria_colors.dart';

/// Estilos de botão do Auria. Uso: `FilledButton(style: botaoDestaque(context.cores), ...)`.

/// Ação principal da tela (fundo na cor de destaque, texto escuro).
ButtonStyle botaoDestaque(AuriaColors c) => FilledButton.styleFrom(
      backgroundColor: c.destaque,
      foregroundColor: c.sobreDestaque,
      disabledBackgroundColor: c.destaque.withValues(alpha: 0.4),
      disabledForegroundColor: c.sobreDestaque.withValues(alpha: 0.6),
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
    );

/// Ação secundária (fundo da superfície, borda fina).
ButtonStyle botaoSecundario(AuriaColors c, {Color? cor}) => OutlinedButton.styleFrom(
      foregroundColor: cor ?? c.texto,
      backgroundColor: c.superficie,
      side: BorderSide(color: c.borda),
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
    );

/// Botão compacto para ações dentro de listas e cards.
ButtonStyle botaoPequeno(AuriaColors c, {Color? cor}) => OutlinedButton.styleFrom(
      foregroundColor: cor ?? c.texto,
      backgroundColor: c.superficie,
      side: BorderSide(color: c.borda),
      minimumSize: const Size(0, 36),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
    );
