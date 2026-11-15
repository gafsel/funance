import 'dart:js_interop';

// As três funções moram em `web/trava.js` (carregado pelo index.html).
@JS('funancesTrava.disponivel')
external JSPromise<JSBoolean> _disponivel();

@JS('funancesTrava.cadastrar')
external JSPromise<JSString> _cadastrar(JSString nome);

@JS('funancesTrava.verificar')
external JSPromise<JSBoolean> _verificar(JSString credencial);

Future<bool> biometriaDisponivel() async {
  try {
    return (await _disponivel().toDart).toDart;
  } catch (_) {
    return false;
  }
}

/// Cadastra este aparelho e devolve a identificação da credencial; `null`
/// se a pessoa cancelou ou não deu certo.
Future<String?> cadastrarBiometria(String nome) async {
  try {
    final id = (await _cadastrar(nome.toJS).toDart).toDart;
    return id.isEmpty ? null : id;
  } catch (_) {
    return null;
  }
}

/// Pede a biometria. `true` só se a pessoa foi reconhecida.
Future<bool> verificarBiometria(String credencial) async {
  try {
    return (await _verificar(credencial.toJS).toDart).toDart;
  } catch (_) {
    return false;
  }
}
