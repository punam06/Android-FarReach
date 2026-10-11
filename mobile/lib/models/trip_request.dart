String tripLabel(String value) => value
    .split('_')
    .map((s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}')
    .join(' ');
String tripMoney(int paisa) => '৳${(paisa / 100).toStringAsFixed(2)}';
int? parseTripMoney(String value) {
  final text = value.trim();
  if (!RegExp(r'^\d{1,8}(\.\d{1,2})?$').hasMatch(text)) return null;
  final parts = text.split('.');
  final amount =
      int.parse(parts[0]) * 100 +
      (parts.length == 2 ? int.parse(parts[1].padRight(2, '0')) : 0);
  return amount > 0 && amount <= 1000000000 ? amount : null;
}

class TripRequest {
  TripRequest(this.data);
  final Map<String, dynamic> data;
  int get id => data['id'] as int;
  int get version => data['version'] as int;
  String get reference => data['reference'] as String;
  String get status => data['status'] as String;
  String get destination => data['destination'] as String;
  String get origin => data['origin'] as String;
  String get startDate => data['start_date'] as String;
  String get endDate => data['end_date'] as String;
  int? get quoteId => data['current_quote_id'] as int?;
  bool get canCancel => [
    'requested',
    'quoted',
    'awaiting_confirmation',
    'confirmed',
  ].contains(status);
}

class TripQuote {
  TripQuote(this.data);
  final Map<String, dynamic> data;
  int get id => data['id'] as int;
  int get total => data['total_paisa'] as int;
  DateTime get expiresAt => DateTime.parse(data['expires_at'] as String);
  bool get expired =>
      data['expired'] == true || !expiresAt.isAfter(DateTime.now());
  List<Map<String, dynamic>> get items => (data['line_items'] as List)
      .map((v) => Map<String, dynamic>.from(v as Map))
      .toList();
  String get itinerary => data['itinerary'] as String;
  String get cancellationPolicy => data['cancellation_policy'] as String;
}

class TripDetail {
  TripDetail(Map<String, dynamic> payload)
    : trip = TripRequest(Map<String, dynamic>.from(payload['trip'] as Map)),
      quotes = (payload['quotes'] as List)
          .map((v) => TripQuote(Map<String, dynamic>.from(v as Map)))
          .toList(),
      events = (payload['events'] as List)
          .map((v) => Map<String, dynamic>.from(v as Map))
          .toList();
  final TripRequest trip;
  final List<TripQuote> quotes;
  final List<Map<String, dynamic>> events;
  TripQuote? get currentQuote {
    for (final quote in quotes) {
      if (quote.id == trip.quoteId) return quote;
    }
    return null;
  }
}
