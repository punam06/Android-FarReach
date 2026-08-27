/// Domain entity for a tourist spot / destination (matches GET /api/spots).
class Spot {
  final int id;
  final String name;
  final String category;
  final String description;
  final String history;
  final String image;
  final String budgetCategory;
  final double? latitude;
  final double? longitude;
  final String districtName;
  final String divisionName;

  const Spot({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.history,
    required this.image,
    required this.budgetCategory,
    this.latitude,
    this.longitude,
    required this.districtName,
    required this.divisionName,
  });

  factory Spot.fromJson(Map<String, dynamic> json) => Spot(
        id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
        name: (json['name'] ?? '').toString(),
        category: (json['category'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        history: (json['history'] ?? '').toString(),
        image: (json['image'] ?? '').toString(),
        budgetCategory: (json['budget_category'] ?? '').toString(),
        latitude:
            json['latitude'] == null ? null : (json['latitude'] as num).toDouble(),
        longitude: json['longitude'] == null
            ? null
            : (json['longitude'] as num).toDouble(),
        districtName: (json['district_name'] ?? '').toString(),
        divisionName: (json['division_name'] ?? '').toString(),
      );
}

