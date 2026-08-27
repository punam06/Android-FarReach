import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../data/spot_repository_impl.dart';
import '../domain/spot.dart';

/// State for the destinations list with search + category filtering.
class SpotsProvider extends ChangeNotifier {
  final SpotRepositoryImpl _repository;

  List<Spot> _spots = [];
  bool loading = false;
  String? error;
  String query = '';
  String category = 'All';

  SpotsProvider({SpotRepositoryImpl? repository})
      : _repository = repository ?? SpotRepositoryImpl();

  List<Spot> get spots {
    final q = query.toLowerCase().trim();
    return _spots.where((s) {
      final matchesCategory =
          category == 'All' || s.category.toLowerCase() == category.toLowerCase();
      final matchesQuery = q.isEmpty ||
          s.name.toLowerCase().contains(q) ||
          s.districtName.toLowerCase().contains(q) ||
          s.divisionName.toLowerCase().contains(q);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  List<String> get categories {
    final set = _spots.map((s) => s.category).where((c) => c.isNotEmpty).toSet();
    return ['All', ...set];
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      _spots = await _repository.getSpots();
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Could not reach the server. Is it running?';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void setQuery(String value) {
    query = value;
    notifyListeners();
  }

  void setCategory(String value) {
    category = value;
    notifyListeners();
  }
}

