import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../features/leave/domain/leave.dart';
import '../../features/settings/data/settings_dao.dart';
import '../config/appwrite_config.dart';
import '../services/appwrite_service.dart';

class PdfGenerator {
  static Future<Uint8List> generateLeaveApproval(Leave leave, String adminName) async {
    final pdf = pw.Document();

    // Fetch Config
    final dao = SettingsDao(AppwriteService.instance);
    final config = await dao.getSignatureConfig();
    final signerName = (config['signerName'] != null && config['signerName']!.isNotEmpty)
        ? config['signerName']!
        : adminName;

    pw.MemoryImage? signatureImage;
    pw.MemoryImage? stampImage;

    try {
      if (config['signatureFileId'] != null) {
        final bytes = await AppwriteService.instance.storage.getFileDownload(
          bucketId: AppwriteConfig.storageBucketId,
          fileId: config['signatureFileId']!,
        );
        signatureImage = pw.MemoryImage(bytes);
      }
      if (config['stampFileId'] != null) {
        final bytes = await AppwriteService.instance.storage.getFileDownload(
          bucketId: AppwriteConfig.storageBucketId,
          fileId: config['stampFileId']!,
        );
        stampImage = pw.MemoryImage(bytes);
      }
    } catch (_) {
      // Ignore if image fetch fails
    }

    final dateFormat = DateFormat('d MMMM yyyy', 'id_ID');
    final startDate = dateFormat.format(DateTime.parse(leave.startDate));
    final endDate = dateFormat.format(DateTime.parse(leave.endDate));
    final today = dateFormat.format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text('SURAT IZIN CUTI', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24)),
                      pw.Text(
                        'GUDANG BITORA PROTOCOL',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 40),
              pw.Text('Banjarmasin, $today', style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 20),
              pw.Text('Yang bertanda tangan di bawah ini:', style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 10),
              _buildKeyValue('Nama', signerName),
              _buildKeyValue('Jabatan', 'Owner / Pimpinan'),
              pw.SizedBox(height: 20),
              pw.Text('Memberikan izin cuti kepada:', style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 10),
              _buildKeyValue('Nama', leave.userName),
              _buildKeyValue('Alasan', leave.reason),
              _buildKeyValue('Tanggal', '$startDate s/d $endDate'),
              pw.SizedBox(height: 20),
              pw.Text(
                'Demikian surat izin ini diberikan agar dapat dipergunakan sebagaimana mestinya.',
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 60),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('Mengetahui,', style: const pw.TextStyle(fontSize: 14)),
                      pw.SizedBox(height: 30),
                      pw.Stack(
                        alignment: pw.Alignment.center,
                        overflow: pw.Overflow.visible,
                        children: [
                          if (stampImage != null)
                            pw.Transform.translate(
                              offset: const PdfPoint(-40, 40),
                              child: pw.Opacity(opacity: 0.8, child: pw.Image(stampImage, width: 100, height: 100)),
                            ),
                          if (signatureImage != null)
                            pw.Image(signatureImage, width: 100, height: 80)
                          else
                            pw.SizedBox(height: 80, width: 100),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(signerName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                      pw.Text('Owner / Pimpinan', style: const pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildKeyValue(String key, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(key, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text(': '),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }
}
