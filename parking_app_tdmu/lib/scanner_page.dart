import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'payment_screen.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  bool isScanned = false;

  void _handleBarcode(BarcodeCapture capture) {
    if (isScanned) return;

    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue;
      if (code == null) continue;

      debugPrint('Scanned: $code');

      if (code.startsWith("tdmu_parking:")) {
        setState(() => isScanned = true);
        _processInternalInvoice(code);
      } 
      else if (code.contains("GATE")) {
        setState(() => isScanned = true);
        _processGateEntry(code);
      } 
      else {
        _showError("Mã QR không thuộc hệ thống TDMU!");
      }

      break;
    }
  }

  void _processInternalInvoice(String code) {
    try {
      final parts = code.split(":");
      if (parts.length < 4) throw Exception("Invalid format");

      final amount = int.parse(parts[1]);
      final username = parts[2];
      final transId = parts[3];

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentScreen(
            amount: amount,
            username: username,
            transId: transId,
          ),
        ),
      );
    } catch (_) {
      _showError("Lỗi cấu trúc hóa đơn!");
      setState(() => isScanned = false);
    }
  }

  void _processGateEntry(String gateCode) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text("Thông tin cổng"),
        content: Text("Hệ thống ghi nhận bạn tại: $gateCode"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => isScanned = false);
            },
            child: const Text("Xác nhận"),
          )
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => isScanned = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Máy quét TDMU Smart"),
        backgroundColor: const Color(0xFF1E3C72),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(onDetect: _handleBarcode),

          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent, width: 4),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),

          const Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  "Đang chờ quét mã...",
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 10),
                Text(
                  "Đưa mã QR vào giữa khung hình",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}