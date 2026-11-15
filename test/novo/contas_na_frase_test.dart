import 'package:flutter_test/flutter_test.dart';
import 'package:funances/novo/modelo/modelos.dart';
import 'package:funances/novo/regras/leitura_frase.dart';

void main() {
  // Duas pessoas, conta e cartão no mesmo banco: o caso difícil.
  const ctx = ContextoDeLeitura(
    hoje: '2026-11-14',
    euId: 'eu',
    contaPadraoId: 'nu',
    membros: [Membro(uid: 'eu', nome: 'Gabriel Teste'), Membro(uid: 'bia', nome: 'Bárbara Teste')],
    contas: [
      Conta(id: 'nu', nome: 'Nubank', tipo: 'corrente', banco: 'nubank', donos: ['eu']),
      Conta(id: 'nu-cartao', nome: 'Cartão Nubank', tipo: 'cartao', banco: 'nubank', donos: ['eu']),
      Conta(id: 'nu-bia', nome: 'Nubank', tipo: 'corrente', banco: 'nubank', donos: ['bia'], apelido: 'nu bia'),
      Conta(id: 'nu-cartao-bia', nome: 'Cartão Nubank', tipo: 'cartao', banco: 'nubank', donos: ['bia']),
      Conta(id: 'itau', nome: 'Itaú conjunta', tipo: 'corrente', banco: 'itau', donos: ['eu', 'bia']),
      Conta(id: 'itau-cartao', nome: 'Cartão Itaú', tipo: 'cartao', banco: 'itau', donos: ['eu']),
      Conta(id: 'c6-bia', nome: 'C6', tipo: 'corrente', banco: 'c6', donos: ['bia']),
    ],
    categorias: [Categoria(id: 'mercado', nome: 'Mercado', tipo: 'saida')],
  );

  String? conta(String frase) => lerLinha(frase, ctx)?.contaId;

  group('qual conta a frase quis dizer', () {
    test('o banco sozinho é a conta de quem está lançando, não o cartão', () {
      expect(conta('mercado 45 nubank'), 'nu');
      expect(conta('mercado 45 no nubank'), 'nu');
      expect(conta('mercado 45 meu nubank'), 'nu');
      expect(conta('mercado 45 itau'), 'itau');
    });

    test('"cartão" ou "crédito" escolhem o cartão', () {
      expect(conta('mercado 45 cartão nubank'), 'nu-cartao');
      expect(conta('mercado 45 no meu cartão de crédito nubank'), 'nu-cartao');
      expect(conta('mercado 45 nubank crédito'), 'nu-cartao');
      expect(conta('mercado 45 cartão itaú'), 'itau-cartao');
    });

    test('"da Bárbara" escolhe a conta dela', () {
      expect(conta('mercado 45 nubank da bárbara'), 'nu-bia');
      expect(conta('mercado 45 nubank da Barbara'), 'nu-bia');
      expect(conta('mercado 45 cartão nubank da bárbara'), 'nu-cartao-bia');
      expect(conta('mercado 45 cartão de crédito nubank da bárbara'), 'nu-cartao-bia');
      expect(conta('mercado 45 no cartão da bárbara'), 'nu-cartao-bia');
    });

    test('apelido e conta conjunta', () {
      expect(conta('mercado 45 nu bia'), 'nu-bia');
      expect(conta('mercado 45 na conjunta'), 'itau');
      expect(conta('mercado 45 itaú conjunta'), 'itau');
    });

    test('conta que só a outra pessoa tem não precisa de "da Bárbara"', () {
      expect(conta('mercado 45 c6'), 'c6-bia');
    });

    test('sem conta citada, vale a conta padrão', () {
      expect(conta('mercado 45'), 'nu');
    });

    test('"no cartão" com dois cartões meus fica em aberto, em vez de adivinhar', () {
      final l = lerLinha('mercado 45 no cartão', ctx)!;
      expect(l.contaId, isNull);
      expect(l.completa, isFalse);
    });

    test('as palavras da conta e do titular não sobram na descrição', () {
      expect(lerLinha('mercado 45 no meu cartão de crédito nubank', ctx)!.descricao, 'Mercado');
      expect(lerLinha('farmácia 30 nubank da bárbara', ctx)!.descricao, 'Farmácia');
    });

    test('transferência entre a minha conta e a dela', () {
      final l = lerLinha('transferi 200 do meu nubank para o nubank da bárbara', ctx)!;
      expect(l.tipo, 'transferencia');
      expect(l.contaId, 'nu');
      expect(l.contaDestinoId, 'nu-bia');
    });
  });
}
