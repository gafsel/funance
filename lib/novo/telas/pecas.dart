import 'package:flutter/material.dart';

import '../modelo/modelos.dart';
import '../regras/formatos.dart';
import '../tema/tema_novo.dart';

/// Cartão padrão: superfície com borda fina, sem sombra.
class Cartao extends StatelessWidget {
  const Cartao({super.key, required this.child, this.onTap, this.padding});
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final conteudo = Padding(padding: padding ?? const EdgeInsets.all(Espacos.g), child: child);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? conteudo : InkWell(onTap: onTap, child: conteudo),
    );
  }
}

class TituloDeSecao extends StatelessWidget {
  const TituloDeSecao(this.texto, {super.key, this.acao});
  final String texto;
  final Widget? acao;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: Espacos.xg, bottom: Espacos.p),
        child: Row(
          children: [
            Expanded(child: Text(texto, style: Theme.of(context).textTheme.titleMedium)),
            ?acao,
          ],
        ),
      );
}

/// Etiqueta pequena (situação, parcela).
class Etiqueta extends StatelessWidget {
  const Etiqueta(this.texto, {super.key, this.cor});
  final String texto;
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    final c = Cores.de(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Espacos.p, vertical: 2),
      decoration: BoxDecoration(color: c.superficieAlta, borderRadius: Raios.pilula),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cor ?? c.tintaSuave),
      ),
    );
  }
}

/// Cor do valor de um lançamento. Despesa é tinta normal, não vermelho:
/// gastar não é erro. Entrada é verde; transferência e previsto, suaves.
Color corDoValor(BuildContext context, Lancamento l) {
  final c = Cores.de(context);
  if (l.situacao == 'cancelado' || l.ehTransferencia) return c.tintaSuave;
  if (l.ehEntrada) return c.positivo;
  return l.efetivado ? c.tinta : c.tintaSuave;
}

String valorComSinal(Lancamento l) =>
    '${l.ehEntrada ? '+' : (l.ehSaida ? '-' : '')}${reais(l.valorCentavos)}';

class LinhaDeLancamento extends StatelessWidget {
  const LinhaDeLancamento({
    super.key,
    required this.lancamento,
    required this.hoje,
    this.conta,
    this.destino,
    this.categoria,
    this.onTap,
    this.acao,
  });

  final Lancamento lancamento;
  final String hoje;
  final Conta? conta;
  final Conta? destino;
  final Categoria? categoria;
  final VoidCallback? onTap;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    final l = lancamento;
    final c = Cores.de(context);
    final texto = Theme.of(context).textTheme;
    final atrasado = l.previsto && l.data.compareTo(hoje) < 0;
    final detalhes = [
      if (l.ehTransferencia) '${conta?.nome ?? '?'} → ${destino?.nome ?? '?'}' else conta?.nome ?? '?',
      if (categoria != null) categoria!.nome,
      if (l.parcelaNumero != null) '${l.parcelaNumero}/${l.parcelaTotal}',
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Espacos.g, vertical: Espacos.m),
        child: Row(
          children: [
            Icon(
              l.ehTransferencia
                  ? Icons.swap_horiz_rounded
                  : (l.ehEntrada ? Icons.south_west_rounded : Icons.north_east_rounded),
              size: 20,
              color: l.ehEntrada ? c.positivo : c.tintaSuave,
            ),
            const SizedBox(width: Espacos.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.descricao.isEmpty ? 'Sem descrição' : l.descricao,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: texto.bodyLarge,
                  ),
                  Text(detalhes, maxLines: 1, overflow: TextOverflow.ellipsis, style: texto.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: Espacos.m),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  valorComSinal(l),
                  style: texto.titleMedium?.copyWith(color: corDoValor(context, l)),
                ),
                Text(
                  l.previsto
                      ? (atrasado ? 'venceu ${diaPorExtenso(l.data, hoje)}' : 'vence ${diaPorExtenso(l.data, hoje)}')
                      : diaPorExtenso(l.dia, hoje),
                  style: texto.bodySmall?.copyWith(color: atrasado ? c.atencao : null),
                ),
              ],
            ),
            if (acao != null) ...[const SizedBox(width: Espacos.p), acao!],
          ],
        ),
      ),
    );
  }
}

/// Estado vazio com uma frase e, se fizer sentido, o próximo passo.
class Vazio extends StatelessWidget {
  const Vazio(this.texto, {super.key, this.acao});
  final String texto;
  final Widget? acao;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(Espacos.xg),
        child: Column(
          children: [
            Text(texto, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            if (acao != null) ...[const SizedBox(height: Espacos.m), acao!],
          ],
        ),
      );
}

/// Marca do app: três degraus e um ponto, de `Suas metas, um passo por vez`.
class Marca extends StatelessWidget {
  const Marca({super.key, this.tamanho = 28});
  final double tamanho;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(tamanho), painter: _MarcaPainter(Cores.de(context)));
}

class _MarcaPainter extends CustomPainter {
  _MarcaPainter(this.c);
  final Cores c;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 8;
    final degrau = Paint()..color = c.primaria;
    for (var i = 0; i < 3; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(i * 2.5 * u, size.height - (i + 1) * 2 * u, 2 * u, (i + 1) * 2 * u),
          Radius.circular(u / 2),
        ),
        degrau,
      );
    }
    canvas.drawCircle(Offset(6 * u, 0.9 * u), 0.9 * u, Paint()..color = c.calor);
  }

  @override
  bool shouldRepaint(_MarcaPainter antigo) => antigo.c != c;
}
