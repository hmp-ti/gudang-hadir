import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/user_dao.dart';
import '../../auth/domain/user.dart';
import '../domain/payroll.dart';
import '../domain/payroll_service.dart';
import 'payroll_detail_page.dart';
import 'payroll_settings_page.dart';

class PayrollGenerationPage extends ConsumerStatefulWidget {
  const PayrollGenerationPage({super.key});

  @override
  ConsumerState<PayrollGenerationPage> createState() => _PayrollGenerationPageState();
}

class _PayrollGenerationPageState extends ConsumerState<PayrollGenerationPage> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  List<User> _users = [];
  bool _isLoadingUsers = true;

  // Cache previews
  final Map<String, Payroll> _previews = {};
  final Map<String, bool> _loadingPreviews = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final dao = ref.read(userDaoProvider);
    _users = await dao.getAllUsers(); // Assuming get all users
    setState(() => _isLoadingUsers = false);
  }

  Future<void> _generatePreview(User user) async {
    setState(() => _loadingPreviews[user.id] = true);
    try {
      final service = ref.read(payrollServiceProvider);
      final payroll = await service.generatePayrollPreview(userId: user.id, month: _selectedMonth, year: _selectedYear);
      setState(() => _previews[user.id] = payroll);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error ${user.name}: $e')));
    } finally {
      setState(() => _loadingPreviews[user.id] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hitung Gaji')),
      body: Column(
        children: [
          _buildFilter(),
          Expanded(
            child: _isLoadingUsers
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (ctx, i) {
                      final user = _users[i];
                      final preview = _previews[user.id];
                      final isLoading = _loadingPreviews[user.id] ?? false;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: preview == null
                              ? const Text('Belum dihitung')
                              : Text('Gaji Bersih: Rp ${preview.netSalary.toStringAsFixed(0)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isLoading)
                                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                              IconButton(
                                icon: const Icon(Icons.settings),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PayrollSettingsPage(userId: user.id, userName: user.name),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.calculate),
                                color: Colors.blue,
                                onPressed: () => _generatePreview(user),
                              ),
                              if (preview != null)
                                IconButton(
                                  icon: const Icon(Icons.arrow_forward),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            PayrollDetailPage(payroll: preview, userName: user.name, isPreview: true),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          DropdownButton<int>(
            value: _selectedMonth,
            items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text('Bulan ${i + 1}'))),
            onChanged: (v) => setState(() {
              _selectedMonth = v!;
              _previews.clear();
            }),
          ),
          const SizedBox(width: 16),
          DropdownButton<int>(
            value: _selectedYear,
            items: [2024, 2025, 2026].map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
            onChanged: (v) => setState(() {
              _selectedYear = v!;
              _previews.clear();
            }),
          ),
        ],
      ),
    );
  }
}
