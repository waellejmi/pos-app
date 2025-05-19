class Setting {
  final int id;
  final String key;
  final String value;
  final DateTime createdAt;
  final DateTime updatedAt;

  Setting({
    required this.id,
    required this.key,
    required this.value,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Setting.fromJson(Map<String, dynamic> json) {
    return Setting(
      id: json['id'],
      key: json['key'],
      value: json['value'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
