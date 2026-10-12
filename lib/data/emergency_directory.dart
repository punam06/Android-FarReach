import '../models/destination.dart';

/// A single emergency or safety contact for a place.
class EmergencyContact {
  const EmergencyContact(
    this.label,
    this.number, {
    this.description,
    this.icon = EmergencyIcon.phone,
  });

  final String label;
  final String number;
  final String? description;
  final EmergencyIcon icon;
}

enum EmergencyIcon { phone, police, ambulance, fire, women, info, tourist }

/// A place-wise safety action that opens an external map search rather than
/// relying on hardcoded local phone numbers.
class SafetyAction {
  const SafetyAction(this.label, this.query, {required this.icon});

  final String label;
  final String query;
  final EmergencyIcon icon;
}

/// Static, offline emergency information shown per destination. National
/// hotlines are Bangladesh-wide official numbers; place-wise help is routed
/// through map searches centred on the destination so no data is fabricated.
class EmergencyDirectory {
  const EmergencyDirectory._();

  static const nationalHotlines = <EmergencyContact>[
    EmergencyContact(
      'National emergency',
      '999',
      description: 'Police, fire and ambulance in one call',
      icon: EmergencyIcon.police,
    ),
    EmergencyContact(
      'Ambulance & health',
      '16263',
      description: 'Government health service hotline',
      icon: EmergencyIcon.ambulance,
    ),
    EmergencyContact(
      'Fire service',
      '16163',
      description: 'Fire and rescue control room',
      icon: EmergencyIcon.fire,
    ),
    EmergencyContact(
      'Women & children',
      '109',
      description: 'Support helpline',
      icon: EmergencyIcon.women,
    ),
    EmergencyContact(
      'National info service',
      '333',
      description: 'Government information and complaints',
      icon: EmergencyIcon.info,
    ),
  ];

  /// Division-specific notes surfaced above the national hotlines.
  static const divisionNotes = <String, String>{
    'Dhaka':
        'Dhaka Metropolitan Police operates a 24/7 control room. Major hospitals are concentrated around Dhanmondi, Mohakhali and Shahbagh.',
    'Chattogram':
        'Chattogram Medical College Hospital is the main referral hospital; the district police control room coordinates coastal rescues.',
    'Cox\'s Bazar':
        'Sea Beach tourist police posts run along the beach. Follow red-flag warnings and avoid swimming after dark.',
    'Khulna':
        'The Sundarbans is patrolled by the forest department; never enter without a registered guide and permit.',
    'Rajshahi':
        'The Rajshahi range police covers the northern heritage belt; river ghats can be slippery during the monsoon.',
    'Sylhet':
        'Sylhet range police cover the tea and haor belt; hill roads are accident-prone in heavy rain.',
    'Barishal':
        'Launch and ferry terminals are busy; keep valuables secure and note the nearest river police post.',
    'Rangpur':
        'Rangpur range police serve the north-west; carry warm clothing for winter travel.',
    'Mymensingh':
        'Mymensingh range police cover the Brahmaputra belt; check river currents before boat trips.',
  };

  static String? noteFor(Destination destination) {
    final key = destination.division.trim();
    if (key.isEmpty) return null;
    final direct = divisionNotes[key];
    if (direct != null) return direct;
    for (final entry in divisionNotes.entries) {
      if (entry.key.toLowerCase() == key.toLowerCase()) return entry.value;
    }
    return null;
  }

  /// Place-wise lookups around the destination, resolved through Google Maps.
  static List<SafetyAction> actionsFor(Destination destination) {
    final place = destination.name.trim().isEmpty
        ? destination.location
        : destination.name;
    return [
      SafetyAction(
        'Nearest hospital',
        'hospital near $place',
        icon: EmergencyIcon.ambulance,
      ),
      SafetyAction(
        'Nearest police station',
        'police station near $place',
        icon: EmergencyIcon.police,
      ),
      SafetyAction(
        'Tourist police post',
        'tourist police near $place',
        icon: EmergencyIcon.tourist,
      ),
      SafetyAction(
        'Nearest pharmacy',
        'pharmacy near $place',
        icon: EmergencyIcon.info,
      ),
      SafetyAction(
        'Fire station',
        'fire station near $place',
        icon: EmergencyIcon.fire,
      ),
    ];
  }

  static List<String> tipsFor(Destination destination) {
    final category = destination.category.toLowerCase();
    final tips = <String>[];
    if (category.contains('beach') || category.contains('island')) {
      tips.add(
        'Swim only where locals or lifeguards advise, and watch for rip currents.',
      );
    }
    if (category.contains('hill') ||
        category.contains('mountain') ||
        category.contains('waterfall')) {
      tips.add(
        'Trails turn slippery after rain; hire a registered guide and start early.',
      );
    }
    if (category.contains('forest') ||
        category.contains('mangrove') ||
        category.contains('wildlife') ||
        category.contains('wild')) {
      tips.add(
        'Keep a safe distance from wildlife and follow forest department rules.',
      );
    }
    if (category.contains('heritage') ||
        category.contains('historical') ||
        category.contains('fort') ||
        category.contains('palace') ||
        category.contains('museum')) {
      tips.add(
        'Many heritage sites close by late afternoon; carry water and sun protection.',
      );
    }
    if (category.contains('tea') || category.contains('lake')) {
      tips.add(
        'Keep to marked paths around plantations and lakes, and avoid isolated areas after dusk.',
      );
    }
    tips.add('Save the number 999 on your phone before you travel.');
    tips.add('Share your itinerary with someone you trust and keep it offline.');
    return tips;
  }
}
