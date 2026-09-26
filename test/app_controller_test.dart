import 'dart:async';
import 'dart:convert';

import 'package:farreach/services/api_client.dart';
import 'package:farreach/services/token_store.dart';
import 'package:farreach/state/app_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('offline saved names reconcile with the seeded live catalog', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final api = ApiClient(
      baseUrl: 'http://example.test',
      client: MockClient(
        (_) async => http.Response(
          '''{"spots":[{"id":41,"name":"Cox's Bazar Sea Beach","category":"beach","district_name":"Cox's Bazar","division_name":"Chattogram"}]}''',
          200,
        ),
      ),
    );
    final controller = AppController(
      api: api,
      preferences: preferences,
      tokenStore: MemoryTokenStore(),
    );

    await controller.toggleSaved(controller.destinations.first);
    await controller.refreshDestinations();

    expect(controller.savedDestinations, hasLength(1));
    expect(controller.savedDestinations.single.id, 41);
    controller.dispose();
  });

  test(
    'device saves are claimed by one account and not leaked to another',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final api = ApiClient(
        baseUrl: 'http://example.test',
        client: MockClient((request) async {
          if (request.url.path == '/api/auth/login') {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            final firstAccount = body['email'] == 'one@example.com';
            return http.Response(
              jsonEncode({
                'token': firstAccount ? 'token-one' : 'token-two',
                'user': {
                  'id': firstAccount ? 11 : 22,
                  'name': firstAccount ? 'One' : 'Two',
                  'email': body['email'],
                  'role': 'user',
                },
              }),
              200,
            );
          }
          if (request.url.path == '/api/user/saved-spots') {
            return http.Response('{"spots":[]}', 200);
          }
          if (request.url.path == '/api/user/bookings') {
            return http.Response('{"bookings":[]}', 200);
          }
          if (request.url.path == '/api/auth/logout') {
            return http.Response('{"ok":true}', 200);
          }
          return http.Response('{"error":"unexpected request"}', 500);
        }),
      );
      final controller = AppController(
        api: api,
        preferences: preferences,
        tokenStore: MemoryTokenStore(),
      );

      await controller.toggleSaved(controller.destinations.first);
      await controller.login('one@example.com', 'password123');
      expect(controller.savedDestinations, hasLength(1));

      await controller.logout();
      expect(controller.savedDestinations, isEmpty);

      await controller.login('two@example.com', 'password123');
      expect(controller.savedDestinations, isEmpty);

      controller.dispose();
    },
  );

  test('a delayed saved sync cannot leak across account switches', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final delayedUserOneSync = Completer<http.Response>();
    final delayedSyncStarted = Completer<void>();
    var userOneSavedReads = 0;

    final api = ApiClient(
      baseUrl: 'http://example.test',
      client: MockClient((request) async {
        if (request.url.path == '/api/auth/login') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final firstAccount = body['email'] == 'one@example.com';
          return http.Response(
            jsonEncode({
              'token': firstAccount ? 'token-one' : 'token-two',
              'user': {
                'id': firstAccount ? 11 : 22,
                'name': firstAccount ? 'One' : 'Two',
                'email': body['email'],
                'role': 'user',
              },
            }),
            200,
          );
        }
        if (request.url.path == '/api/spots') {
          return http.Response(
            '''{"spots":[{"id":41,"name":"Cox's Bazar Sea Beach","category":"beach","district_name":"Cox's Bazar","division_name":"Chattogram"}]}''',
            200,
          );
        }
        if (request.url.path == '/api/user/saved-spots') {
          final authorization = request.headers['authorization'];
          if (authorization == 'Bearer token-one') {
            userOneSavedReads += 1;
            if (userOneSavedReads == 2) {
              delayedSyncStarted.complete();
              return delayedUserOneSync.future;
            }
          }
          return http.Response('{"spots":[]}', 200);
        }
        if (request.url.path == '/api/user/bookings') {
          return http.Response('{"bookings":[]}', 200);
        }
        if (request.url.path == '/api/auth/logout') {
          return http.Response('{"ok":true}', 200);
        }
        return http.Response('{"error":"unexpected request"}', 500);
      }),
    );
    final controller = AppController(
      api: api,
      preferences: preferences,
      tokenStore: MemoryTokenStore(),
    );

    await controller.login('one@example.com', 'password123');
    await controller.refreshDestinations();
    await delayedSyncStarted.future;
    await controller.logout();
    await controller.login('two@example.com', 'password123');

    delayedUserOneSync.complete(
      http.Response(
        '''{"spots":[{"id":41,"name":"Cox's Bazar Sea Beach","category":"beach","district_name":"Cox's Bazar","division_name":"Chattogram"}]}''',
        200,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(controller.user?.id, 22);
    expect(controller.savedDestinations, isEmpty);
    expect(
      preferences.getStringList('farreach_saved_names_user_22_v2'),
      isEmpty,
    );
    controller.dispose();
  });
}
