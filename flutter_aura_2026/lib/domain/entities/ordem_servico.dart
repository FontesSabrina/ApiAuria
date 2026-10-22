import 'package:flutter/foundation.dart' show immutable;
import 'item_estoque.dart';

enum StatusOS { aberta, emAndamento, concluida, cancelada }

@immutable
class OrdemServico {
  final String id;
  /// Id do chamado que originou a OS (necessário para abrir a OS na API).
  final String chamadoId;
  final String ativoId;
  /// Nome do ativo já enviado pela API (evita uma requisição extra por item da lista).
  final String? ativoNome;
  final String solicitanteId;
  final String descricaoProblema;
  final DateTime dataAbertura;
  final String prioridade;
  final String tipoManutencao;
  final String? tecnicoResponsavelId;
  final String? tecnicoNome;
  final StatusOS status;

  final String? relatotecnico;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final int tempoGastoMinutos;
  /// Calculado pela API: soma (quantidade × custo unitário) das peças consumidas.
  final double custoPecas;
  final double custoMaoDeObra;

  final List<ItemEstoque> pecasUtilizadas;

  final DateTime? dataAprovacao;
  final String? aprovadorId;

  const OrdemServico({
    required this.id,
    this.chamadoId = '',
    required this.ativoId,
    this.ativoNome,
    required this.solicitanteId,
    required this.descricaoProblema,
    required this.dataAbertura,
    required this.prioridade,
    this.tipoManutencao = 'Corretiva',
    this.tecnicoResponsavelId,
    this.tecnicoNome,
    this.status = StatusOS.aberta,
    this.relatotecnico,
    this.dataInicio,
    this.dataFim,
    this.tempoGastoMinutos = 0,
    this.custoPecas = 0.0,
    this.custoMaoDeObra = 0.0,
    this.pecasUtilizadas = const [],
    this.dataAprovacao,
    this.aprovadorId,
  });

  double get custoTotal => custoPecas + custoMaoDeObra;

  OrdemServico copyWith({
    String? id,
    String? chamadoId,
    String? ativoId,
    String? ativoNome,
    String? solicitanteId,
    String? descricaoProblema,
    DateTime? dataAbertura,
    String? prioridade,
    String? tipoManutencao,
    String? tecnicoResponsavelId,
    String? tecnicoNome,
    StatusOS? status,
    String? relatotecnico,
    DateTime? dataInicio,
    DateTime? dataFim,
    int? tempoGastoMinutos,
    double? custoPecas,
    double? custoMaoDeObra,
    List<ItemEstoque>? pecasUtilizadas,
    DateTime? dataAprovacao,
    String? aprovadorId,
  }) {
    return OrdemServico(
      id: id ?? this.id,
      chamadoId: chamadoId ?? this.chamadoId,
      ativoId: ativoId ?? this.ativoId,
      ativoNome: ativoNome ?? this.ativoNome,
      solicitanteId: solicitanteId ?? this.solicitanteId,
      descricaoProblema: descricaoProblema ?? this.descricaoProblema,
      dataAbertura: dataAbertura ?? this.dataAbertura,
      prioridade: prioridade ?? this.prioridade,
      tipoManutencao: tipoManutencao ?? this.tipoManutencao,
      tecnicoResponsavelId: tecnicoResponsavelId ?? this.tecnicoResponsavelId,
      tecnicoNome: tecnicoNome ?? this.tecnicoNome,
      status: status ?? this.status,
      relatotecnico: relatotecnico ?? this.relatotecnico,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      tempoGastoMinutos: tempoGastoMinutos ?? this.tempoGastoMinutos,
      custoPecas: custoPecas ?? this.custoPecas,
      custoMaoDeObra: custoMaoDeObra ?? this.custoMaoDeObra,
      pecasUtilizadas: pecasUtilizadas ?? this.pecasUtilizadas,
      dataAprovacao: dataAprovacao ?? this.dataAprovacao,
      aprovadorId: aprovadorId ?? this.aprovadorId,
    );
  }

  double get horasGastas {
    if (dataInicio != null && dataFim != null) {
      final diferenca = dataFim!.difference(dataInicio!);
      return diferenca.inMinutes / 60.0;
    }
    return 0.0;
  }
}
