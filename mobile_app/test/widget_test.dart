import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:tourism_app/app.dart';
import 'package:tourism_app/features/auth/presentation/auth_provider.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const TourismApp(),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
