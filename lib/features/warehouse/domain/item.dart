class Item {
  final String id;
  final String code;
  final String name;
  final String category;
  final String unit;
  final int stock;
  final int minStock;
  final String rackLocation; // 'rack_location' in DB
  final String description;
  final DateTime updatedAt;

  Item({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.unit,
    required this.stock,
    required this.minStock,
    required this.rackLocation,
    required this.description,
    required this.updatedAt,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      code: json['code'],
      name: json['name'],
      category: json['category'],
      unit: json['unit'],
      stock: json['stock'],
      minStock: json['min_stock'],
      rackLocation: json['rack_location'],
      description: json['description'],
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'category': category,
      'unit': unit,
      'stock': stock,
      'min_stock': minStock,
      'rack_location': rackLocation,
      'description': description,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Item copyWith({
    String? id,
    String? code,
    String? name,
    String? category,
    String? unit,
    int? stock,
    int? minStock,
    String? rackLocation,
    String? description,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      rackLocation: rackLocation ?? this.rackLocation,
      description: description ?? this.description,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
