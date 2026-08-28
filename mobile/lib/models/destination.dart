import 'dart:convert';

double? _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

int _asInt(Object? value, [int fallback = 0]) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String _asString(Object? value) => value?.toString().trim() ?? '';

class Destination {
  const Destination({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.history,
    required this.district,
    required this.division,
    required this.budget,
    required this.image,
    required this.assetPath,
    this.latitude,
    this.longitude,
  });

  final int id;
  final String name;
  final String category;
  final String description;
  final String history;
  final String district;
  final String division;
  final String budget;
  final String image;
  final String assetPath;
  final double? latitude;
  final double? longitude;

  String get location {
    final parts = [
      district,
      division,
    ].where((part) => part.isNotEmpty).toSet().toList();
    return parts.isEmpty ? 'Bangladesh' : parts.join(', ');
  }

  bool get hasCoordinates => latitude != null && longitude != null;

  String get cacheKey => id > 0 ? 'id:$id' : 'name:${name.toLowerCase()}';

  String? imageUrl(String baseUrl) {
    if (image.isEmpty) return null;
    final parsed = Uri.tryParse(image);
    if (parsed != null && parsed.hasScheme) return parsed.toString();
    final encoded = image.split('/').map(Uri.encodeComponent).join('/');
    return '$baseUrl/spot-pictures/$encoded';
  }

