import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dados/provedores.dart';
import '../modelo/modelos.dart';
import '../regras/formatos.dart';
import '../tema/tema_novo.dart';
import 'categorias.dart';
import 'comeco.dart';
import 'fatura.dart';
import 'fechamento.dart';
import 'revisao.dart';
import 'formulario.dart';
import 'pecas.dart';

class TelaMais extends ConsumerWidget {
  const TelaMais({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contas = ref.watch(contasProvider).valueOrNull ?? const <Conta>[];
    final saldos = ref.watch(saldosProvider);
    final usuario = ref.watch(authProvider).valueOrNull;
    final espacos = ref.watch(espacosProvider).valueOrNull ?? const <Espaco>[];
    final atual = ref.watch(espacoAtualProvider);
    final texto = Theme.of(context).textTheme;
    final ativas = contas.where((c) => !c.arquivada).toList()..sort((a, b) => a.nome.compareTo(b.nome));

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Espacos.g, Espacos.g, Espacos.g, 96),
          children: [
            const TituloDeSecao('Espaços'),
            Cartao(
              padding: const EdgeInsets.symmetric(vertical: Espacos.p),
              child: Column(children: [
                for (final e in espacos)
                  ListTile(
                    leading: Icon(e.ehEmpresa ? Icons.storefront_outlined : Icons.home_outlined),
                    title: Text(e.nome),
                    subtitle: Text(e.ehEmpresa ? 'Empresa' : 'Pessoal'),
                    trailing: e.id == atual?.id ? const Icon(Icons.check_rounded) : null,
                    onTap: () => lembrarEspaco(ref, e.id),
                  ),
                ListTile(
                  leading: const Icon(Icons.add_rounded),
                  title: const Text('Novo espaço'),
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute<void>(builder: (_) => const TelaComeco(podeVoltar: true))),
                ),
              ]),
            ),
            const TituloDeSecao('Organizar'),
            Cartao(
              padding: const EdgeInsets.symmetric(vertical: Espacos.p),
              child: Column(children: [
                ListTile(
                  leading: const Icon(Icons.label_outline_rounded),
                  title: Text(atual?.ehEmpresa == true ? 'Centros de custo e limites' : 'Categorias e limites'),
                  onTap: () => abrirCategorias(context),
                ),
                ListTile(
                  leading: const Icon(Icons.fact_check_outlined),
                  title: const Text('Fechar o mês'),
                  onTap: () => abrirFechamento(context, ref.read(hojeProvider).substring(0, 7)),
                ),
                ListTile(
                  leading: const Icon(Icons.event_repeat_outlined),
                  title: const Text('Revisão da semana'),
                  onTap: () => abrirRevisao(context),
                ),
              ]),
            ),
            const TituloDeSecao('Contas e cartões'),
            Cartao(
              padding: const EdgeInsets.symmetric(vertical: Espacos.p),
              child: Column(children: [
                for (final c in ativas)
                  ListTile(
                    title: Text(c.nome),
                    subtitle: Text(rotulosDeConta[c.tipo] ?? c.tipo),
                    trailing: Text(reais(saldos[c.id] ?? 0), style: texto.titleMedium),
                    onTap: c.ehCartao ? () => abrirCartao(context, c) : null,
                  ),
                if (ativas.isEmpty) const Vazio('Nenhuma conta neste espaço.'),
              ]),
            ),
            const TituloDeSecao('Você'),
            Cartao(
              padding: const EdgeInsets.symmetric(vertical: Espacos.p),
              child: Column(children: [
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded),
                  title: Text(usuario?.displayName ?? usuario?.email ?? 'Conta'),
                  subtitle: usuario?.displayName != null ? Text(usuario?.email ?? '') : null,
                ),
                ListTile(
                  leading: const Icon(Icons.logout_rounded),
                  title: const Text('Sair'),
                  onTap: () => FirebaseAuth.instance.signOut(),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
