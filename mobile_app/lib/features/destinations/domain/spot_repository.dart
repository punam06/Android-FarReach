import 'spot.dart';

/// Abstract contract for destination data.
abstract class SpotRepository {
  Future<List<Spot>> getSpots();
}

