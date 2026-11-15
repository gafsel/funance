import 'package:flutter/material.dart';

import '../modelo/modelos.dart';
import '../regras/formatos.dart';
import '../tema/tema_novo.dart';

/// Cartão padrão: papel com borda fina, sem sombra.
class Cartao extends StatelessWidget {
  const Cartao({super.key, required this.child, this.onTap, this.padding, this.cor, this.semBorda = false});
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? cor;
  final bool semBorda;

  @override
  Widget build(BuildContext context) {
    final c = Cores.de(context);
    final conteudo = Padding(padding: padding ?? const EdgeInsets.all(Espacos.g), child: child);
    return Material(
      color: cor ?? c.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: Raios.g,
        side: semBorda ? BorderSide.none : BorderSide(color: c.linha),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? conteudo : InkWell(onTap: onTap, child: conteudo),
    );
  }
}

/// Cartão de lista: linhas separadas por um fio.
class Lista extends StatelessWidget {
  const Lista({super.key, required this.filhos});
  final List<Widget> filhos;

  @override
  Widget build(BuildContext context) => Cartao(
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < filhos.length; i++) ...[
              if (i > 0) const Divider(),
              filhos[i],
            ],
          ],
        ),
      );
}

/// Título de seção, com um detalhe ou uma ação à direita.
class TituloDeSecao extends StatelessWidget {
  const TituloDeSecao(this.texto, {super.key, this.acao, this.detalhe, this.semTopo = false});
  final String texto;
  final Widget? acao;
  final String? detalhe;
  final bool semTopo;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(top: semTopo ? 0 : Espacos.xg, bottom: Espacos.p),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: Text(texto, style: t.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
          if (detalhe != null) Text(detalhe!, style: t.bodySmall),
          ?acao,
        ],
      ),
    );
  }
}

enum Tom { neutro, primario, bom, atencao, problema, calor }

/// Etiqueta em pílula. O tom diz o que ela comunica, não a cor.
class Etiqueta extends StatelessWidget {
  const Etiqueta(this.texto, {super.key, this.tom = Tom.neutro, this.cor});
  final String texto;
  final Tom tom;

  /// Compatibilidade: uma cor de texto solta vira o tom mais próximo.
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    final c = Cores.de(context);
    var t = tom;
    if (cor != null && t == Tom.neutro) {
      t = cor == c.positivo ? Tom.bom : (cor == c.problema ? Tom.problema : Tom.atencao);
    }
    final (fundo, tinta, borda) = switch (t) {
      Tom.neutro => (c.superficie, c.tinta2, c.linha),
      Tom.primario => (c.primariaSuave, c.tinta, c.primariaSuave),
      Tom.bom => (c.positivoSuave, c.positivo, c.positivoSuave),
      Tom.atencao => (c.atencaoSuave, c.atencao, c.atencaoSuave),
      Tom.problema => (c.problemaSuave, c.problema, c.problemaSuave),
      Tom.calor => (c.calorSuave, c.tinta, c.calorSuave),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2.5),
      decoration: BoxDecoration(color: fundo, borderRadius: Raios.pilula, border: Border.all(color: borda)),
      child: Text(
        texto,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: tinta),
      ),
    );
  }
}

/// Seletor em segmentos, no lugar de abas: um trilho suave com a opção
/// escolhida em papel. Os rótulos nunca quebram linha; se não couberem,
/// encolhem.
class Segmentos<T> extends StatelessWidget {
  const Segmentos({super.key, required this.opcoes, required this.valor, required this.aoMudar, this.largo = true});

  /// (valor, rótulo).
  final List<(T, String)> opcoes;
  final T valor;
  final ValueChanged<T> aoMudar;

  /// Ocupa a largura disponível, com as opções em partes iguais.
  final bool largo;

