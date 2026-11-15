import 'package:flutter_test/flutter_test.dart';
import 'package:funances/novo/modelo/modelos.dart';
import 'package:funances/novo/regras/cenario.dart';
import 'package:funances/novo/regras/faturas.dart';
import 'package:funances/novo/regras/organizacao.dart';

const hoje = '2026-11-16';

Lancamento l(String id, String tipo, int centavos, String data, {bool pago = true, String conta = 'cc', String? destino}) => Lancamento(
      id: id,
      tipo: tipo,
      descricao: id,
      previstoCentavos: pago ? null : centavos,
      realizadoCentavos: pago ? centavos : null,
      data: data,
      dataEfetiva: pago ? data : null,
      situacao: pago ? 'efetivado' : 'previsto',
      contaId: conta,
      contaDestinoId: destino,
    );

Categoria cat(String id, {int? limite, String? grupo = 'conforto'}) =>
    Categoria(id: id, nome: id[0].toUpperCase() + id.substring(1), tipo: 'saida', limiteMensalCentavos: limite, grupo: grupo);

ResumoMes resumo(Map<String, int> gastos) => ResumoMes(
      mes: '2026-11',
      deltaPorConta: const {},
      categorias: {for (final e in gastos.entries) e.key: (0, e.value)},
    );

