/// Flight school entity
class FlightSchool {
  final String id;
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final DateTime createdAt;
  
  FlightSchool({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.email,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'phone': phone,
    'email': email,
    'createdAt': createdAt.toIso8601String(),
  };

  factory FlightSchool.fromJson(Map<String, dynamic> json) => FlightSchool(
    id: json['id'],
    name: json['name'],
    address: json['address'],
    phone: json['phone'],
    email: json['email'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}
