import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/validators.dart';
import '../domain/item.dart';
import 'warehouse_controller.dart';

class ItemFormPage extends ConsumerStatefulWidget {
  final Item? item; // If null, it's Add mode
  const ItemFormPage({super.key, this.item});

  @override
  ConsumerState<ItemFormPage> createState() => _ItemFormPageState();
}

class _ItemFormPageState extends ConsumerState<ItemFormPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _unitController;
  late TextEditingController _minStockController;
  late TextEditingController _rackController;
  late TextEditingController _descController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _codeController = TextEditingController(text: item?.code ?? '');
    _nameController = TextEditingController(text: item?.name ?? '');
    _categoryController = TextEditingController(text: item?.category ?? '');
    _unitController = TextEditingController(text: item?.unit ?? 'Pcs');
    _minStockController = TextEditingController(text: item?.minStock.toString() ?? '5');
    _rackController = TextEditingController(text: item?.rackLocation ?? '');
    _descController = TextEditingController(text: item?.description ?? '');
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _categoryController.dispose();
    _unitController.dispose();
    _minStockController.dispose();
    _rackController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        if (widget.item == null) {
          // Add
          await ref
              .read(warehouseControllerProvider.notifier)
              .addItem(
                _codeController.text,
                _nameController.text,
                _categoryController.text,
                _unitController.text,
                int.parse(_minStockController.text),
                _rackController.text,
                _descController.text,
              );
        } else {
          // Edit
          final updatedItem = widget.item!.copyWith(
            code: _codeController.text,
            name: _nameController.text,
            category: _categoryController.text,
            unit: _unitController.text,
            minStock: int.parse(_minStockController.text),
            rackLocation: _rackController.text,
            description: _descController.text,
          );
          await ref.read(warehouseControllerProvider.notifier).updateItem(updatedItem);
        }
        if (mounted) Navigator.pop(context);
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
    final isEditing = widget.item != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Barang' : 'Tambah Barang')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'Kode Barang (Unik)'),
                validator: AppValidators.required,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Barang'),
                validator: AppValidators.required,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(labelText: 'Kategori'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _unitController,
                      decoration: const InputDecoration(labelText: 'Satuan (Pcs, Box)'),
                      validator: AppValidators.required,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minStockController,
                      decoration: const InputDecoration(labelText: 'Min Stock'),
                      keyboardType: TextInputType.number,
                      validator: AppValidators.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _rackController,
                      decoration: const InputDecoration(labelText: 'Lokasi Rak'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: Text(isEditing ? 'SIMPAN PERUBAHAN' : 'TAMBAH BARANG'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
