import 'dart:typed_data';

/// Um arquivo escolhido pelo usuário, do jeito que todas as plataformas
/// conseguem descrever.
///
/// O app trafegava `dart:io.File` do seletor até o Storage. Na web isso não
/// existe: o seletor devolve um blob, `File('blob:...')` não abre nada e
/// `existsSync()`/`lengthSync()`/`readAsBytesSync()` levantam
/// `UnsupportedError`. O envio de extrato na web parava aí.
///
/// Os bytes são a única representação que serve em todo lugar — e são também
/// o que o `putData` do Firebase Storage quer, na web e fora dela. O [path]
/// fica como informação extra de desktop/mobile, para quem precisar mostrar a
/// origem do arquivo; ninguém deve depender dele para ler o conteúdo.
class PickedDocument {
  const PickedDocument({required this.name, required this.bytes, this.path});

  /// Nome com extensão, como o usuário vê ("extrato-marco.pdf").
  final String name;

  /// Conteúdo completo. É o que sobe para o Storage.
  final Uint8List bytes;

  /// Caminho no disco, quando a plataforma tem um. `null` na web.
  final String? path;

  /// Tamanho real do conteúdo — o que o limite de upload mede.
  ///
  /// Vem dos bytes, e não do que o seletor declarou: `PlatformFile.size`
  /// chegava a vir zerado, e zero passa em qualquer limite.
  int get sizeInBytes => bytes.length;

  /// Extensão em minúsculas, sem ponto. Vazia se o nome não tiver uma.
  String get extension {
    final int dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return '';
    return name.substring(dot + 1).toLowerCase();
  }
}
