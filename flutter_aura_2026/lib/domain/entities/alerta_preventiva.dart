import 'package:flutter/foundation.dart' show immutable;

/// Ativo que precisa de manutenção preventiva, com os motivos calculados pela API.
@immutable
class AlertaPreventiva {
  final String ativoId;
  final String nome;
  final String patrimonio;
  final String estadoConservacao;
  final String? ambienteNome;
  final List<String> motivos;

  const AlertaPreventiva({
    required this.ativoId,
    required this.nome,
    required this.patrimonio,
    required this.estadoConservacao,
    this.ambienteNome,
    required this.motivos,
  });
}
