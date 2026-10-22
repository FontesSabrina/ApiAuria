import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_aura_2026/core/network/api_exception.dart';
import 'package:flutter_aura_2026/core/network/api_parsers.dart';
import 'package:flutter_aura_2026/data/datasources/remote/ordem_servico_remote_datasource.dart';
import 'package:flutter_aura_2026/domain/entities/ordem_servico.dart';

void main() {
  group('api_parsers', () {
    test('idDoServidor diferencia id numérico (servidor) de UUID provisório', () {
      expect(idDoServidor('42'), isTrue);
      expect(idDoServidor('3f1c9a2e-0000-4000-8000-000000000000'), isFalse);
    });

    test('dataDoServidor trata data sem fuso como UTC', () {
      final semFuso = dataDoServidor('2026-10-22T12:00:00');
      final comZ = dataDoServidor('2026-10-22T12:00:00Z');
      expect(semFuso, comZ);
      expect(semFuso.isUtc, isFalse); // convertida para o horário local
    });

    test('dataParaApi formata yyyy-MM-dd', () {
      expect(dataParaApi(DateTime(2026, 3, 7)), '2026-03-07');
    });
  });

  test('ordemServicoFromJson lê a resposta enriquecida da API', () {
    final os = ordemServicoFromJson({
      'id': 7,
      'chamadoId': 3,
      'tecnicoId': 2,
      'tecnicoNome': 'Carlos',
      'tempoGastoMinutos': 45,
      'parecerTecnico': 'Troca de lâmpada',
      'custoMaoObra': 50,
      'custoPecas': 24.5,
      'custoTotal': 74.5,
      'dataInicio': '2026-10-22T12:00:00',
      'dataConclusao': null,
      'concluida': false,
      'statusChamado': 'Em Execucao',
      'descricaoProblema': 'Lâmpada queimada',
      'prioridade': 'Alta',
      'tipoManutencao': 'Corretiva',
      'dataAbertura': '2026-10-22T11:00:00',
      'ativoId': 5,
      'ativoNome': 'Luminária sala 101',
      'solicitanteId': 9,
      'solicitanteNome': 'Ana',
      'itensUtilizados': [
        {'itemEstoqueId': 1, 'itemNome': 'Lâmpada LED', 'quantidadeUtilizada': 2, 'custoUnitario': 12.25, 'subtotal': 24.5},
      ],
    });

    expect(os.id, '7');
    expect(os.chamadoId, '3');
    expect(os.ativoNome, 'Luminária sala 101');
    expect(os.status, StatusOS.aberta);
    expect(os.custoTotal, 74.5);
    expect(os.pecasUtilizadas.single.quantidade, 2);
  });

  test('ApiException mostra a mensagem e os erros de validação', () {
    final e = ApiException('Dados inválidos.', errors: ['O nome é obrigatório.', 'Informe um e-mail válido.'], statusCode: 400);
    expect(e.toString(), contains('Dados inválidos.'));
    expect(e.toString(), contains('O nome é obrigatório.'));
  });
}
