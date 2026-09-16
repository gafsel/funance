import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/finance/presentation/widgets/detail_header.dart';

Widget _buildApp({required double expandedHeight}) {
  return MaterialApp(
    home: Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverDetailHeader(
            title: 'Cartão Nubank Ultravioleta',
            subtitle: r'R$ 12.345,67',
            expandedHeight: expandedHeight,
            chips: [
              DetailHeaderChip(icon: Icons.schedule, label: 'Pendente'),
              DetailHeaderChip(icon: Icons.calendar_today, label: '10/09/2026'),
            ],
            actions: [
              DetailHeaderAction(
                icon: Icons.payment,
                label: 'Registrar pagamento',
                onPressed: () {},
              ),
              DetailHeaderAction(
                icon: Icons.edit_outlined,
                label: 'Editar',
                onPressed: () {},
              ),
            ],
            bottomContent: const Padding(
              padding: EdgeInsets.all(20),
              child: SizedBox(height: 120, width: double.infinity),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => ListTile(title: Text('item $i')),
              childCount: 30,
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _pumpAtSize(
  WidgetTester tester,
  Size size, {
  double textScale = 1.0,
  double expandedHeight = 480,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
      ),
      child: _buildApp(expandedHeight: expandedHeight),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('header não estoura em celular pequeno', (tester) async {
    await _pumpAtSize(tester, const Size(320, 568));
    expect(tester.takeException(), isNull);
  });

  testWidgets('header não estoura com fonte do sistema aumentada', (
    tester,
  ) async {
    await _pumpAtSize(tester, const Size(360, 640), textScale: 1.3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('header não estoura em landscape baixo', (tester) async {
    await _pumpAtSize(tester, const Size(640, 360));
    expect(tester.takeException(), isNull);
  });

  testWidgets('header não estoura em desktop largo', (tester) async {
    await _pumpAtSize(tester, const Size(1400, 900), expandedHeight: 320);
    expect(tester.takeException(), isNull);
  });
}
