import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/form/responsive_grid.dart';

void main() {
  testWidgets('Reproduce hasSize error in ResponsiveGrid with Dropdown', (WidgetTester tester) async {
    // Simula uma tela grande para disparar a lógica do grid
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ResponsiveGrid(
              spacing: 16,
              children: [
                DropdownButtonFormField<String>(
                  value: '1',
                  items: [
                    DropdownMenuItem(
                      value: '1',
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance),
                          const SizedBox(width: 8),
                          Expanded(child: const Text('Account 1')),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (_) {},
                ),
                TextFormField(initialValue: 'Field 2'),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Account 1'), findsOneWidget);
    
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
