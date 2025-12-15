import 'package:flutter/material.dart';
import '../domain/item.dart';
import 'item_form_page.dart';
import 'transaction_form_page.dart';

class ItemDetailPage extends StatelessWidget {
  final Item item;
  const ItemDetailPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ItemFormPage(item: item)));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Kode', item.code),
            _buildDetailRow('Kategori', item.category),
            _buildDetailRow('Rak', item.rackLocation),
            const Divider(),
            _buildDetailRow(
              'Stok Saat Ini',
              '${item.stock} ${item.unit}',
              isValueBold: true,
              valueColor: item.stock <= item.minStock ? Colors.red : Colors.green,
            ),
            _buildDetailRow('Min Stock', '${item.minStock} ${item.unit}'),
            const Divider(),
            const Text('Deskripsi:', style: TextStyle(color: Colors.grey)),
            Text(item.description, style: const TextStyle(fontSize: 16)),

            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    icon: const Icon(Icons.arrow_downward),
                    label: const Text('Barang Masuk'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TransactionFormPage(item: item, type: 'IN'),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                    icon: const Icon(Icons.arrow_upward),
                    label: const Text('Barang Keluar'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TransactionFormPage(item: item, type: 'OUT'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isValueBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isValueBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
