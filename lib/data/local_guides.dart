import '../models/destination.dart';

/// A recommended local guide shown in the destination details and the
/// booking management screens.
class LocalGuide {
  const LocalGuide({
    required this.name,
    required this.initials,
    required this.role,
    required this.email,
    required this.phone,
    required this.base,
  });

  final String name;
  final String initials;
  final String role;
  final String email;
  final String phone;
  final String base;

  Uri get profileUri => Uri.parse(
    'https://www.google.com/search?q=${Uri.encodeComponent('$name tour guide $base')}',
  );
}

int _seedFor(Destination destination) {
  var hash = 0;
  for (final code in destination.name.runes) {
    hash = (hash * 31 + code) & 0x7fffffff;
  }
  return hash ^ (destination.id > 0 ? destination.id : 7);
}

int _next(int seed, int min, int max) {
  final value = (seed * 2654435761) & 0x7fffffff;
  return min + (value % (max - min + 1));
}

List<LocalGuide> localGuidesFor(Destination destination) {
  const firstNames = [
    'Arif',
    'Nusrat',
    'Rafiq',
    'Maya',
    'Tasnim',
    'Sujon',
    'Jahan',
    'Rumana',
    'Faruk',
    'Lima',
  ];
  const roles = [
    'Local Guide',
    'Beach Guide',
    'Nature Guide',
    'Cultural Guide',
    'History Guide',
    'Hills Guide',
  ];
  const domains = [
    'example.com',
    'travelsbd.com',
    'guidehub.com',
    'tourmail.com',
  ];
  const bases = [
    "Cox's Bazar",
    'Dhaka',
    'Sylhet',
    'Bandarban',
    'Rangamati',
    'Khulna',
  ];

  var seed = _seedFor(destination);
  final count = 2 + (_next(seed, 0, 1));
  final list = <LocalGuide>[];
  for (var i = 0; i < count; i++) {
    seed++;
    final fn = firstNames[_next(seed, 0, firstNames.length - 1)];
    final ln = firstNames[_next(seed + 3, 0, firstNames.length - 1)];
    final base = destinationsWithBases.contains(destination.district)
        ? destination.district
        : bases[_next(seed + 5, 0, bases.length - 1)];
    final role = roles[_next(seed + 7, 0, roles.length - 1)];
    final domain = domains[_next(seed + 9, 0, domains.length - 1)];
    final phone = '+88 ${_next(seed + 11, 10000000, 99999999)}';
    list.add(
      LocalGuide(
        name: '$fn $ln',
        initials: '${fn[0]}${ln[0]}',
        role: role,
        email: '${fn.toLowerCase()}.${ln.toLowerCase()}@$domain',
        phone: phone,
        base: base,
      ),
    );
  }
  return list;
}

const destinationsWithBases = [
  "Cox's Bazar",
  'Sylhet',
  'Bandarban',
  'Rangamati',
  'Khulna',
  'Moulvibazar',
  'Patuakhali',
  'Chittagong',
  'Dhaka',
];