  factory Destination.fromJson(Map<String, dynamic> json) {
    final name = _asString(json['name']);
    return Destination(
      id: _asInt(json['id']),
      name: name.isEmpty ? 'Untitled destination' : name,
      category: _asString(json['category']).isEmpty
          ? 'Explore'
          : _asString(json['category']),
      description: _asString(json['description']),
      history: _asString(json['history']),
      district: _asString(json['district_name'] ?? json['district']),
      division: _asString(json['division_name'] ?? json['division']),
      budget: _asString(json['budget_category'] ?? json['budget']).isEmpty
          ? 'Mid'
          : _asString(json['budget_category'] ?? json['budget']),
      image: _asString(json['image']),
      assetPath: _asString(json['assetPath']).isNotEmpty
          ? _asString(json['assetPath'])
          : assetForDestination(name),
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'description': description,
    'history': history,
    'district_name': district,
    'division_name': division,
    'budget_category': budget,
    'image': image,
    'assetPath': assetPath,
    'latitude': latitude,
    'longitude': longitude,
  };

  static List<Destination> decodeList(String encoded) {
    final decoded = jsonDecode(encoded);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((item) => Destination.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static String encodeList(List<Destination> destinations) =>
      jsonEncode(destinations.map((item) => item.toJson()).toList());
}

String assetForDestination(String name) {
  final normalized = name.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
  if (normalized.contains('cox')) return 'assets/images/coxs_bazar.jpg';
  if (normalized.contains('sundar')) return 'assets/images/sundarbans.jpg';
  if (normalized.contains('saintmartin')) {
    return 'assets/images/saint_martin.jpg';
  }
  if (normalized.contains('bandarban') || normalized.contains('nilgiri')) {
    return 'assets/images/bandarban.jpg';
  }
  if (normalized.contains('srimangal') || normalized.contains('tea')) {
    return 'assets/images/srimangal.jpg';
  }
  if (normalized.contains('lalbagh')) return 'assets/images/lalbagh_fort.jpg';
  if (normalized.contains('ahsan')) return 'assets/images/ahsan_manzil.jpg';
  if (normalized.contains('jaf')) return 'assets/images/jaflong.jpg';
  if (normalized.contains('kuakata') || normalized.contains('kuyakata')) {
    return 'assets/images/kuakata.jpg';
  }
  if (normalized.contains('rangamati') || normalized.contains('kaptai')) {
    return 'assets/images/rangamati.jpg';
  }
  return 'assets/images/coxs_bazar.jpg';
}

class WeatherInfo {
  const WeatherInfo({
    required this.temperature,
    required this.description,
    required this.humidity,
    required this.windKmh,
  });

  final double temperature;
  final String description;
  final int humidity;
  final double windKmh;

  factory WeatherInfo.fromJson(Map<String, dynamic> json) {
    final weather = json['weather'];
    final firstWeather =
        weather is List && weather.isNotEmpty && weather.first is Map
        ? Map<String, dynamic>.from(weather.first as Map)
        : const <String, dynamic>{};
    final main = json['main'] is Map
        ? Map<String, dynamic>.from(json['main'] as Map)
        : const <String, dynamic>{};
    final wind = json['wind'] is Map
        ? Map<String, dynamic>.from(json['wind'] as Map)
        : const <String, dynamic>{};
    return WeatherInfo(
      temperature: _asDouble(main['temp']) ?? 0,
      description: _asString(firstWeather['description']).isEmpty
          ? 'Weather available'
          : _asString(firstWeather['description']),
      humidity: _asInt(main['humidity']),
      windKmh: (_asDouble(wind['speed']) ?? 0) * 3.6,
    );
  }
}

class HotelRecommendation {
  const HotelRecommendation({
    required this.name,
    required this.price,
    required this.rating,
    required this.availability,
    required this.note,
    required this.url,
  });

  final String name;
  final String price;
  final double rating;
  final String availability;
  final String note;
  final String url;

  factory HotelRecommendation.fromJson(Map<String, dynamic> json) =>
      HotelRecommendation(
        name: _asString(json['name']),
        price: _asString(json['price']),
        rating: _asDouble(json['rating']) ?? 0,
        availability: _asString(json['availability']),
        note: _asString(json['note']),
        url: _asString(json['url']),
      );
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone = '',
    this.address = '',
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final String phone;
  final String address;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: _asInt(json['id']),
    name: _asString(json['name']),
    email: _asString(json['email']),
    role: _asString(json['role']).isEmpty ? 'user' : _asString(json['role']),
    phone: _asString(json['phone']),
    address: _asString(json['address']),
  );
}

class Booking {
  const Booking({
    required this.id,
    required this.spotName,
    required this.price,
    required this.date,
    required this.status,
    required this.persons,
  });

  final int id;
  final String spotName;
  final int price;
  final String date;
  final String status;
  final int persons;

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
    id: _asInt(json['id']),
    spotName: _asString(json['spot_name'] ?? json['target_name']),
    price: _asInt(json['price']),
    date: _asString(json['booking_date']),
    status: _asString(json['status']),
    persons: _asInt(json['persons'], 1),
  );
}

const fallbackDestinations = <Destination>[
  Destination(
    id: 0,
    name: "Cox's Bazar",
    category: 'Beach',
    description: 'Long sandy shores, seafood, sunrise walks, and an easy base for exploring the southeast coast.',
    history: 'A landmark coastal destination shaped by fishing communities and maritime trade.',
    district: "Cox's Bazar",
    division: 'Chattogram',
    budget: 'Mid',
    image: '',
    assetPath: 'assets/images/coxs_bazar.jpg',
    latitude: 21.4272,
    longitude: 92.0058,
  ),
  Destination(
    id: 0,
    name: 'The Sundarbans',
    category: 'Nature',
    description: 'A vast mangrove landscape of tidal rivers, quiet creeks, wildlife, and community-led boat journeys.',
    history: 'The forest has protected the delta and supported river communities for generations.',
    district: 'Khulna',
    division: 'Khulna',
    budget: 'High',
    image: '',
    assetPath: 'assets/images/sundarbans.jpg',
    latitude: 21.9497,
    longitude: 89.1833,
  ),
  Destination(
    id: 0,
    name: "Saint Martin's Island",
    category: 'Island',
    description: 'Clear water, coral-stone beaches, simple island food, and slow evenings beside the Bay of Bengal.',
    history: 'Bangladesh’s only coral island is home to a close-knit fishing community.',
    district: "Cox's Bazar",
    division: 'Chattogram',
    budget: 'High',
    image: '',
    assetPath: 'assets/images/saint_martin.jpg',
    latitude: 20.6270,
    longitude: 92.3220,
  ),
  Destination(
    id: 0,
    name: 'Bandarban',
    category: 'Hills',
    description: 'Cloudy ridgelines, waterfalls, winding roads, and diverse hill communities in the Chattogram Hill Tracts.',
    history: 'The region is known for its Indigenous cultures, crafts, and long-established hill settlements.',
    district: 'Bandarban',
    division: 'Chattogram',
    budget: 'Mid',
    image: '',
    assetPath: 'assets/images/bandarban.jpg',
    latitude: 22.1953,
    longitude: 92.2184,
  ),
  Destination(
    id: 0,
    name: 'Srimangal Tea Country',
    category: 'Nature',
    description: 'Rolling tea estates, forest trails, cycling routes, and the gentle rhythm of northeastern Bangladesh.',
    history: 'Tea cultivation has shaped the area’s landscape and working communities for more than a century.',
    district: 'Moulvibazar',
    division: 'Sylhet',
    budget: 'Low',
    image: '',
    assetPath: 'assets/images/srimangal.jpg',
    latitude: 24.3065,
    longitude: 91.7296,
  ),
  Destination(
    id: 0,
    name: 'Lalbagh Fort',
    category: 'History',
    description: 'A calm Mughal-era complex with gardens, gateways, a mosque, and a museum in Old Dhaka.',
    history: 'Construction began in the seventeenth century and the unfinished fort remains one of Dhaka’s defining monuments.',
    district: 'Dhaka',
    division: 'Dhaka',
    budget: 'Low',
    image: '',
    assetPath: 'assets/images/lalbagh_fort.jpg',
    latitude: 23.7195,
    longitude: 90.3882,
  ),
  Destination(
    id: 0,
    name: 'Ahsan Manzil',
    category: 'History',
    description: 'The Pink Palace overlooks the Buriganga and offers an accessible introduction to Dhaka’s urban history.',
    history: 'The restored palace once served as the residence and seat of influence of Dhaka’s nawabs.',
    district: 'Dhaka',
    division: 'Dhaka',
    budget: 'Low',
    image: '',
    assetPath: 'assets/images/ahsan_manzil.jpg',
    latitude: 23.7086,
    longitude: 90.4060,
  ),
  Destination(
    id: 0,
    name: 'Jaflong',
    category: 'Nature',
    description: 'River stones, green hills, tea gardens, and borderland views make this a popular day trip from Sylhet.',
    history: 'River life and stone collection have long shaped livelihoods around the Piyain River.',
    district: 'Sylhet',
    division: 'Sylhet',
    budget: 'Low',
    image: '',
    assetPath: 'assets/images/jaflong.jpg',
    latitude: 25.1641,
    longitude: 92.0177,
  ),
  Destination(
    id: 0,
    name: 'Kuakata',
    category: 'Beach',
    description: 'A broad southern beach known for open horizons, fishing communities, and both sunrise and sunset views.',
    history: 'Kuakata’s name and cultural identity are closely linked with the area’s Rakhine community.',
    district: 'Patuakhali',
    division: 'Barishal',
    budget: 'Mid',
    image: '',
    assetPath: 'assets/images/kuakata.jpg',
    latitude: 21.8167,
    longitude: 90.1167,
  ),
  Destination(
    id: 0,
    name: 'Rangamati',
    category: 'Lake',
    description: 'Kaptai Lake, forested hills, boat routes, markets, and viewpoints create an easygoing lakeside escape.',
    history: 'The area carries the living traditions of several Indigenous communities of the hill tracts.',
    district: 'Rangamati',
    division: 'Chattogram',
    budget: 'Mid',
    image: '',
    assetPath: 'assets/images/rangamati.jpg',
    latitude: 22.7324,
    longitude: 92.2985,
  ),
];
