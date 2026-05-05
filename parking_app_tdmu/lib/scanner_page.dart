import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import 'package:flutter/material.dart';

class ScannerPage extends StatelessWidget {
  const ScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét mã vào cổng'),
        backgroundColor: const Color(0xFF1E3C72),
      ),
      body: AiBarcodeScanner(
        onDispose: () {
          debugPrint("Barcode scanner disposed!");
        },
        onDetect: (BarcodeCapture capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            final String? code = barcode.rawValue;
            if (code != null) {
              debugPrint("Tìm thấy mã: $code");
              // Sau khi quét thấy mã, quay lại và gửi kết quả về
              Navigator.pop(context, code);
            }
          }
        },
      ),
    );
  }
}