import '../modelo/modelos.dart';
import 'formatos.dart';

/// Até onde vai uma edição ou exclusão num lançamento que faz parte de uma
/// série (parcelas ou algo que se repete todo mês).
enum Alcance { soEste, proximos, todos }

String _diaDoMes(String data) => data.substring(8, 10);

/// A edição mexeu em algo que faz sentido levar para os outros da série?
/// Pagar, mudar o valor pago ou a data do pagamento é só deste lançamento.
bool mudancaReplicavel(Lancamento antes, Lancamento depois) =>
    antes.tipo != depois.tipo ||
    antes.descricao != depois.descricao ||
    antes.previstoCentavos != depois.previstoCentavos ||
    antes.contaId != depois.contaId ||
    antes.contaDestinoId != depois.contaDestinoId ||
    antes.categoriaId != depois.categoriaId ||
    antes.contraparteId != depois.contraparteId ||
    _diaDoMes(antes.data) != _diaDoMes(depois.data);

/// Os outros lançamentos da série que entram no alcance: os que vencem
/// depois deste, ou todos.
List<Lancamento> _noAlcance(Lancamento este, Iterable<Lancamento> daSerie, Alcance alcance) => [
      for (final l in daSerie)
        if (l.id != este.id && (alcance == Alcance.todos || (alcance == Alcance.proximos && l.data.compareTo(este.data) > 0))) l,
    ];

/// Os outros lançamentos da série como ficam depois de levar a edição até
/// eles. Só devolve os que mudam.
///
/// No que ainda está agendado vale tudo: descrição, valor, conta, categoria
/// e dia do mês. No que já foi pago só mudam descrição, categoria e
/// cliente/fornecedor: valor, conta e data do que aconteceu ficam como foram.
List<Lancamento> replicarEdicao(Lancamento antes, Lancamento depois, Iterable<Lancamento> daSerie, Alcance alcance) {
  final mudouODia = _diaDoMes(antes.data) != _diaDoMes(depois.data);
  final mudados = <Lancamento>[];
  for (final l in _noAlcance(antes, daSerie, alcance)) {
    var novo = l.copiar(
      descricao: antes.descricao != depois.descricao ? depois.descricao : null,
      categoriaId: antes.categoriaId != depois.categoriaId ? () => depois.categoriaId : null,
      contraparteId: antes.contraparteId != depois.contraparteId ? () => depois.contraparteId : null,
    );
    if (l.previsto) {
      final mes = l.data.substring(0, 7);
      novo = novo.copiar(
        tipo: antes.tipo != depois.tipo ? depois.tipo : null,
        previstoCentavos: antes.previstoCentavos != depois.previstoCentavos ? () => depois.previstoCentavos : null,
        contaId: antes.contaId != depois.contaId ? depois.contaId : null,
        contaDestinoId: antes.contaDestinoId != depois.contaDestinoId ? () => depois.contaDestinoId : null,
        data: mudouODia ? diaNoMes(mes, int.parse(_diaDoMes(depois.data))) : null,
      );
    }
    if (_diferente(l, novo)) mudados.add(novo);
  }
  return mudados;
}

bool _diferente(Lancamento a, Lancamento b) =>
    a.tipo != b.tipo ||
    a.descricao != b.descricao ||
    a.previstoCentavos != b.previstoCentavos ||
    a.contaId != b.contaId ||
    a.contaDestinoId != b.contaDestinoId ||
    a.categoriaId != b.categoriaId ||
    a.contraparteId != b.contraparteId ||
    a.data != b.data;

/// Os outros lançamentos da série que saem junto numa exclusão. Só os que
/// ainda estão agendados: o que já foi pago aconteceu e fica no histórico.
List<Lancamento> excluirJunto(Lancamento este, Iterable<Lancamento> daSerie, Alcance alcance) =>
    [for (final l in _noAlcance(este, daSerie, alcance)) if (l.previsto) l];

/// O que muda no cadastro da série para que os meses ainda não gerados
/// sigam a edição. Vazio quando nada muda.
Mapa ajusteDaSerie(Lancamento antes, Lancamento depois) => {
      if (antes.tipo != depois.tipo) 'tipo': depois.tipo,
      if (antes.descricao != depois.descricao) 'descricao': depois.descricao,
      if (antes.previstoCentavos != depois.previstoCentavos && depois.previstoCentavos != null) 'valorCentavos': depois.previstoCentavos,
      if (antes.contaId != depois.contaId) 'contaId': depois.contaId,
      if (antes.contaDestinoId != depois.contaDestinoId) 'contaDestinoId': depois.contaDestinoId,
      if (antes.categoriaId != depois.categoriaId) 'categoriaId': depois.categoriaId,
      if (_diaDoMes(antes.data) != _diaDoMes(depois.data)) 'diaVencimento': int.parse(_diaDoMes(depois.data)),
    };
