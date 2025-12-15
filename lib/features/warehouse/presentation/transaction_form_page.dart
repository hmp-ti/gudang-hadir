import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/validators.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/item.dart';
import 'warehouse_controller.dart';

class TransactionFormPage extends ConsumerStatefulWidget {
  final Item item;
  final String type; // 'IN' or 'OUT'

  const TransactionFormPage({super.key, required this.item, required this.type});

  @override
  ConsumerState<TransactionFormPage> createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends ConsumerState<TransactionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _qtyController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final currentUser = await ref.read(authRepositoryProvider).getCurrentUser();
        if (currentUser == null) throw Exception('Session expired');

        await ref
            .read(warehouseControllerProvider.notifier)
            .addTransaction(
              itemId: widget.item.id,
              type: widget.type,
              qty: int.parse(_qtyController.text),
              note: _noteController.text,
              userId: currentUser.id,
            );

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Transaksi Berhasil'), backgroundColor: Colors.green));
          Navigator.pop(context); // Close Form
          Navigator.pop(context); // Close Detail ? Or just keep detail updated?
          // If we pop detail, we need to refresh list. WarehouseController auto refreshes list.
          // But DetailPage usually fetches ID.
          // Let's just pop the form for now.
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTypeIn = widget.type == 'IN';
    return Scaffold(
      appBar: AppBar(
        title: Text(isTypeIn ? 'Barang Masuk (IN)' : 'Barang Keluar (OUT)'),
        backgroundColor: isTypeIn ? Colors.green : Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Barang: ${widget.item.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Stok Saat Ini: ${widget.item.stock} ${widget.item.unit}'),
              const Divider(height: 32),
              TextFormField(
                controller: _qtyController,
                decoration: const InputDecoration(labelText: 'Jumlah (Qty)'),
                keyboardType: TextInputType.number,
                validator: (val) {
                  final msg = AppValidators.number(val);
                  if (msg != null) return msg;
                  if (val == null || val.isEmpty) return 'Wajib diisi';
                  final q = int.parse(val);
                  if (q <= 0) return 'Harus > 0';
                  if (!isTypeIn && q > widget.item.stock) {
                    return 'Stok tidak cukup (Sisa: ${widget.item.stock})';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Catatan / Keterangan'),
                maxLines: 2,
                validator: AppValidators.required,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isTypeIn ? Colors.green : Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isLoading ? null : _submit,
                  child: Text(isTypeIn ? 'SIMPAN MASUK' : 'SIMPAN KELUAR'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
