class WarehouseTransaction {
  final String id;
  final String itemId;
  final String type; // 'IN' or 'OUT'
  final int qty;
  final String note;
  final DateTime createdAt;
  final String createdBy; // userId

  // Optional: Join fields for display
  final String? itemName;
  final String? userName;

  WarehouseTransaction({
    required this.id,
    required this.itemId,
    required this.type,
    required this.qty,
    required this.note,
    required this.createdAt,
    required this.createdBy,
    this.itemName,
    this.userName,
  });

  factory WarehouseTransaction.fromJson(Map<String, dynamic> json) {
    return WarehouseTransaction(
      id: json['id'],
      itemId: json['item_id'],
      type: json['type'],
      qty: json['qty'],
      note: json['note'],
      createdAt: DateTime.parse(json['created_at']),
      createdBy: json['created_by'],
      itemName: json['item_name'], // from join
      userName: json['user_name'], // from join
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_id': itemId,
      'type': type,
      'qty': qty,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
    };
  }
}
