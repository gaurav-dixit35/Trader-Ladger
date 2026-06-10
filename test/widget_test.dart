// ignore_for_file: avoid_relative_lib_imports

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/core/widgets/app_logo_title.dart';

void main() {
  testWidgets('Trader Ledger branding title renders', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const AppLogoTitle(title: 'Traders'),
          ),
        ),
      ),
    );

    expect(find.text('Traders'), findsOneWidget);
  });
}