  @override
  Widget build(BuildContext context) {
    final c = Cores.de(context);
    final t = Theme.of(context).textTheme;
    Widget opcao((T, String) o) {
      final escolhida = o.$1 == valor;
      final botao = Material(
        color: escolhida ? c.superficie : c.suave,
        borderRadius: Raios.p,
        elevation: escolhida ? 0.6 : 0,
        shadowColor: c.tinta,
        child: InkWell(
          borderRadius: Raios.p,
          onTap: () => aoMudar(o.$1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                o.$2,
                maxLines: 1,
                softWrap: false,
                style: t.labelLarge?.copyWith(color: escolhida ? c.tinta : c.tinta2),
              ),
            ),
          ),
        ),
      );
      return largo ? Expanded(child: botao) : botao;
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: c.suave, borderRadius: Raios.m),
      child: Row(
        mainAxisSize: largo ? MainAxisSize.max : MainAxisSize.min,
        children: [
          for (var i = 0; i < opcoes.length; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            opcao(opcoes[i]),
          ],
        ],
      ),
    );
  }
}

/// Barra de progresso fina.
class Barra extends StatelessWidget {
  const Barra(this.fracao, {super.key, this.cor, this.trilho});
  final double fracao;
  final Color? cor;
  final Color? trilho;

  @override
  Widget build(BuildContext context) {
    final c = Cores.de(context);
    return ClipRRect(
      borderRadius: Raios.pilula,
      child: LinearProgressIndicator(
        value: fracao.clamp(0, 1).toDouble(),
        minHeight: 8,
        backgroundColor: trilho ?? c.suave,
        color: cor ?? c.primaria,
      ),
    );
  }
}

/// Botão pequeno de contorno, para ação dentro de uma linha ("Paguei").
class BotaoPequeno extends StatelessWidget {
  const BotaoPequeno(this.rotulo, {super.key, this.aoTocar, this.cheio = false, this.icone});
  final String rotulo;
  final VoidCallback? aoTocar;
  final bool cheio;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme.labelLarge;
    const forma = EdgeInsets.symmetric(horizontal: 12, vertical: 6);
    final filho = Row(mainAxisSize: MainAxisSize.min, children: [
      if (icone != null) ...[Icon(icone, size: 16), const SizedBox(width: 6)],
      Text(rotulo, maxLines: 1, softWrap: false),
    ]);
    return cheio
        ? FilledButton(
            onPressed: aoTocar,
            style: FilledButton.styleFrom(minimumSize: const Size(0, 32), padding: forma, textStyle: texto),
            child: filho,
          )
        : OutlinedButton(
            onPressed: aoTocar,
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 32), padding: forma, textStyle: texto),
            child: filho,
          );
  }
}

/// Linha de lista: título e detalhe à esquerda; à direita, o que vier.
class Linha extends StatelessWidget {
  const Linha({super.key, required this.titulo, this.detalhe, this.direita, this.aoTocar, this.corDoDetalhe, this.antes});
  final String titulo;
  final String? detalhe;
  final Widget? direita;
  final Widget? antes;
  final VoidCallback? aoTocar;
  final Color? corDoDetalhe;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final conteudo = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          if (antes != null) ...[antes!, const SizedBox(width: 10)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(titulo, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                if (detalhe != null)
                  Text(detalhe!, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodySmall?.copyWith(color: corDoDetalhe)),
              ],
            ),
          ),
          if (direita != null) ...[const SizedBox(width: 10), direita!],
        ],
      ),
    );
    return aoTocar == null ? conteudo : InkWell(onTap: aoTocar, child: conteudo);
  }
}

/// Cor do valor de um lançamento. Despesa é tinta normal, não vermelho:
/// gastar não é erro. Entrada é verde; transferência e previsto, suaves.
Color corDoValor(BuildContext context, Lancamento l) {
  final c = Cores.de(context);
  if (l.situacao == 'cancelado' || l.ehTransferencia) return c.tinta2;
  if (l.ehEntrada) return c.positivo;
  return l.efetivado ? c.tinta : c.tinta2;
}

