import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'payment_screen.dart'; // Đảm bảo đã có file này trong thư mục lib

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  bool isScanned = false; // Biến chặn để không quét trùng nhiều lần

  // --- HÀM XỬ LÝ DỮ LIỆU SAU KHI QUÉT ---
  void _handleBarcode(BarcodeCapture capture) {
    if (isScanned) return; 

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null) {
        debugPrint('Dữ liệu quét được: $code');
        
        // 1. KIỂM TRA NẾU LÀ MÃ NẠP TIỀN NỘI BỘ
        if (code.startsWith("tdmu_parking:")) {
          setState(() {
            isScanned = true; // Khóa scanner lại để chuyển trang
          });
          _processInternalInvoice(code);
        } 
        // 2. KIỂM TRA NẾU LÀ MÃ XE RA/VÀO (Hệ thống hiện tại)
        else if (code.contains("GATE")) {
          setState(() {
            isScanned = true;
          });
          _processGateEntry(code);
        }
        // 3. CÁC LOẠI MÃ KHÔNG HỢP LỆ
        else {
          _showError("Mã QR không thuộc hệ thống TDMU!");
        }
        break; 
      }
    }
  }

  // --- LOGIC XỬ LÝ HÓA ĐƠN NẠP TIỀN ---
  void _processInternalInvoice(String code) {
    try {
      // Tách chuỗi dữ liệu: tdmu_parking:amount:username:transId
      final parts = code.split(":");
      if (parts.length < 4) throw Exception("Sai định dạng hóa đơn");

      int amount = int.parse(parts[1]);
      String username = parts[2];
      String transId = parts[3];

      // Chuyển ngay sang màn hình thanh toán tích xanh
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            amount: amount,
            username: username,
            transId: transId,
          ),
        ),
      );
    } catch (e) {
      _showError("Lỗi cấu trúc hóa đơn!");
      setState(() => isScanned = false);
    }
  }

  // --- LOGIC XỬ LÝ XE RA/VÀO ---
  void _processGateEntry(String gateCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Thông tin cổng"),
        content: Text("Hệ thống ghi nhận bạn tại: $gateCode"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => isScanned = false); // Mở lại scanner sau khi đóng dialog
            },
            child: const Text("Xác nhận"),
          )
        ],
      ),
    );
  }

  // --- HIỂN THỊ THÔNG BÁO LỖI ---
  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    // Sau 2 giây cho phép người dùng quét lại mã khác
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => isScanned = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Máy quét TDMU Smart", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3C72),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Lớp 1: Camera Scanner
          MobileScanner(
            onDetect: _handleBarcode,
          ),
          
          // Lớp 2: Khung quét trang trí cho chuyên nghiệp
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent, width: 4),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Stack(
                children: [
                  // Các góc vuông trang trí
                  Positioned(top: 0, left: 0, child: Container(width: 40, height: 40, decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white, width: 6), left: BorderSide(color: Colors.white, width: 6))))),
                  Positioned(top: 0, right: 0, child: Container(width: 40, height: 40, decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white, width: 6), right: BorderSide(color: Colors.white, width: 6))))),
                  Positioned(bottom: 0, left: 0, child: Container(width: 40, height: 40, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white, width: 6), left: BorderSide(color: Colors.white, width: 6))))),
                  Positioned(bottom: 0, right: 0, child: Container(width: 40, height: 40, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white, width: 6), right: BorderSide(color: Colors.white, width: 6))))),
                ],
              ),
            ),
          ),
          
          // Lớp 3: Hướng dẫn người dùng
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  "Đang chờ quét mã hóa đơn...",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                  child: const Text(
                    "Hãy đưa mã QR vào trung tâm khung hình",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}