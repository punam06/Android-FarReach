import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../data/booking_repository_impl.dart';
import '../domain/booking.dart';

/// State for the bookings list screen.
class BookingsProvider extends ChangeNotifier {
  final BookingRepositoryImpl _repository;

  List<Booking> bookings = [];
  bool loading = false;
  String? error;

  BookingsProvider({BookingRepositoryImpl? repository})
      : _repository = repository ?? BookingRepositoryImpl();

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      bookings = await _repository.getUserBookings();
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Could not reach the server. Is it running?';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> cancel(Booking booking) async {
    try {
      await _repository.cancelBooking(booking.id);
      bookings.removeWhere((b) => b.id == booking.id);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    }
  }
}

