import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/payroll_config.dart';
import '../domain/payroll_service.dart';

class PayrollSettingsPage extends ConsumerStatefulWidget {
  final String userId;
  final String userName;

  const PayrollSettingsPage({super.key, required this.userId, required this.userName});

  @override
  ConsumerState<PayrollSettingsPage> createState() => _PayrollSettingsPageState();
}

class _PayrollSettingsPageState extends ConsumerState<PayrollSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _baseSalaryCtrl;
  late TextEditingController _transportCtrl;
  late TextEditingController _mealCtrl;
  late TextEditingController _overtimeCtrl;
  late TextEditingController _lateCtrl;
  late TextEditingController _absentCtrl;
  late TextEditingController _shiftStartCtrl;
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _baseSalaryCtrl = TextEditingController();
    _transportCtrl = TextEditingController();
    _mealCtrl = TextEditingController();
    _overtimeCtrl = TextEditingController();
    _lateCtrl = TextEditingController();
    _absentCtrl = TextEditingController();
    _shiftStartCtrl = TextEditingController();
    _loadData();
  }

  Future<void> _loadData() async {
    final repo = ref.read(payrollRepositoryProvider);
    final config = await repo.getPayrollConfig(widget.userId);
    
    setState(() {
      _baseSalaryCtrl.text = config.baseSalary.toStringAsFixed(0);
      _transportCtrl.text = config.transportAllowance.toStringAsFixed(0);
      _mealCtrl.text = config.mealAllowance.toStringAsFixed(0);
      _overtimeCtrl.text = config.overtimeRate.toStringAsFixed(0);
      _lateCtrl.text = config.latePenalty.toStringAsFixed(0);
      _absentCtrl.text = config.absentPenalty.toStringAsFixed(0);
      _shiftStartCtrl.text = config.shiftStartTime;
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final config = PayrollConfig(
        userId: widget.userId,
        baseSalary: double.tryParse(_baseSalaryCtrl.text) ?? 0,
        transportAllowance: double.tryParse(_transportCtrl.text) ?? 0,
        mealAllowance: double.tryParse(_mealCtrl.text) ?? 0,
        overtimeRate: double.tryParse(_overtimeCtrl.text) ?? 0,
        latePenalty: double.tryParse(_lateCtrl.text) ?? 0,
        absentPenalty: double.tryParse(_absentCtrl.text) ?? 0,
        shiftStartTime: _shiftStartCtrl.text,
      );
      
      await ref.read(payrollRepositoryProvider).savePayrollConfig(config);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengaturan Gaji Disimpan!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gaji: ${widget.userName}')),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                   _buildCurrencyField(_baseSalaryCtrl, 'Gaji Pokok'),
                   const SizedBox(height: 16),
                   const Text('Tunjangan Harian (dikalikan kehadiran)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                   _buildCurrencyField(_transportCtrl, 'Transport'),
                   _buildCurrencyField(_mealCtrl, 'Uang Makan'),
                   const SizedBox(height: 16),
                   const Text('Lembur & Denda', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                   _buildCurrencyField(_overtimeCtrl, 'Upah Lembur (Per Jam)'),
                   _buildCurrencyField(_lateCtrl, 'Denda Terlambat (Per Menit)'),
                   _buildCurrencyField(_absentCtrl, 'Denda Tidak Masuk (Per Hari)'),
                   const SizedBox(height: 16),
                   TextFormField(
                     controller: _shiftStartCtrl,
                     decoration: const InputDecoration(labelText: 'Jam Masuk (Format HH:MM)', hintText: '08:00'),
                     validator: (v) => v!.contains(':') ? null : 'Format salah',
                   ),
                   const SizedBox(height: 32),
                   ElevatedButton(
                     onPressed: _save,
                     style: ElevatedButton.styleFrom(
                       padding: const EdgeInsets.symmetric(vertical: 16),
                       backgroundColor: Colors.blue,
                       foregroundColor: Colors.white,
                     ),
                     child: const Text('Simpan Pengaturan'),
                   ),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrencyField(TextEditingController ctrl, String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          prefixText: 'Rp ',
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
