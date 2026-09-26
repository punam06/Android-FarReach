import 'package:farreach/services/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('fails safely when live services are not configured', () async {
    final api = ApiClient(baseUrl: '');

    await expectLater(
      api.getDestinations(),
      throwsA(
        isA<ApiFailure>().having(
          (error) => error.message,
          'message',
          contains('not configured'),
        ),
      ),
    );
    api.close();
  });

  test('loads destinations from the FarReach API contract', () async {
    final api = ApiClient(
      baseUrl: 'http://example.test',
      client: MockClient((request) async {
        expect(request.url.path, '/api/spots');
        return http.Response(
          '''{"spots":[{"id":7,"name":"Ahsan Manzil","category":"History","district_name":"Dhaka","division_name":"Dhaka","budget_category":"Low","latitude":"23.7","longitude":"90.4"}]}''',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final destinations = await api.getDestinations();

    expect(destinations, hasLength(1));
    expect(destinations.single.name, 'Ahsan Manzil');
    expect(destinations.single.latitude, 23.7);
  });

  test('sends the bearer token when saving a destination', () async {
    final api = ApiClient(
      baseUrl: 'http://example.test',
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/user/saved-spots');
        expect(request.headers['authorization'], 'Bearer session-token');
        expect(request.body, contains('"spot_id":9'));
        return http.Response('{"ok":true}', 200);
      }),
    )..token = 'session-token';

    await api.saveDestination(9);
  });

  test('surfaces backend errors as readable ApiFailure', () async {
    final api = ApiClient(
      baseUrl: 'http://example.test',
      client: MockClient(
        (_) async => http.Response('{"error":"sign in required"}', 401),
      ),
    );

    expect(
      api.getMe(),
      throwsA(
        isA<ApiFailure>()
            .having((error) => error.statusCode, 'statusCode', 401)
            .having((error) => error.message, 'message', 'sign in required'),
      ),
    );
  });

  test('resends signup codes through the current backend route', () async {
    final api = ApiClient(
      baseUrl: 'http://example.test',
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/auth/signup/resend');
        expect(request.body, contains('person@example.com'));
        return http.Response('{"delivery":"mock","previewCode":"654321"}', 200);
      }),
    );

    final result = await api.resendSignup('person@example.com');

    expect(result.delivery, 'mock');
    expect(result.previewCode, '654321');
  });
}
