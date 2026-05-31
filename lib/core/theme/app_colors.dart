import 'package:flutter/material.dart';

class AppColors {
  // --- 1. Paleta Principal ---
  
  // Deep Turquesa: Fundo principal do container, cabeçalhos profundos e containers de seção.
  static const Color deepTurquoise = Color(0xFF14404C);
  
  // Azul-petróleo Vibrante: Fundo geral do corpo, elementos de interface secundários e variações de gradiente.
  static const Color vibrantTeal = Color(0xFF4A8C9C);
  
  // Branco Puro: Texto principal em fundos profundos, texto de interface limpo e áreas de conteúdo limpas.
  static const Color pureWhite = Color(0xFFFFFFFF);

  // --- 2. Paleta de Destaque e Recompensa ---
  
  // Ouro do Sucesso: CTAs, ícones de conquista, moedas de recompensa.
  static const Color successGold = Color(0xFFFAD02E);
  
  // Ouro Antigo (Moeda): Texturas de moedas 3D, ícones de progresso.
  static const Color antiqueGold = Color(0xFFD4A017);
  
  // Ouro Pálido (Título): Texto de título principal sobre fundos escuros.
  static const Color paleGold = Color(0xFFFDF3BB);

  // Marinho Escuro: Texto principal em fundos claros
  static const Color darkNavy = Color(0xFF0A2329);

  // --- 3. Paleta de Gamificação e Feedback ---
  
  // Ciano Brilhante: Barras de progresso (estado final), estrelas.
  static const Color brightCyan = Color(0xFF25D3D0);
  
  // Verde Limão (Progresso): Início de barras de progresso, feedback de sucesso.
  static const Color limeGreen = Color(0xFF9CDE7C);
  
  // Laranja Coral (Ação): Elementos de gamificação, aviso médio, ação secundária.
  static const Color coralOrange = Color(0xFFFF6F61);
  
  // Roxo Profundo (Mistério): Feedback de erro crítico, bônus especiais.
  static const Color deepPurple = Color(0xFF8E44AD);

  // Cores de apoio legadas (podem ser substituídas pelo deepPurple se necessário)
  static const Color error = Color(0xFFBA1A1A);
  static const Color softGrey = Color(0xFFEEEEEE);
  // --- 4. Seleção de Cores para Categorias ---
  static const List<Color> selectionColors = [
    deepTurquoise,
    vibrantTeal,
    successGold,
    brightCyan,
    limeGreen,
    coralOrange,
    deepPurple,
    Color(0xFFE91E63), // Pink
    Color(0xFF9C27B0), // Purple
    Color(0xFF673AB7), // Deep Purple
    Color(0xFF3F51B5), // Indigo
    Color(0xFF2196F3), // Blue
    Color(0xFF009688), // Teal
    Color(0xFF4CAF50), // Green
    Color(0xFFFFEB3B), // Yellow
    Color(0xFFFF9800), // Orange
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Blue Grey
  ];
}
