import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/time/product_week.dart';
import 'package:funances/features/home/domain/services/journey_service.dart';
import 'package:funances/features/home/domain/services/mission_service.dart';

/// F4.10 §6.5, risco nº 7 — o app tinha DUAS definições de semana, e elas não
/// davam o mesmo resultado.
///
/// `JourneyService.weekIdFor` somava dias de calendário e media o dia do ano
/// em UTC; `MissionService._getWeekNumber`/`_getWeekYear` faziam as duas
/// contas em blocos de 24 horas (`Duration(days:)` e `difference().inDays`).
/// Num domingo de 23 ou 25 horas, a segunda escorrega um dia — e semana errada
/// é checklist e XP do período errado.
///
/// Agora há uma só, [ProductWeek], e estes casos a amarram ao vetor
/// compartilhado com o servidor.

List<Map<String, dynamic>> _vetores() {
  final raw = File(
    'functions/src/test/fixtures/week_vectors.json',
  ).readAsStringSync();
  final cases = (jsonDecode(raw) as Map<String, dynamic>)['cases'] as List;
  return cases.cast<Map<String, dynamic>>();
}

/// O vetor descreve o horário LOCAL do produto (America/Sao_Paulo). A
/// conversão de fuso é do servidor, que tem a base de fusos; o cliente só faz
/// aritmética de calendário, e é essa parte que estes casos verificam.
DateTime _local(Map<String, dynamic> entry) =>
    DateTime.parse((entry['saoPauloLocal'] as String).replaceFirst(' ', 'T'));

void main() {
  test('o vetor compartilhado com o servidor existe e não está vazio', () {
    expect(_vetores(), isNotEmpty);
  });

  group('ProductWeek concorda com o servidor', () {
    for (final entry in _vetores()) {
      test(entry['label'] as String, () {
        final local = _local(entry);

        expect(ProductWeek.idOf(local), entry['expectedWeekId']);
        expect(ProductWeek.yearOf(local), entry['expectedYear']);
        expect(ProductWeek.numberOf(local), entry['expectedWeek']);
      });
    }
  });

  group('as duas definições do app viraram uma', () {
    test('a jornada e as missões respondem a MESMA semana, caso a caso', () {
      for (final entry in _vetores()) {
        final local = _local(entry);

        // O caminho da jornada.
        final idDaJornada = JourneyService.weekIdFor(local);

        // O caminho das missões: janela da semana e, a partir do começo dela,
        // ano e número — que é como `watchMissions` pergunta ao resumo
        // semanal.
        final janela = MissionService.weekWindow(local);
        final ano = ProductWeek.yearOf(janela.start);
        final numero = ProductWeek.numberOf(janela.start);
        final idDasMissoes = '$ano-W${numero.toString().padLeft(2, '0')}';

        expect(
          idDasMissoes,
          idDaJornada,
          reason: 'divergiram em ${entry['label']}',
        );
        expect(idDaJornada, entry['expectedWeekId']);
      }
    });

    test('a janela começa no domingo 00:00 e termina no fim do sábado', () {
      // Sexta-feira, 11/09/2026.
      final janela = MissionService.weekWindow(DateTime(2026, 9, 11, 15, 42));

      expect(janela.start, DateTime(2026, 9, 6));
      expect(janela.start.weekday % 7, 0); // domingo
      expect(janela.end, DateTime(2026, 9, 13).subtract(
        const Duration(milliseconds: 1),
      ));
    });

    test('perguntar no próprio domingo não devolve a semana anterior', () {
      final janela = MissionService.weekWindow(DateTime(2026, 9, 13, 0, 0, 1));
      expect(janela.start, DateTime(2026, 9, 13));
    });
  });

  group('aritmética de calendário, não de 24 horas', () {
    test('o começo da semana preserva o dia mesmo somando dias de calendário',
        () {
      // Num domingo de 23h ou 25h, `subtract(Duration(days: n))` pode cair no
      // dia anterior; `addCalendarDays` não. Aqui o fuso do teste pode não ter
      // DST, mas a propriedade — o começo é sempre um domingo, à meia-noite —
      // vale em qualquer dia do calendário.
      for (var dia = DateTime(2018, 1, 1);
          dia.year < 2019;
          dia = DateTime(dia.year, dia.month, dia.day + 1)) {
        final inicio = ProductWeek.startOf(dia);

        expect(
          inicio.weekday % 7,
          0,
          reason: 'a semana de $dia não começa num domingo',
        );
        // A HORA não é verificada de propósito: num fuso com horário de
        // verão, a meia-noite do domingo da virada simplesmente não existe, e
        // o `DateTime` normaliza para 01:00. O que precisa valer é o DIA.
      }
    });

    test('a semana de 1º de janeiro pertence ao ano do domingo que a inicia',
        () {
      // 1º/1/2026 é uma quinta: a semana dela começou no domingo 28/12/2025.
      expect(ProductWeek.idOf(DateTime(2026, 1, 1, 12)), '2025-W52');
      // 1º/1/2023 é domingo: semana 1 cheia.
      expect(ProductWeek.idOf(DateTime(2023, 1, 1, 10)), '2023-W01');
    });
  });
}