String valorComSinal(Lancamento l) =>
    '${l.ehEntrada ? '+' : (l.ehSaida ? '-' : '')}${reais(l.valorCentavos)}';

/// Quando o lançamento aconteceu ou vence, em poucas palavras.
String quandoDoLancamento(Lancamento l, String hoje) {
  if (!l.previsto) return diaPorExtenso(l.dia, hoje);
  final dia = diaPorExtenso(l.data, hoje);
  return l.data.compareTo(hoje) < 0 ? 'Venceu $dia' : 'Vence $dia';
}

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
    final atrasado = l.previsto && l.data.compareTo(hoje) < 0;
    final detalhes = [
      quandoDoLancamento(l, hoje),
      if (l.ehTransferencia) '${conta?.nome ?? '?'} → ${destino?.nome ?? '?'}' else conta?.nome ?? '?',
      if (categoria != null) categoria!.nome,
      if (l.parcelaNumero != null) '${l.parcelaNumero}/${l.parcelaTotal}',
    ].join(' · ');

    return Linha(
      titulo: l.descricao.isEmpty ? 'Sem descrição' : l.descricao,
      detalhe: detalhes,
      corDoDetalhe: atrasado ? c.atencao : null,
      aoTocar: onTap,
      direita: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(valorComSinal(l), style: Textos.valor(context, cor: corDoValor(context, l))),
          if (acao != null) ...[const SizedBox(width: 10), acao!],
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: Espacos.g, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              texto,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Cores.de(context).tinta3, fontSize: 13),
            ),
            if (acao != null) ...[const SizedBox(height: Espacos.m), acao!],
          ],
        ),
      );
}

/// Página com rolagem, margens da tela e largura máxima. Na mesa o conteúdo
/// fica alinhado à esquerda, como numa ferramenta de trabalho.
class Pagina extends StatelessWidget {
  const Pagina({super.key, required this.filhos, this.larguraMaxima = 1040, this.centralizada = false});
  final List<Widget> filhos;
  final double larguraMaxima;
  final bool centralizada;

  @override
  Widget build(BuildContext context) {
    final margem = margemDaTela(context);
    return Align(
      alignment: centralizada ? Alignment.topCenter : Alignment.topLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: larguraMaxima + margem * 2),
        child: ListView(
          padding: EdgeInsets.fromLTRB(margem, ehMesa(context) ? 20 : Espacos.g, margem, 32),
          children: filhos,
        ),
      ),
    );
  }
}

/// Fila de botões: lado a lado na mesa, empilhados e largos no celular.
class Acoes extends StatelessWidget {
  const Acoes({super.key, required this.filhos});
  final List<Widget> filhos;

  @override
  Widget build(BuildContext context) => ehMesa(context)
      ? Wrap(spacing: Espacos.p, runSpacing: Espacos.p, children: filhos)
      : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < filhos.length; i++) ...[
              if (i > 0) const SizedBox(height: Espacos.p),
              filhos[i],
            ],
          ],
        );
}

/// Marca do app: um quadrado de cantos redondos com três degraus e um ponto.
class Marca extends StatelessWidget {
  const Marca({super.key, this.tamanho = 24});
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
    final l = size.width;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(l * 0.26)),
      Paint()..color = c.primaria,
    );
    final degrau = Paint()..color = c.sobrePrimaria;
    final u = l / 10;
    for (var i = 0; i < 3; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH((2.2 + i * 2) * u, (6.4 - i * 1.5) * u, 1.6 * u, (1.6 + i * 1.5) * u),
          Radius.circular(u * 0.4),
        ),
        degrau,
      );
    }
    canvas.drawCircle(Offset(7 * u, 2.3 * u), 0.85 * u, Paint()..color = c.calor);
  }

  @override
  bool shouldRepaint(_MarcaPainter antigo) => antigo.c != c;
}
