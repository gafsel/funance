/// Dinheiro e datas, do jeito que aparecem na tela.
library;

String _milhar(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return b.toString();
}

/// `R$ 1.234,56`. Negativo com o sinal antes do símbolo.
String reais(int centavos, {bool comSimbolo = true}) {
  final abs = centavos.abs();
  final texto = '${_milhar(abs ~/ 100)},${(abs % 100).toString().padLeft(2, '0')}';
  return '${centavos < 0 ? '-' : ''}${comSimbolo ? 'R\$ ' : ''}$texto';
}

/// Lê `45`, `45,9`, `45.90`, `1.234,56`, `R$ 12` como centavos.
/// Devolve `null` se não for um valor.
int? lerCentavos(String texto) {
  var t = texto.trim().replaceAll(RegExp(r'[Rr]\$\s*'), '').replaceAll(' ', '');
  if (t.isEmpty || !RegExp(r'^\d[\d.,]*$').hasMatch(t)) return null;
  final virgula = t.lastIndexOf(',');
  final ponto = t.lastIndexOf('.');
  if (virgula >= 0) {
    // Vírgula é decimal; ponto antes dela é milhar.
    t = '${t.substring(0, virgula).replaceAll('.', '')}.${t.substring(virgula + 1)}';
  } else if (ponto >= 0 && t.length - ponto - 1 == 3 && t.indexOf('.') == ponto && ponto <= 3) {
    // `1.234`: um único ponto seguido de três dígitos é milhar.
    t = t.replaceAll('.', '');
  }
  final valor = double.tryParse(t);
  if (valor == null || valor <= 0 || valor > 1e11) return null;
  return (valor * 100).round();
}

String doisDigitos(int n) => n.toString().padLeft(2, '0');

String chaveDoDia(DateTime d) => '${d.year}-${doisDigitos(d.month)}-${doisDigitos(d.day)}';

String chaveDoMes(DateTime d) => '${d.year}-${doisDigitos(d.month)}';

DateTime diaDaChave(String chave) => DateTime(
      int.parse(chave.substring(0, 4)),
      int.parse(chave.substring(5, 7)),
      int.parse(chave.substring(8, 10)),
    );

String somarDias(String chave, int dias) {
  final d = diaDaChave(chave);
  return chaveDoDia(DateTime(d.year, d.month, d.day + dias));
}

String somarMeses(String mes, int quantos) {
  final d = DateTime(int.parse(mes.substring(0, 4)), int.parse(mes.substring(5, 7)) + quantos);
  return chaveDoMes(d);
}

int diasNoMes(String mes) =>
    DateTime(int.parse(mes.substring(0, 4)), int.parse(mes.substring(5, 7)) + 1, 0).day;

/// Dia `dia` do mês, limitado ao último dia dele.
String diaNoMes(String mes, int dia) =>
    '$mes-${doisDigitos(dia.clamp(1, diasNoMes(mes)))}';

const _meses = [
  'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
  'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
];
const _semana = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];

String nomeDoMes(String mes) {
  final nome = _meses[int.parse(mes.substring(5, 7)) - 1];
  return '${nome[0].toUpperCase()}${nome.substring(1)} de ${mes.substring(0, 4)}';
}

/// `hoje`, `ontem`, `amanhã` ou `qui, 12 nov`.
String diaPorExtenso(String chave, String hoje) {
  if (chave == hoje) return 'hoje';
  if (chave == somarDias(hoje, -1)) return 'ontem';
  if (chave == somarDias(hoje, 1)) return 'amanhã';
  final d = diaDaChave(chave);
  final ano = chave.substring(0, 4) == hoje.substring(0, 4) ? '' : ' ${d.year}';
  return '${_semana[d.weekday - 1]}, ${d.day} ${_meses[d.month - 1].substring(0, 3)}$ano';
}
