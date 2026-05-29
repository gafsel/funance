import 'dart:io';

extension FileExtension on File {
  String get fileName {
    return path.split("/").last;
  }
}
