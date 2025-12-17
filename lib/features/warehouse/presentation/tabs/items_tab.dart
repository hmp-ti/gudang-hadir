import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/item.dart';
import '../item_detail_page.dart';
import '../item_form_page.dart';
import '../warehouse_controller.dart';

class ItemsTab extends ConsumerStatefulWidget {
  const ItemsTab({super.key});

  @override
  ConsumerState<ItemsTab> createState() => _ItemsTabState();
}

class _ItemsTabState extends ConsumerState<ItemsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(warehouseControllerProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ItemFormPage()));
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Cari nama atau kode barang...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: itemsAsync.when(
              data: (items) {
                final filtered = items.where((item) {
                  return item.name.toLowerCase().contains(_searchQuery) ||
                      item.code.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('Tidak ada barang ditemukan'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _buildItemCard(context, item);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, Item item) {
    final isLowStock = item.stock <= item.minStock;
    return Card(
      child: ListTile(
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${item.code} | Rak: ${item.rackLocation}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${item.stock} ${item.unit}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isLowStock ? Colors.red : Colors.black,
              ),
            ),
            if (isLowStock) const Text('Low Stock', style: TextStyle(color: Colors.red, fontSize: 10)),
          ],
        ),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ItemDetailPage(item: item)));
        },
      ),
    );
  }
}
