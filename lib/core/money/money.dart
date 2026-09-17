import 'package:flutter/foundation.dart';
import 'package:funances/core/utils/num_extensions.dart';

/// Dinheiro somado em CENTAVOS inteiros.
///
/// `0.1 + 0.2` em ponto flutuante dá `0.30000000000000004`, e um mês de
/// lançamentos somados em `double` acumula esse resto até o total da tela
/// discordar da soma das linhas por um centavo. O app inteiro escondia isso
/// com comparações por epsilon (`(a - b).abs() < 0.01`), que é admitir que a
/// conta está errada e combinar de não olhar.
///
/// Aqui a soma acontece em `int`: exata, associativa, sem resto. A ENTRADA
/// ainda é `double` — é o que o Firestore guarda hoje (F1.10 etapa 2 troca o
/// armazenamento) —, e [Money.fromDouble] arredonda uma vez, na fronteira.
/// Depois disso não há mais arredondamento nenhum.
@immutable
class Money implements Comparable<Money> {
  const Money.fromCents(this.cents);

  /// Converte o `double` que veio do Firestore, arredondando para o centavo
  /// mais próximo. É o ÚNICO ponto onde um valor monetário é arredondado.
  factory Money.fromDouble(double value) => Money.fromCents((value * 100).round());

  static const Money zero = Money.fromCents(0);

  final int cents;

  Money operator +(Money other) => Money.fromCents(cents + other.cents);

  Money operator -(Money other) => Money.fromCents(cents - other.cents);

  Money operator -() => Money.fromCents(-cents);

  /// Multiplicação por um fator adimensional (metade da fatura, 30% da renda).
  /// O arredondamento é do centavo, não do fator.
  Money operator *(num factor) => Money.fromCents((cents * factor).round());

  bool operator <(Money other) => cents < other.cents;
  bool operator <=(Money other) => cents <= other.cents;
  bool operator >(Money other) => cents > other.cents;
  bool operator >=(Money other) => cents >= other.cents;

  bool get isZero => cents == 0;
  bool get isNegative => cents < 0;
  bool get isPositive => cents > 0;

  Money get abs => Money.fromCents(cents.abs());

  /// De volta para `double`, para o que ainda fala em `double`: a gravação no
  /// Firestore, os modelos freezed e os gráficos.
  double toDouble() => cents / 100;

  String format({String? locale}) => toDouble().asCurrency(locale: locale);

  /// Soma exata de uma lista. Vazia dá [zero] — não `null`, não `NaN`.
  static Money sum(Iterable<Money> values) =>
      values.fold(zero, (total, value) => total + value);

  /// Soma de `double`s vindos do Firestore, convertidos um a um. É o
  /// substituto do laço `total += item.amount`.
  static Money sumOf<T>(Iterable<T> items, double Function(T item) amount) =>
      items.fold(zero, (total, item) => total + Money.fromDouble(amount(item)));

  /// Quanto [this] representa de [total], de 0 a 1. Total zero devolve 0 em
  /// vez de dividir por zero.
  double ratioOf(Money total) => total.isZero ? 0 : cents / total.cents;

  @override
  int compareTo(Money other) => cents.compareTo(other.cents);

  @override
  bool operator ==(Object other) => other is Money && other.cents == cents;

  @override
  int get hashCode => cents.hashCode;

  @override
  String toString() => 'Money(${toDouble().toStringAsFixed(2)})';
}

extension MoneyFromDouble on double {
  /// Açúcar para a fronteira: `item.amount.asMoney`.
  Money get asMoney => Money.fromDouble(this);
}
