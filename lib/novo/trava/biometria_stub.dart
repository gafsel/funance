Future<bool> biometriaDisponivel() async => false;

/// Cadastra este aparelho e devolve a identificação da credencial; `null`
/// se a pessoa cancelou ou não deu certo.
Future<String?> cadastrarBiometria(String nome) async => null;

/// Pede a biometria. `true` só se a pessoa foi reconhecida.
Future<bool> verificarBiometria(String credencial) async => false;
