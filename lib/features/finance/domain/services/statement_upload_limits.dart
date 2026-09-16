/// Regras do arquivo que o usuário envia para análise (extrato, fatura,
/// conciliação).
///
/// O servidor recusa o que passa do limite depois que o arquivo já subiu para
/// o Storage: o usuário espera o upload inteiro para receber um erro. Checar
/// antes é mais rápido e mais barato, e a mensagem pode ser específica
/// (mandar OFX, ou um período menor) em vez do texto genérico do servidor.
abstract final class StatementUploadLimits {
  /// Teto do arquivo analisável, em bytes. É o mesmo limite do servidor —
  /// as rules do Storage cortam em 20 MB, mas o que a análise aceita é 10 MB.
  static const int maxBytes = 10 * 1024 * 1024;

  /// Em megabytes, para a mensagem ao usuário.
  static const int maxMegabytes = maxBytes ~/ (1024 * 1024);

  static bool isWithinLimit(int bytes) => bytes <= maxBytes;

  /// A extensão do arquivo está entre as aceitas.
  ///
  /// Compara em minúsculas porque o nome vem do sistema de arquivos e
  /// `Extrato.PDF` é tão válido quanto `extrato.pdf`. Nome sem ponto (ou
  /// terminando em ponto) não tem extensão e não passa.
  static bool isAllowedExtension(String fileName, List<String> allowed) {
    final dot = fileName.lastIndexOf('.');
    if (dot < 0 || dot == fileName.length - 1) return false;

    final extension = fileName.substring(dot + 1).toLowerCase();

    return allowed.map((e) => e.toLowerCase()).contains(extension);
  }
}
