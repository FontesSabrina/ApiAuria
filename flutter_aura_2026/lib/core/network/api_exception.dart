/// Erro vindo da AuriaAPI: falha de negócio/validação (ResultWrapper com `success:false`)
/// ou falha de transporte/autorização (401/403/erro de rede).
class ApiException implements Exception {
  final String message;
  final List<String> errors;
  final int? statusCode;

  ApiException(this.message, {this.errors = const [], this.statusCode});

  /// Mensagem pronta para mostrar ao usuário: a mensagem principal e, quando houver
  /// mais de um erro (ex.: vários campos inválidos), a lista de erros.
  @override
  String toString() {
    final detalhes = errors.where((e) => e != message).toList();
    return detalhes.isEmpty ? message : '$message\n• ${detalhes.join('\n• ')}';
  }
}
