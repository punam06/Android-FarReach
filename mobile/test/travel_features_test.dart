import 'dart:convert';

import 'package:farreach/models/destination.dart';
import 'package:farreach/screens/account_forms_screen.dart';
import 'package:farreach/screens/app_shell.dart';
import 'package:farreach/screens/booking_management_screen.dart';
import 'package:farreach/screens/destination_detail_screen.dart';
import 'package:farreach/screens/profile_screen.dart';
import 'package:farreach/screens/support_screen.dart';
import 'package:farreach/screens/travel_tools_screen.dart';
import 'package:farreach/services/api_client.dart';
import 'package:farreach/services/token_store.dart';
import 'package:farreach/state/app_controller.dart';
import 'package:farreach/widgets/destination_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response response(Map<String, dynamic> body) =>
    http.Response(jsonEncode(body), 200);
const account = {
  'id': 1,
  'name': 'Traveler',
  'email': 'traveler@example.test',
  'phone': '+8801700000000',
  'address': 'Dhaka',
};
const spot = {
  'id': 7,
  'name': 'Lalbagh Fort',
  'district_name': 'Dhaka',
  'category': 'History',
  'budget_category': 'Low',
};
final destination = Destination.fromJson(spot);
Future<AppController> signedIn(ApiClient api) async {
  SharedPreferences.setMockInitialValues({});
  final controller = AppController(
    api: api,
    preferences: await SharedPreferences.getInstance(),
    tokenStore: MemoryTokenStore(),
  );
  await controller.login('traveler@example.test', 'Password-123');
  return controller;
}

