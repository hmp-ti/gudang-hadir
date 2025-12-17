import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScanPage extends StatefulWidget {
  const QRScanPage({super.key});

  @override
  State<QRScanPage> createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: MobileScanner(
        controller: controller,
        errorBuilder: (context, error, child) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('Gagal memuat kamera: ${error.errorCode}', style: const TextStyle(color: Colors.red)),
                if (error.errorDetails?.message != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Detail: ${error.errorDetails!.message}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
              ],
            ),
          );
        },
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              // Prevent multiple pops
              if (mounted) {
                controller.stop(); // Stop scanning before popping
                Navigator.pop(context, barcode.rawValue);
              }
              return;
            }
          }
        },
      ),
    );
  }
}
