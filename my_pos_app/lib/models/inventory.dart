

class Inventory {
  final int id;
  final String name;
  final String location;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Inventory({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Inventory.fromJson(Map<String, dynamic> json) {
    return Inventory(
      id: json['id'],
      name: json['name'],
      location: json['location'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
