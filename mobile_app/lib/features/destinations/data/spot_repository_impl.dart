import '../../../core/network/api_client.dart';
import '../domain/spot.dart';
import '../domain/spot_repository.dart';

/// REST implementation of [SpotRepository].
class SpotRepositoryImpl implements SpotRepository {
  final ApiClient _client;

  SpotRepositoryImpl({ApiClient? client})
      : _client = client ?? ApiClient.instance;

  @override
  Future<List<Spot>> getSpots() async {
    final data = await _client.get('/api/spots', auth: false);
    final rows = data is Map && data['spots'] is List
        ? data['spots'] as List
        : <dynamic>[];
    return rows
        .whereType<Map<String, dynamic>>()
        .map((row) => Spot.fromJson(row))
        .toList();
  }
}

