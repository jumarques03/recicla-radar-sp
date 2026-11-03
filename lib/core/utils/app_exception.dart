/// Erro com mensagem já pronta para mostrar à pessoa usuária.
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}
