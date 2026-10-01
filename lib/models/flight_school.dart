/// Flight school entity. Mirrors the `flight_schools` table in Supabase.
class FlightSchool {
  final String id;
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final String? inviteCode;
  final String planType; // 'standard' | 'comped'
  final DateTime createdAt;

  bool get isComped => planType == 'comped';

  FlightSchool({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.email,
    this.inviteCode,
    this.planType = 'standard',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'phone': phone,
        'email': email,
        'invite_code': inviteCode,
        'plan_type': planType,
        'createdAt': createdAt.toIso8601String(),
      };

  factory FlightSchool.fromJson(Map<String, dynamic> json) => FlightSchool(
        id: json['id'] as String,
        name: json['name'] as String,
        address: json['address'] as String?,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        inviteCode: (json['invite_code'] ?? json['inviteCode']) as String?,
        planType:
            (json['plan_type'] ?? json['planType']) as String? ?? 'standard',
        createdAt: DateTime.parse(
          (json['created_at'] ?? json['createdAt']).toString(),
        ),
      );
}