void main() {
  group('comprometimento do mês', () {
    const contas = {
      'cc': Conta(id: 'cc', nome: 'Conta', tipo: 'corrente'),
      'cartao': Conta(id: 'cartao', nome: 'Cartão', tipo: 'cartao'),
    };
    final fatura = SituacaoDaFatura(
      const Fatura(id: 'f', contaId: 'cartao', vencimento: '2026-11-10', fechamento: '2026-11-04', inicio: '2026-10-04', fim: '2026-11-03', totalCentavos: 100000, pagoCentavos: 100000),
      20000,
      hoje,
    );

    test('soma o que sai das contas e as faturas que vencem no mês; compra no cartão e transferência ficam de fora', () {
      final c = calcularComprometimento(
        mes: '2026-11',
        contas: contas,
        faturas: [fatura],
        lancamentos: [
          l('salario', 'entrada', 700000, '2026-11-05'),
          l('freela', 'entrada', 70000, '2026-11-21', pago: false),
          l('aluguel', 'saida', 210000, '2026-11-06'),
          l('luz', 'saida', 18000, '2026-11-18', pago: false),
          l('mercado no cartão', 'saida', 40000, '2026-11-08', conta: 'cartao'),
          l('pagamento da fatura', 'transferencia', 100000, '2026-11-10', destino: 'cartao'),
          l('do mês passado', 'saida', 5000, '2026-10-30'),
        ],
      );
      expect(c.entraCentavos, 770000);
      expect(c.contasCentavos, 228000);
      // A fatura conta pelo devido: as compras mais o que veio da anterior.
      expect(c.faturasCentavos, 120000);
      expect(c.sobraCentavos, 422000);
      expect(c.percentual, 45);
    });

    test('sem entrada não há percentual', () {
      expect(calcularComprometimento(mes: '2026-11', contas: contas, faturas: const [], lancamentos: const []).percentual, isNull);
    });
  });

  group('quanto ainda dá', () {
    final categorias = [cat('restaurantes', limite: 50000), cat('lazer', limite: 30000), cat('mercado', limite: 90000, grupo: 'essencial'), cat('compras'), cat('assinaturas')];
    final gasto = resumo({'restaurantes': 56000, 'lazer': 25500, 'mercado': 48000, 'compras': 12000, 'assinaturas': 6000});

    test('só entra quem tem limite, do mais crítico para o mais folgado', () {
      final restos = restosPorCategoria(gasto, categorias);
      expect(restos.map((r) => r.categoriaId), ['restaurantes', 'lazer', 'mercado']);
      expect(restos[0].passou, isTrue);
      expect(restos[0].restaCentavos, -6000);
      expect(restos[1].perto, isTrue);
      expect(restos[2].perto, isFalse);
    });

    test('o resto do estilo de vida usa o teto do grupo menos os limites já dados', () {
      // Teto de 150 mil; restaurantes e lazer já têm 80 mil: sobram 70 mil para as sem limite.
      final resto = restoDoEstiloDeVida(gasto, categorias, 150000)!;
      expect(resto.limiteCentavos, 70000);
      expect(resto.gastoCentavos, 18000);
      expect(resto.restaCentavos, 52000);
      expect(restoDoEstiloDeVida(gasto, categorias, null), isNull);
      expect(restoDoEstiloDeVida(gasto, [cat('lazer', limite: 30000)], 150000), isNull);
    });

    test('a frase aparece só quando há o que dizer', () {
      const folgado = Comprometimento(entraCentavos: 100, contasCentavos: 10, faturasCentavos: 10);
      String nome(String id) => id;
      expect(fraseDaSituacao(restosPorCategoria(gasto, categorias), null, folgado, nome), 'restaurantes passou do limite. lazer está perto.');
      expect(fraseDaSituacao(restosPorCategoria(resumo({'lazer': 100}), categorias), null, folgado, nome), isNull);
      expect(
        fraseDaSituacao(const [], null, const Comprometimento(entraCentavos: 100000, contasCentavos: 90000, faturasCentavos: 30000), nome),
        contains('a mais de destino do que entra'),
      );
    });
  });

  test('pendências: o que venceu e o que vence em sete dias', () {
    final p = calcularPendencias([
      l('internet', 'saida', 11990, '2026-11-13', pago: false),
      l('luz', 'saida', 18900, '2026-11-18', pago: false),
      l('freela', 'entrada', 120000, '2026-11-21', pago: false),
      l('longe', 'saida', 5000, '2026-11-30', pago: false),
      l('pago', 'saida', 5000, '2026-11-10'),
    ], hoje);
    expect(p.atrasados.map((x) => x.id), ['internet']);
    expect(p.proximos.map((x) => x.id), ['luz', 'freela']);
    expect(p.atrasadoCentavos, 11990);
    // O que é a receber aparece na lista, mas não soma no "a pagar".
    expect(p.proximoCentavos, 18900);
  });

  group('organização', () {
    test('o convite volta a cada três meses e adiar segura por trinta dias', () {
      expect(horaDeOrganizar(hoje: hoje), isTrue);
      expect(horaDeOrganizar(hoje: hoje, feitaEm: '2026-09-20'), isFalse);
      expect(horaDeOrganizar(hoje: hoje, feitaEm: '2026-08-31'), isTrue);
      expect(horaDeOrganizar(hoje: hoje, adiadaEm: '2026-11-01'), isFalse);
      expect(horaDeOrganizar(hoje: hoje, adiadaEm: '2026-10-10'), isTrue);
    });

    test('reparte o teto na proporção do que cada categoria costuma gastar', () {
      final s = sugerirLimites(
        rendaCentavos: 1000000, fixosCentavos: 500000, metasCentavos: 100000, percentualDoEstilo: 30,
        mediaPorCategoria: {'restaurantes': 300000, 'lazer': 100000, 'sem historico': 0},
      );
      // 30% seriam 300 mil, que cabem no que sobra (400 mil).
      expect(s.tetoCentavos, 300000);
      expect(s.limites, {'restaurantes': 225000, 'lazer': 75000});
      expect(s.aviso, isNull);
    });

    test('o teto é o que sobra quando os fixos e as metas apertam', () {
      final s = sugerirLimites(
        rendaCentavos: 1000000, fixosCentavos: 700000, metasCentavos: 150000, percentualDoEstilo: 30,
        mediaPorCategoria: {'restaurantes': 300000},
      );
      expect(s.tetoCentavos, 150000);
      expect(s.limites, {'restaurantes': 150000});
    });

    test('quem já gasta menos que o teto fica com o que costuma gastar', () {
      final s = sugerirLimites(
        rendaCentavos: 1000000, fixosCentavos: 300000, metasCentavos: 0, percentualDoEstilo: 30,
        mediaPorCategoria: {'lazer': 43700},
      );
      expect(s.limites, {'lazer': 43000});
    });

    test('sem renda ou sem sobra, avisa em vez de sugerir', () {
      expect(sugerirLimites(rendaCentavos: 0, fixosCentavos: 0, metasCentavos: 0, percentualDoEstilo: 30, mediaPorCategoria: const {}).aviso, isNotNull);
      final apertado = sugerirLimites(rendaCentavos: 500000, fixosCentavos: 450000, metasCentavos: 80000, percentualDoEstilo: 30, mediaPorCategoria: {'lazer': 10000});
      expect(apertado.limites, isEmpty);
      expect(apertado.aviso, contains('já tomam toda a renda'));
    });
  });
}
