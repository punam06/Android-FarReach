/// Domain entity for a user booking (matches GET /api/user/bookings).
class Booking {
  final int id;
  final int spotId;
  final String spotName;
  final String type;
  final String status;
  final double amount;
  final String createdAt;

  const Booking({
    required this.id,
    required this.spotId,
    required this.spotName,
    required this.type,
    required this.status,
    required this.amount,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
        spotId: json['spot_id'] is int
            ? json['spot_id']
            : int.tryParse('${json['spot_id']}') ?? 0,
        spotName: (json['spot_name'] ?? json['name'] ?? '').toString(),
        type: (json['type'] ?? 'package').toString(),
        status: (json['status'] ?? 'pending').toString(),
        amount: json['amount'] == null ? 0 : (json['amount'] as num).toDouble(),
        createdAt: (json['created_at'] ?? '').toString(),
      );
}

