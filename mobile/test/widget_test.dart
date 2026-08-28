import 'package:farreach/main.dart';
import 'package:farreach/services/api_client.dart';
import 'package:farreach/services/token_store.dart';
import 'package:farreach/state/app_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('FarReach opens the offline Explore experience', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = AppController(
      api: ApiClient(
        baseUrl: 'http://example.test',
        client: MockClient((_) async => http.Response('{"spots":[]}', 200)),
      ),
      preferences: preferences,
      tokenStore: MemoryTokenStore(),
    );

    await tester.pumpWidget(FarReachApp(controller: controller));
    await tester.pump();

    expect(find.text('FarReach'), findsOneWidget);
    expect(find.text('Explore Bangladesh'), findsOneWidget);
    expect(find.text("Cox's Bazar"), findsWidgets);
    expect(find.text('Explore'), findsOneWidget);
    expect(tester.takeException(), isNull);

    controller.dispose();
  });

  testWidgets('Explore phone layout matches its visual baseline', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = AppController(
      api: ApiClient(
        baseUrl: 'http://example.test',
        client: MockClient((_) async => http.Response('{"spots":[]}', 200)),
      ),
      preferences: preferences,
      tokenStore: MemoryTokenStore(),
    );
    await controller.initialize();
    addTearDown(controller.dispose);

    await tester.pumpWidget(FarReachApp(controller: controller));
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/images/coxs_bazar.jpg'),
        tester.element(find.byType(FarReachApp)),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(FarReachApp),
      matchesGoldenFile('goldens/explore_phone.png'),
    );
  });
}
