import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dados/avisos.dart';
import '../dados/provedores.dart';
import '../modelo/modelos.dart';
import '../regras/formatos.dart';
import '../tema/tema_novo.dart';
import 'formulario.dart';
import 'pecas.dart';

/// O sino do topo: abre os avisos e mostra um ponto quando há novos.
class BotaoDeAvisos extends ConsumerWidget {
  const BotaoDeAvisos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = Cores.de(context);
    final novos = ref.watch(avisosNovosProvider);
    return IconButton(
      tooltip: novos == 0 ? 'Avisos' : '$novos ${novos == 1 ? 'aviso novo' : 'avisos novos'}',
      visualDensity: VisualDensity.compact,
      onPressed: () => abrirFolha<void>(context, (_) => const _FolhaDeAvisos(), largura: 520, alta: true),
      icon: Stack(clipBehavior: Clip.none, children: [
        Icon(novos == 0 ? Icons.notifications_none_rounded : Icons.notifications_rounded, size: 22, color: c.tinta2),
        if (novos > 0)
          Positioned(
            right: -1,
            top: -1,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: c.calor, shape: BoxShape.circle, border: Border.all(color: c.superficie, width: 1.5)),
            ),
          ),
      ]),
    );
  }
}

IconData _icone(String tipo) => switch (tipo) {
      'vencimentos' => Icons.event_rounded,
      'semLancar' => Icons.edit_calendar_rounded,
      _ => Icons.weekend_rounded,
    };

class _FolhaDeAvisos extends ConsumerStatefulWidget {
  const _FolhaDeAvisos();

  @override
  ConsumerState<_FolhaDeAvisos> createState() => _FolhaDeAvisosState();
}

class _FolhaDeAvisosState extends ConsumerState<_FolhaDeAvisos> {
  Aparelho? _aparelho;
  bool _mexendo = false;

  /// Os que eram novos quando a folha abriu continuam marcados enquanto ela
  /// está aberta, mesmo depois de registrados como vistos.
  late final Set<String> _eramNovos;

  @override
  void initState() {
    super.initState();
    final ate = instanteDe(ref.read(usuarioProvider).valueOrNull?['avisosVistosEm']);
    _eramNovos = {
      for (final a in ref.read(avisosProvider).valueOrNull ?? const <Aviso>[])
        if (a.criadoEm != null && (ate == null || a.criadoEm!.isAfter(ate))) a.id,
    };
    final uid = ref.read(authProvider).valueOrNull?.uid;
    if (uid != null && _eramNovos.isNotEmpty) marcarAvisosComoVistos(uid);
    situacaoDoAparelho(ref.read(usuarioProvider).valueOrNull ?? const {}).then((s) {
      if (mounted) setState(() => _aparelho = s);
    });
  }

  Future<void> _alternarAparelho(String uid) async {
    setState(() => _mexendo = true);
    if (_aparelho == Aparelho.ligado) {
      await desligarAvisosNesteAparelho(uid);
      if (mounted) setState(() => _aparelho = Aparelho.desligado);
    } else {
      final ficou = await ligarAvisosNesteAparelho(uid);
      if (mounted) setState(() => _aparelho = ficou);
    }
    if (mounted) setState(() => _mexendo = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = Cores.de(context);
    final t = Theme.of(context).textTheme;
    final hoje = ref.watch(hojeProvider);
    final uid = ref.watch(authProvider).valueOrNull?.uid;
    final avisos = ref.watch(avisosProvider).valueOrNull ?? const <Aviso>[];
    final usuario = ref.watch(usuarioProvider).valueOrNull ?? const <String, dynamic>{};
    final preferencias = usuario['avisos'] is Map ? usuario['avisos'] as Map : const {};

    return ListView(
      padding: const EdgeInsets.fromLTRB(Espacos.g, 0, Espacos.g, Espacos.g),
      children: [
        Text('Avisos', style: t.titleLarge),
        const SizedBox(height: Espacos.m),
        if (avisos.isEmpty)
          const Cartao(padding: EdgeInsets.zero, child: Vazio('Nenhum aviso por enquanto. Vencimentos, lembretes e alertas de limite aparecem aqui.'))
        else
          Lista(filhos: [
            for (final a in avisos)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(color: _eramNovos.contains(a.id) ? c.calorSuave : c.suave, borderRadius: Raios.p),
                    child: Icon(_icone(a.tipo), size: 17, color: c.tinta2),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(a.titulo, style: t.titleSmall)),
                        Text(diaPorExtenso(a.dia, hoje), style: t.bodySmall),
                      ]),
                      const SizedBox(height: 2),
                      Text(a.texto, style: t.bodySmall?.copyWith(color: c.tinta2)),
                    ]),
                  ),
                ]),
              ),
          ]),
        const TituloDeSecao('Notificações'),
        Cartao(
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Neste aparelho', style: t.titleSmall),
                const SizedBox(height: 2),
                Text(
                  switch (_aparelho) {
                    null => 'Conferindo…',
                    Aparelho.ligado => 'Ligadas. Os avisos chegam aqui mesmo com o app fechado.',
                    Aparelho.desligado => 'Desligadas. Os avisos só aparecem nesta lista.',
                    Aparelho.bloqueado => 'O navegador está bloqueando. Libere as notificações deste site nas configurações dele.',
                    Aparelho.indisponivel => 'Por enquanto só no navegador (ou no app instalado a partir dele). Os avisos aparecem nesta lista.',
                  },
                  style: t.bodySmall,
                ),
              ]),
            ),
            if (uid != null && (_aparelho == Aparelho.ligado || _aparelho == Aparelho.desligado)) ...[
              const SizedBox(width: Espacos.m),
              BotaoPequeno(
                _aparelho == Aparelho.ligado ? 'Desligar' : 'Ligar',
                cheio: _aparelho != Aparelho.ligado,
                aoTocar: _mexendo ? null : () => _alternarAparelho(uid),
              ),
            ],
          ]),
        ),
        const SizedBox(height: Espacos.m),
        Lista(filhos: [
          for (final (tipo, nome, quando) in tiposDeAviso)
            SwitchListTile(
              dense: true,
              title: Text(nome, style: t.titleSmall),
              subtitle: Text(quando, style: t.bodySmall),
              value: preferencias[tipo] != false,
              onChanged: uid == null ? null : (ligado) => definirAviso(uid, tipo, ligado),
            ),
        ]),
        const SizedBox(height: Espacos.p),
        Text('Vale para você, em todos os seus espaços e aparelhos.', style: t.bodySmall),
      ],
    );
  }
}
