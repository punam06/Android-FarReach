import '../../../core/network/api_client.dart';
import '../domain/booking.dart';

/// REST data source for the current user's bookings.
class BookingRepositoryImpl {
  final ApiClient _client;

  BookingRepositoryImpl({ApiClient? client})
      : _client = client ?? ApiClient.instance;

  Future<List<Booking>> getUserBookings() async {
    final data = await _client.get('/api/user/bookings');
    final rows = data is Map && data['bookings'] is List
        ? data['bookings'] as List
        : data is List
            ? data
            : <dynamic>[];
    return rows
        .whereType<Map<String, dynamic>>()
        .map((row) => Booking.fromJson(row))
        .toList();
  }

  Future<void> cancelBooking(int bookingId) async {
    await _client.delete('/api/user/bookings/$bookingId');
  }
}

