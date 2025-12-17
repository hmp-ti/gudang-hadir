class Item {
  final String id;
  final String code;
  final String name;
  final String category;
  final String unit;
  final int stock;
  final int minStock;
  final String rackLocation;
  final String description;
  final double price;
  final bool discontinued;
  final String manufacturer;
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
    this.price = 0.0,
    this.discontinued = false,
    this.manufacturer = '',
    required this.updatedAt,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    // Helper to safely get value checking both camelCase and snake_case
    T? getVal<T>(String camel, String snake) {
      if (json.containsKey(camel) && json[camel] != null) return json[camel] as T?;
      if (json.containsKey(snake) && json[snake] != null) return json[snake] as T?;
      return null;
    }

    return Item(
      id: json['id'] ?? json['\$id'] ?? '', // Support Appwrite $id
      code: getVal<String>('code', 'code') ?? '',
      name: getVal<String>('name', 'name') ?? '',
      category: getVal<String>('category', 'category') ?? '',
      unit: getVal<String>('unit', 'unit') ?? '',
      stock: getVal<int>('stock', 'stock') ?? 0,
      minStock: getVal<int>('minStock', 'min_stock') ?? 0,
      rackLocation: getVal<String>('rackLocation', 'rack_location') ?? '',
      description: getVal<String>('description', 'description') ?? '',
      price: (getVal<num>('price', 'price') ?? 0).toDouble(),
      discontinued: getVal<bool>('discontinued', 'discontinued') ?? false,
      manufacturer: getVal<String>('manufacturer', 'manufacturer') ?? '',
      updatedAt: DateTime.tryParse(getVal<String>('updatedAt', 'updated_at') ?? '') ?? DateTime.now(),
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
      'price': price,
      'discontinued': discontinued,
      'manufacturer': manufacturer,
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
