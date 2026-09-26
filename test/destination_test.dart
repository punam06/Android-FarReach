import 'package:farreach/models/destination.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Destination', () {
    test('parses MySQL decimal coordinates returned as strings', () {
      final destination = Destination.fromJson({
        'id': 42,
        'name': 'Jaflong',
        'category': 'Nature',
        'district_name': 'Sylhet',
        'division_name': 'Sylhet',
        'budget_category': 'Low',
        'latitude': '25.1641',
        'longitude': '92.0177',
      });

      expect(destination.latitude, 25.1641);
      expect(destination.longitude, 92.0177);
      expect(destination.location, 'Sylhet');
      expect(destination.assetPath, 'assets/images/jaflong.jpg');
    });

    test('cached destination list round-trips safely', () {
      final encoded = Destination.encodeList(
        fallbackDestinations.take(2).toList(),
      );
      final decoded = Destination.decodeList(encoded);

      expect(decoded, hasLength(2));
      expect(decoded.first.name, "Cox's Bazar");
      expect(decoded.last.name, 'The Sundarbans');
    });
  });
}
