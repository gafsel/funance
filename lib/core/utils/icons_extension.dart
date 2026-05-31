import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

extension IconsExtension on String {

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
