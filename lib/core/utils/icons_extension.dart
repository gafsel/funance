import 'package:flutter/material.dart';

extension IconsExtension on String {
  /// O ícone com este nome, ou um substituto.
  ///
  /// O nome vem do Firestore — de uma categoria, de uma conta, de um emblema
  /// do catálogo — e por isso NUNCA é garantido: um catálogo mais novo que o
  /// app instalado nomeia ícones que esta build não conhece, e o leitor de
  /// notificação grava categoria sem `icon` nenhum (que chega aqui como
  /// string vazia, desde que o parse passou a tolerar). Nos dois casos a
  /// resposta é um substituto, nunca uma exceção: uma tela inteira não pode
  /// cair porque um pictograma não existe.
  ///
  /// A ordem é deliberada: o ícone pedido, depois o [orElse] de quem chama —
  /// que conhece o assunto e escolhe melhor, `Icons.category` numa lista de
  /// categorias — e só então o círculo, que é o "algo existe aqui" genérico.
  ///
  /// Não é um mapa de TODOS os ícones do Material: é a lista que a interface
  /// oferece na escolha de ícone. Um nome fora dela não é um erro de
  /// digitação a corrigir aqui — é um nome que o app não oferece.
  IconData asIcon({IconData? orElse}) {
    return availableIcons[this] ?? orElse ?? Icons.circle;
  }

  static const Map<String, IconData> availableIcons = {
    'account_balance': Icons.account_balance,
    'credit_card': Icons.credit_card,
    'savings': Icons.savings,
    'account_balance_wallet': Icons.account_balance_wallet,
    'money': Icons.money,
    'attach_money': Icons.attach_money,
    'trending_up': Icons.trending_up,
    'trending_down': Icons.trending_down,
    'payments': Icons.payments,
    'wallet': Icons.wallet,
    'show_chart': Icons.show_chart,
    'pie_chart': Icons.pie_chart,
    'monetization_on': Icons.monetization_on,
    'shopping_cart': Icons.shopping_cart,
    'restaurant': Icons.restaurant,
    'directions_car': Icons.directions_car,
    'home': Icons.home,
    'flash_on': Icons.flash_on,
    'water_drop': Icons.water_drop,
    'wifi': Icons.wifi,
    'school': Icons.school,
    'health_and_safety': Icons.health_and_safety,
    'fitness_center': Icons.fitness_center,
    'theater_comedy': Icons.theater_comedy,
    'flight': Icons.flight,
    'category': Icons.category,
    'work': Icons.work,
    'pets': Icons.pets,
    'stroller': Icons.stroller,
    'movie': Icons.movie,
    'sports_esports': Icons.sports_esports,
    'checkroom': Icons.checkroom,
    'medication': Icons.medication,
    'spa': Icons.spa,
    'face': Icons.face,
    'brushes': Icons.brush,
    'handyman': Icons.handyman,
    'cleaning_services': Icons.cleaning_services,
    'build': Icons.build,
    'subscriptions': Icons.subscriptions,
    'local_bar': Icons.local_bar,
    'local_cafe': Icons.local_cafe,
    'fastfood': Icons.fastfood,
    'celebration': Icons.celebration,
  };
}
