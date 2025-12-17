import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:gudang_hadir/features/warehouse/data/transaction_dao.dart';
import 'package:gudang_hadir/features/warehouse/domain/item.dart';
import 'package:gudang_hadir/features/warehouse/domain/transaction.dart';

class ItemHistoryPage extends ConsumerStatefulWidget {
  final Item item;
  const ItemHistoryPage({super.key, required this.item});

  @override
  ConsumerState<ItemHistoryPage> createState() => _ItemHistoryPageState();
}

class _ItemHistoryPageState extends ConsumerState<ItemHistoryPage> {
  bool _isLoading = false;
  List<WarehouseTransaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      // Fetch all transactions, then filter by item ID?
      // Or TransactionDao needs getTransactionsByItemId?
      // TransactionDao currently has getAllTransactions({type, start, end}).
      // It sorts by createdAt desc.
      // We can filter in memory for now, or add a query.
      // Ideally update TransactionDao to query by itemId. But for now filter memory.
      // Wait, if database grows, memory filter is bad.
      // But implementation plan said "Add deleteTransaction to DAO".
      // I should probably add query support for itemId in getAllTransactions or a new method.
      // Let's assume getAllTransactions returns list and we filter.
      // Actually TransactionDao.getAllTransactions doesn't support itemId filtering yet.

      final all = await ref.read(transactionDaoProvider).getAllTransactions();
      _transactions = all.where((t) => t.itemId == widget.item.id).toList();
      setState(() {});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTransaction(WarehouseTransaction transaction) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: Text(
          'Transaksi ${transaction.type} qty ${transaction.qty} pada ${DateFormat('d MMM HH:mm').format(transaction.createdAt)} akan dihapus.\n\nStok barang TIDAK akan otomatis dikembalikan (Anda harus update stok manual jika perlu).',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(transactionDaoProvider).deleteTransaction(transaction.id);

      // Optionally adjust stock?
      // User request "hapus history barang masuk keluar".
      // Usually if I delete "IN", stock should decrease? Or just delete history record?
      // For safety, let's just delete the record. User can adjust stock via Edit Item.
      // Warning text explains this.

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaksi dihapus')));
        _fetchData();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Riwayat Barang', style: TextStyle(fontSize: 16)),
            Text(widget.item.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
          ? const Center(child: Text('Belum ada riwayat transaksi.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _transactions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final t = _transactions[index];
                final isMasuk = t.type.toLowerCase() == 'masuk';
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isMasuk ? Colors.green.shade100 : Colors.red.shade100,
                      child: Icon(
                        isMasuk ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isMasuk ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text(
                      '${t.type} : ${t.qty} ${widget.item.unit}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(DateFormat('d MMM yyyy HH:mm').format(t.createdAt)),
                        if (t.note.isNotEmpty)
                          Text('Note: ${t.note}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                        Text(
                          'Oleh: ${t.userName ?? "Unknown"}',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.grey, size: 20),
                      onPressed: () => _deleteTransaction(t),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
