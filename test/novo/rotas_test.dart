import 'package:flutter_test/flutter_test.dart';
import 'package:funances/novo/caminhos.dart';
import 'package:funances/novo/rotas.dart';
import 'package:funances/novo/telas/casca.dart';
import 'package:funances/novo/telas/conta.dart';
import 'package:funances/novo/telas/fechamento.dart';
import 'package:funances/novo/telas/meta.dart';

void main() {
  test('cada seção tem um endereço e volta dele', () {
    for (final secao in Secao.values) {
      expect(secaoDoCaminho(caminhoDaSecao(secao)), secao);
    }
    expect(secaoDoCaminho('/'), Secao.inicio);
    expect(secaoDoCaminho(''), Secao.inicio);
    expect(secaoDoCaminho('/nao-existe'), isNull);
    expect(secaoDoCaminho('/fechamento/2026-10'), isNull);
  });

  test('endereço de detalhe monta a tela com o id', () {
    expect((telaDoCaminho(caminhoDaConta('abc')) as TelaConta).contaId, 'abc');
    expect((telaDoCaminho(caminhoDaMeta('m 1/2')) as TelaMeta).metaId, 'm 1/2');
    expect((telaDoCaminho(caminhoDoFechamento('2026-10')) as TelaFechamento).mes, '2026-10');
    expect(telaDoCaminho(caminhoDaFatura('cartao', 'cartao_2026-11-10')), isNotNull);
    expect(telaDoCaminho(caminhoDoCartao('cartao')), isNotNull);
    expect(telaDoCaminho(caminhoDasCategorias), isNotNull);
  });

  test('endereço de seção ou desconhecido não é detalhe', () {
    expect(telaDoCaminho('/'), isNull);
    expect(telaDoCaminho('/lancamentos'), isNull);
    expect(telaDoCaminho('/fechamento'), isNull);
    expect(telaDoCaminho('/conta'), isNull);
    expect(telaDoCaminho('/qualquer/coisa/errada'), isNull);
  });

  test('ao abrir num detalhe a casca fica por baixo', () {
    final pilha = rotasIniciais(caminhoDaConta('abc'));
    expect(pilha.map((r) => r.settings.name), ['/', '/conta/abc']);
    expect(rotasIniciais('/metas').map((r) => r.settings.name), ['/metas']);
    expect(rotasIniciais('/nao-existe').map((r) => r.settings.name), ['/']);
  });
}
