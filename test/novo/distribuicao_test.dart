import 'package:flutter_test/flutter_test.dart';
import 'package:funances/novo/modelo/modelos.dart';
import 'package:funances/novo/regras/distribuicao.dart';

const categorias = {
  'moradia': Categoria(id: 'moradia', nome: 'Moradia', tipo: 'saida', grupo: 'essencial'),
  'mercado': Categoria(id: 'mercado', nome: 'Mercado', tipo: 'saida', grupo: 'essencial'),
  'restaurantes': Categoria(id: 'restaurantes', nome: 'Restaurantes', tipo: 'saida', grupo: 'conforto'),
  'lazer': Categoria(id: 'lazer', nome: 'Lazer', tipo: 'saida', grupo: 'conforto'),
  'assinaturas': Categoria(id: 'assinaturas', nome: 'Assinaturas', tipo: 'saida'),
  'salario': Categoria(id: 'salario', nome: 'Salário', tipo: 'entrada'),
};

ResumoMes mes(String chave, int renda, Map<String, int> gastos) => ResumoMes(
      mes: chave,
      deltaPorConta: const {},
      entradasCentavos: renda,
      saidasCentavos: gastos.values.fold(0, (s, v) => s + v),
      categorias: {'salario': (0, renda), for (final e in gastos.entries) e.key: (0, e.value)},
    );

Diagnostico? rodar(List<ResumoMes> resumos, {String referencia = 'equilibrio'}) => diagnosticar(
      resumos: resumos,
      categorias: categorias,
      mesAtual: '2026-11',
      referencia: referenciaDe(referencia),
      nomeDe: (id) => categorias[id]?.nome ?? id,
    );

void main() {
  test('categoria sem grupo é adivinhada pelo nome', () {
    expect(grupoSugerido('Aluguel'), 'essencial');
    expect(grupoSugerido('Plano de saúde'), 'essencial');
    expect(grupoSugerido('Previdência'), 'investimento');
    expect(grupoSugerido('Streaming'), 'conforto');
    expect(grupoDa(categorias['assinaturas']!), 'conforto');
  });

  test('usa a média dos três meses fechados e ignora o corrente', () {
    final d = rodar([
      mes('2026-08', 1000000, {'moradia': 300000, 'restaurantes': 100000}),
      mes('2026-09', 1000000, {'moradia': 300000, 'restaurantes': 200000}),
      mes('2026-10', 1000000, {'moradia': 300000, 'restaurantes': 300000}),
      mes('2026-11', 100000, {'moradia': 900000}),
    ])!;
    expect(d.meses, ['2026-08', '2026-09', '2026-10']);
    expect(d.parcial, isFalse);
    expect(d.rendaCentavos, 1000000);
    expect(d.porGrupo, {'essencial': 300000, 'conforto': 200000, 'investimento': 500000});
    expect(d.apontamentos.single.tipo, 'certo');
  });

  test('estilo de vida acima do teto: aponta o grupo e dá alternativas', () {
    final d = rodar([
      mes('2026-09', 1000000, {'moradia': 400000, 'restaurantes': 200000, 'lazer': 150000, 'assinaturas': 50000}),
      mes('2026-10', 1000000, {'moradia': 400000, 'restaurantes': 300000, 'lazer': 150000, 'assinaturas': 50000}),
    ])!;
    // Média do grupo: 450 mil; teto de 30% = 300 mil.
    expect(d.foraCentavos('conforto'), 150000);
    final a = d.apontamentos.single;
    expect(a.tipo, 'reduzir');
    expect(a.grupo, 'conforto');
    expect(a.titulo, contains('R\$ 1.500,00 acima do teto'));
    // Restaurantes foi o que subiu: vem primeiro.
    expect(a.categorias.first, 'restaurantes');
    expect(a.texto, contains('Restaurantes (+R\$ 1.000,00)'));
    expect(a.alternativas, hasLength(2));
    expect(a.alternativas.last, contains('R\$ 750,00 a menos em cada'));
  });

  test('essencial muito alto é para resolver, não para cortar aos poucos', () {
    final d = rodar([
      mes('2026-10', 1000000, {'moradia': 450000, 'mercado': 200000, 'lazer': 100000}),
    ])!;
    final a = d.apontamentos.first;
    expect(a.tipo, 'resolver');
    expect(a.grupo, 'essencial');
    expect(a.texto, contains('65% da renda'));
    expect(a.texto, contains('Moradia (R\$ 4.500,00) e Mercado (R\$ 2.000,00)'));
    expect(a.alternativas.single, contains('Fixo alto'));
    // Na referência "Fixo alto" o mesmo retrato fica dentro do tolerável.
    expect(rodar([mes('2026-10', 1000000, {'moradia': 450000, 'mercado': 200000, 'lazer': 100000})], referencia: 'fixo-alto')!
        .apontamentos.first.tipo, 'reduzir');
  });

  test('gastar mais do que entra vem antes de tudo', () {
    final d = rodar([mes('2026-10', 500000, {'moradia': 300000, 'lazer': 300000})])!;
    expect(d.apontamentos.first.titulo, 'Os gastos passam da renda');
    expect(d.foraCentavos('investimento'), 200000);
  });

  test('quem gasta pouco não entra na divisão do corte', () {
    final d = rodar([
      mes('2026-10', 1000000, {'restaurantes': 250000, 'lazer': 100000, 'assinaturas': 5000}),
    ])!;
    // 550 reais acima; dividido por três daria 190 de assinaturas, que só gasta 50.
    final a = d.apontamentos.single;
    expect(a.alternativas.last, 'Dividir o corte: Restaurantes, Lazer, R\$ 280,00 a menos em cada.');
  });

  test('sem mês fechado usa o corrente, e sem renda não há diagnóstico', () {
    expect(rodar([mes('2026-11', 1000000, {'moradia': 300000})])!.parcial, isTrue);
    expect(rodar([mes('2026-11', 0, {'moradia': 300000})]), isNull);
    expect(rodar(const []), isNull);
  });
}
