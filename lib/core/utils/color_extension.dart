import 'package:flutter/material.dart';

extension ColorExtension on String {
  Color asColor() {
    return Color(int.parse(replaceAll('#', '0xFF')));
  }
}
