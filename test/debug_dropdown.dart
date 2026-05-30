import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Dropdown with Expanded inside Row', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
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
                        Expanded(child: const Text('Long text that should be expanded safely within the dropdown menu item')),
                      ],
                    ),
                  ),
                ],
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.textContaining('Long text'), findsOneWidget);
  });
}
