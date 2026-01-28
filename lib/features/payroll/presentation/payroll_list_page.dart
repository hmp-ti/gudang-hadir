import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../domain/payroll.dart';
import '../domain/payroll_service.dart';
import 'payroll_generation_page.dart'; // Will create next
import 'payroll_detail_page.dart'; // Will create next

class PayrollListPage extends ConsumerStatefulWidget {
  const PayrollListPage({super.key});

  @override
  ConsumerState<PayrollListPage> createState() => _PayrollListPageState();
}

class _PayrollListPageState extends ConsumerState<PayrollListPage> {
  // In real app, we might need to list all payrolls or filter by user.
  // Admin view: All payrolls? Or select User first?
  // Let's make a list that shows recent payrolls.
  // But Repo currently gets payrolls BY USER.
  // We need a way to list ALL payrolls or search users.
  // For MVP, lets assume we browse by User in "Users" tab, and here we just generate?
  // Or, we list ALL payrolls. I'll check repo again.
  // Repo: getPayrolls(userId). Doesn't have getAllPayrolls.
  // I will assume for now we select a user to view history?
  // Or I can add `getAllPayrolls` to Repo.

  // Let's implement a simple "Payroll Dashboard" where we can:
  // 1. Generate New (Bulk or Single) -> Goes to Generation Page
  // 2. View History (This requires listing all or searching).

  // To keep it simple: "Payroll List" will just show a button "Generate Payroll"
  // and a list of RECENTLY generated payrolls (need to update Repo for list ALL).

  // Updated Repo Plan:
  // I'll stick to 'getPayrolls(userId)' constraint for now,
  // maybe we just list users and then click to see their payroll history?

  // Let's change this to "Payroll Dashboard".
  // Filter by Month/Year?

  // Let's trying to list documents without query (List All).

  bool _isLoading = true;
  final List<Payroll> _payrolls = [];

  @override
  void initState() {
    super.initState();
    _loadAllPayrolls();
  }

  Future<void> _loadAllPayrolls() async {
    setState(() => _isLoading = true);
    final repo = ref.read(payrollRepositoryProvider);
    final data = await repo.getAllPayrolls();
    if (mounted) {
      setState(() {
        _payrolls.clear();
        _payrolls.addAll(data);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Penggajian')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const PayrollGenerationPage()));
          _loadAllPayrolls(); // Refresh after return
        },
        label: const Text('Buat Slip Gaji'),
        icon: const Icon(Icons.calculate),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllPayrolls,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_payrolls.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 100),
                child: Center(
                  child: Text(
                    'Belum ada data penggajian.\nSilakan tekan tombol "Buat Slip Gaji".',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              )
            else
              ..._payrolls.map(
                (payroll) => Card(
                  child: ListTile(
                    title: Text('Slip Gaji ${payroll.periodStart}'),
                    subtitle: Text('Gaji Bersih: ${CurrencyFormatter.format(payroll.netSalary)}'),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      // We don't have user name readily available in Payroll object :(
                      // We might need to fetch it or store it.
                      // For now passing "Karyawan" or maybe fetch user.
                      // Actually better to store userName in Payroll or fetch.
                      // Let's passed generic "Detail" for now.
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PayrollDetailPage(
                            payroll: payroll,
                            userName: 'Karyawan ${payroll.userId.substring(0, 4)}...',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
    );
  }
}
