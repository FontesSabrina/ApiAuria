import 'package:flutter/foundation.dart' show immutable;

@immutable
class AtivoFalhas {
  final String ativoId;
  final String ativoNome;
  final int quantidadeOrdens;

  const AtivoFalhas({required this.ativoId, required this.ativoNome, required this.quantidadeOrdens});
}

@immutable
class OrdemPendente {
  final String ordemServicoId;
  final String ativoNome;
  final String descricaoProblema;
  final String prioridade;
  final String? tecnicoNome;

  const OrdemPendente({
    required this.ordemServicoId,
    required this.ativoNome,
    required this.descricaoProblema,
    required this.prioridade,
    this.tecnicoNome,
  });
}

/// Indicadores do painel de BI, calculados pela API (GET /api/indicadores).
@immutable
class Indicadores {
  final int totalOrdens;
  final int ordensConcluidas;
  final int ordensEmAberto;
  final double taxaConclusao;
  final double custoTotal;
  final double custoMaoObra;
  final double custoPecas;
  final double tempoMedioAtendimentoHoras;
  final double tempoMedioExecucaoHoras;
  final Map<String, int> chamadosPorStatus;
  final List<AtivoFalhas> topAtivosComFalhas;
  final List<OrdemPendente> ordensPendentes;
  /// Quando a API calculou os números (não muda enquanto o resultado está em cache).
  final DateTime geradoEm;

  const Indicadores({
    required this.totalOrdens,
    required this.ordensConcluidas,
    required this.ordensEmAberto,
    required this.taxaConclusao,
    required this.custoTotal,
    required this.custoMaoObra,
    required this.custoPecas,
    required this.tempoMedioAtendimentoHoras,
    required this.tempoMedioExecucaoHoras,
    required this.chamadosPorStatus,
    required this.topAtivosComFalhas,
    required this.ordensPendentes,
    required this.geradoEm,
  });
}
