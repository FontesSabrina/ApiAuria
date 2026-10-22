// Utilitários de conversão dos dados que vêm da AuriaAPI.

/// Registros novos recebem um id provisório (UUID) no app até serem salvos;
/// a API sempre usa id inteiro. Id numérico = registro já existe no servidor (PUT);
/// caso contrário, ainda não existe (POST).
bool idDoServidor(String id) => int.tryParse(id) != null;

/// Datas geradas pelo servidor (abertura, conclusão, criação) são gravadas em UTC.
/// Quando voltam do banco sem o sufixo "Z", são interpretadas como UTC e convertidas
/// para o horário local do aparelho.
DateTime dataDoServidor(String valor) {
  final data = DateTime.parse(valor);
  if (data.isUtc) return data.toLocal();
  return DateTime.utc(data.year, data.month, data.day, data.hour, data.minute, data.second, data.millisecond).toLocal();
}

DateTime? dataDoServidorOuNula(dynamic valor) => valor == null ? null : dataDoServidor(valor as String);

double paraDouble(dynamic valor) => (valor as num?)?.toDouble() ?? 0.0;

/// Formata uma data como yyyy-MM-dd (formato aceito pela API em parâmetros de consulta).
String dataParaApi(DateTime data) =>
    '${data.year.toString().padLeft(4, '0')}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';
