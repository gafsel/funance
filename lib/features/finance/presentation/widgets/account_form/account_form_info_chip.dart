import 'package:flutter/material.dart';
import 'package:funances/core/widgets/app_chip.dart';

/// Chip de contagem do resumo do extrato lido ("N lançamentos encontrados").
///
/// Vive separado porque é o pedaço que mais tende a se repetir: cada novo dado
/// que a leitura do documento passar a detectar entra como mais um chip, e o
/// formulário não precisa saber desenhá-lo para isso.
Widget buildAccountFormInfoChip(IconData icon, String label) {
  return StatusPill(label: label, icon: icon, tone: StatusTone.info);
}
