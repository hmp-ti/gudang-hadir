import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../domain/payroll.dart';
import '../data/payroll_repository.dart';
import '../domain/payroll_service.dart';
import '../../reports/domain/report_pdf_generator.dart';
import '../../../core/services/appwrite_service.dart';
import '../../../core/config/appwrite_config.dart';
import '../../settings/data/settings_dao.dart';

class PayrollDetailPage extends ConsumerWidget {
  final Payroll payroll;
  final String userName;
  final bool isPreview;

  const PayrollDetailPage({super.key, required this.payroll, required this.userName, this.isPreview = false});

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(payrollRepositoryProvider).savePayroll(payroll);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Slip Gaji Disimpan!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = payroll.detail;
    final breakdown = detail['breakdown'] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text(isPreview ? 'Preview Slip Gaji' : 'Slip Gaji'),
        actions: [
          if (isPreview)
            IconButton(icon: const Icon(Icons.save), onPressed: () => _save(context, ref))
          else
            IconButton(icon: const Icon(Icons.print), onPressed: () => _exportPdf(context)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    'SLIP GAJI KARYAWAN',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(userName, style: Theme.of(context).textTheme.titleLarge),
                  Text(
                    '${payroll.periodStart} s/d ${payroll.periodEnd}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Divider(height: 32, thickness: 2),

            _buildRow('Gaji Pokok', payroll.baseSalary, isBold: true),
            const SizedBox(height: 16),

            const Text(
              'Penerimaan (Tunjangan & Lembur)',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
            ),
            _buildRow(
              'Transport (${detail["daysPresent"]} hari)',
              breakdown['transport'],
            ), // Using dynamic access carefully
            _buildRow('Uang Makan (${detail["daysPresent"]} hari)', breakdown['meal']),
            _buildRow(
              'Lembur (${detail["totalOvertimeHours"]} jam)',
              breakdown['totalOvertime'],
            ), // Need check key logic in service
            _buildRow(
              'Total Tunjangan',
              payroll.totalAllowance + payroll.totalOvertime,
              isBold: true,
            ), // Simplified display

            const SizedBox(height: 16),
            const Text(
              'Potongan',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            _buildRow('Keterlambatan (${detail["totalLateMinutes"]} menit)', breakdown['lateDeduction']),
            _buildRow('Absen (${detail["absentDays"]} hari)', breakdown['absentDeduction']),
            _buildRow('Total Potongan', payroll.totalDeduction, isBold: true),

            const Divider(height: 32, thickness: 2),
            _buildRow('GAJI BERSIH (Take Home Pay)', payroll.netSalary, isBold: true, fontSize: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, dynamic value, {bool isBold = false, double fontSize = 14}) {
    double val = 0;
    if (value is int) val = value.toDouble();
    if (value is double) val = value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: fontSize),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            CurrencyFormatter.format(val),
            style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: fontSize),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context) async {
    try {
      // Fetch signature config
      final settingsDao = SettingsDao(AppwriteService.instance);
      final sigConfig = await settingsDao.getSignatureConfig();

      final Map<String, dynamic> data = {
        'payroll': payroll.toJson(),
        'userName': userName,
        'signerName': sigConfig['signerName'],
      };

      // Download images if exist
      if (sigConfig['signatureFileId'] != null) {
        try {
          final bytes = await AppwriteService.instance.storage.getFileDownload(
            bucketId: AppwriteConfig.storageBucketId,
            fileId: sigConfig['signatureFileId']!,
          );
          data['signatureBytes'] = bytes;
        } catch (_) {}
      }
      if (sigConfig['stampFileId'] != null) {
        try {
          final bytes = await AppwriteService.instance.storage.getFileDownload(
            bucketId: AppwriteConfig.storageBucketId,
            fileId: sigConfig['stampFileId']!,
          );
          data['stampBytes'] = bytes;
        } catch (_) {}
      }

      await ReportPdfGenerator.generate('Payslip', data);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
      }
    }
  }
}