void phone(WidgetTester tester, {double width = 412}) {
  tester.view.physicalSize = Size(width, 915);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

http.Response? accountRoutes(http.Request req) => switch (req.url.path) {
  '/api/auth/login' => response({'token': 'session', 'user': account}),
  '/api/user/saved-spots' => response({'spots': []}),
  '/api/user/bookings' => response({'bookings': []}),
  _ => null,
};

void main() {
  test(
    'signup completion submits the proof returned by OTP verification',
    () async {
      final api = ApiClient(
        baseUrl: 'http://example.test',
        client: MockClient((req) async {
          if (req.url.path.endsWith('verify-code')) {
            return response({'verificationToken': 'signup-proof'});
          }
          expect(req.url.path, '/api/auth/signup/set-password');
          expect(jsonDecode(req.body)['verificationToken'], 'signup-proof');
          return response({'token': 'session', 'user': account});
        }),
      );
      addTearDown(api.close);
      await api.verifySignup('traveler@example.test', '123456');
      expect(
        (await api.finishSignup(
          name: 'Traveler',
          email: 'traveler@example.test',
          password: 'Password-123',
        )).token,
        'session',
      );
    },
  );
  testWidgets('signing out after signup returns to an empty sign-in password', (
    tester,
  ) async {
    phone(tester);
    final api = ApiClient(
      baseUrl: 'http://example.test',
      client: MockClient((req) async {
        final auth = accountRoutes(req);
        if (auth != null) return auth;
        return switch (req.url.path) {
          '/api/auth/signup/start' => response({
            'delivery': 'preview',
            'previewCode': '123456',
          }),
          '/api/auth/signup/verify-code' => response({
            'verificationToken': 'signup-proof',
          }),
          '/api/auth/signup/set-password' => response({
            'token': 'session',
            'user': account,
          }),
          '/api/auth/logout' => response({'ok': true}),
          _ => throw StateError('Unexpected request: ${req.url.path}'),
        };
      }),
    );
    SharedPreferences.setMockInitialValues({});
    final controller = AppController(
      api: api,
      preferences: await SharedPreferences.getInstance(),
      tokenStore: MemoryTokenStore(),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(home: ProfileScreen(controller: controller)),
    );
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Traveler');
    await tester.enterText(
      find.byType(TextField).at(1),
      'traveler@example.test',
    );
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Continue'));
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '123456');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Continue'));
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Password-123');
    await tester.enterText(find.byType(TextField).at(1), 'Password-123');
    final create = find.widgetWithText(FilledButton, 'Create account');
    await tester.ensureVisible(create);
    await tester.tap(create);
    await tester.pumpAndSettle();
    expect(controller.isAuthenticated, isTrue);
    await tester.ensureVisible(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(controller.isAuthenticated, isFalse);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Choose a password'), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text,
      isEmpty,
    );
  });
  testWidgets('saved destination opens without duplicate heroes across tabs', (
    tester,
  ) async {
    phone(tester);
    SharedPreferences.setMockInitialValues({
      'farreach_saved_names_guest_v2': ['lalbagh fort'],
    });
    final controller = AppController(
      api: ApiClient(
        baseUrl: 'http://example.test',
        client: MockClient((req) async {
          return req.url.path == '/api/spots'
              ? response({
                  'spots': [spot],
                })
              : response({});
        }),
      ),
      preferences: await SharedPreferences.getInstance(),
      tokenStore: MemoryTokenStore(),
    );
    await controller.initialize();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(home: AppShell(controller: controller)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DestinationCard));
    await tester.pumpAndSettle();
    expect(find.byType(DestinationDetailScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(DestinationCard));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DestinationCard));
    await tester.pumpAndSettle();
    expect(find.byType(DestinationDetailScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'budget calculator uses server breakdown and shows zero day-trip lodging',
    (tester) async {
      phone(tester);
      final api = ApiClient(
        baseUrl: 'http://example.test',
        client: MockClient((req) async {
          if (req.url.path == '/api/pricing') {
            return response({
              'districts': ['Dhaka'],
              'hotel_tiers': {'normal': 1},
              'food_tiers': {'standard': 350},
              'guide_tiers': {'none': 0},
              'transport_modes': ['bus_nonac'],
            });
          }
          expect(req.url.path, '/api/budget/estimate');
          final body = jsonDecode(req.body);
          expect(body['spot_id'], 7);
          expect(body['days'], 1);
          expect(body['persons'], 1);
          return response({
            'estimate': {
              'total': 500,
              'per_person': 500,
              'nights': 0,
              'distance_km': 0,
              'breakdown': {
                'accommodation': 0,
                'food': 350,
                'local_transport': 150,
              },
              'note': 'Planning estimate only.',
            },
          });
        }),
      );
      addTearDown(api.close);
      await tester.pumpWidget(
        MaterialApp(
          home: BudgetScreen(api: api, destination: destination),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Calculate budget'));
      await tester.tap(find.text('Calculate budget'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Estimated trip total'));
      expect(find.text('৳500'), findsWidgets);
      expect(find.text('৳0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'stay search submits dates and shows room totals without claiming availability',
    (tester) async {
      phone(tester);
      final api = ApiClient(
        baseUrl: 'http://example.test',
        client: MockClient((req) async {
          expect(req.url.path, '/api/hotels/search');
          expect(jsonDecode(req.body)['checkin'], isNotEmpty);
          return response({
            'hotels': [
              {
                'name': 'Catalog hotel',
                'price': 2000,
                'rooms': 1,
                'nights': 1,
                'total_estimate': 2000,
                'url': 'https://example.test',
              },
            ],
          });
        }),
      );
      addTearDown(api.close);
      await tester.pumpWidget(
        MaterialApp(
          home: StaysScreen(api: api, destination: destination),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Catalog hotel'), findsOneWidget);
      expect(
        find.textContaining('Availability: check with property'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'ticket creation sends the custom trip category and request details',
    (tester) async {
      phone(tester);
      Map<String, dynamic>? submitted;
      final api = ApiClient(
        baseUrl: 'http://example.test',
        client: MockClient((req) async {
          final auth = accountRoutes(req);
          if (auth != null) return auth;
          expect(req.url.path, '/api/user/tickets');
          submitted = Map<String, dynamic>.from(jsonDecode(req.body) as Map);
          return response({
            'ticket': {'id': 1},
          });
        }),
      );
      final controller = await signedIn(api);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(home: CreateTicketScreen(controller: controller)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('custom trip').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'Sylhet trip');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Two days, three travelers, 15000 BDT.',
      );
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Create ticket'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Create ticket'));
      await tester.pumpAndSettle();
      expect(submitted?['category'], 'custom_trip');
      expect(submitted?['subject'], 'Sylhet trip');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'chat offers deliberate ticket creation after a support response',
    (tester) async {
      phone(tester, width: 320);
      final api = ApiClient(
        baseUrl: 'http://example.test',
        client: MockClient((req) async {
          final auth = accountRoutes(req);
          if (auth != null) return auth;
          if (req.method == 'GET') return response({'messages': []});
          expect(req.url.path, '/api/chatbot/messages');
          expect(jsonDecode(req.body)['message'], 'Custom trip help');
          return response({
            'reply': 'Create a support ticket with your preferred dates.',
            'action': 'create_ticket',
          });
        }),
      );
      final controller = await signedIn(api);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(home: ChatScreen(controller: controller)),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Custom trip help');
      await tester.tap(find.byTooltip('Send message'));
      await tester.pumpAndSettle();
      expect(find.text('Custom trip help'), findsOneWidget);
      expect(find.text('Create support ticket'), findsOneWidget);
      await tester.tap(find.text('Create support ticket'));
      await tester.pumpAndSettle();
      expect(find.byType(CreateTicketScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('profile exposes editing, saved spots and ticket management', (
    tester,
  ) async {
    phone(tester, width: 320);
    final api = ApiClient(
      baseUrl: 'http://example.test',
      client: MockClient((req) async => accountRoutes(req) ?? response({})),
    );
    final controller = await signedIn(api);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(home: ProfileScreen(controller: controller)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Saved spots'), findsOneWidget);
    expect(find.text('Tickets & custom trip requests'), findsOneWidget);
    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();
    expect(find.byType(EditProfileScreen), findsOneWidget);
    expect(find.text('Traveler'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'booking management reviews server price before applying changes',
    (tester) async {
      phone(tester);
      var persons = 1;
      final date = dateOnly(DateTime.now().add(const Duration(days: 10)));
      final api = ApiClient(
        baseUrl: 'http://example.test',
        client: MockClient((req) async {
          final auth = accountRoutes(req);
          if (auth != null) return auth;
          if (req.url.path.endsWith('/ticket')) {
            return response({
              'ticket': {
                'id': 1,
                'spot_id': 7,
                'spot_name': 'Lalbagh Fort',
                'reference': 'FR-TEST',
                'traveler_name': 'Traveler',
                'booking_date': date,
                'persons': persons,
                'price': 800 * persons,
                'status': 'confirmed',
                'valid': true,
                'can_modify': true,
                'note': 'FarReach reservation receipt.',
              },
            });
          }
          if (req.url.path == '/api/bookings/quote') {
            return response({
              'quote': {'total': 1600},
            });
          }
          expect(req.method, 'PUT');
          expect(req.url.path, '/api/user/bookings/1');
          persons = jsonDecode(req.body)['persons'] as int;
          return response({
            'booking': {
              'id': 1,
              'booking_date': date,
              'persons': persons,
              'price': 1600,
              'status': 'confirmed',
            },
          });
        }),
      );
      final controller = await signedIn(api);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: BookingManagementScreen(
            controller: controller,
            booking: Booking(
              id: 1,
              spotName: 'Lalbagh Fort',
              price: 800,
              date: date,
              status: 'confirmed',
              persons: 1,
              canModify: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '2');
      await tester.ensureVisible(find.text('Review new price'));
      await tester.tap(find.text('Review new price'));
      await tester.pumpAndSettle();
      expect(persons, 1);
      expect(find.text('Updated server price: ৳1600 BDT'), findsOneWidget);
      await tester.tap(find.text('Confirm booking changes'));
      await tester.pumpAndSettle();
      expect(persons, 2);
      expect(find.textContaining('2 traveler(s)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
