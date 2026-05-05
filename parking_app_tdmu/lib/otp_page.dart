import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class OtpPage extends StatefulWidget {
  final Map userData;
  const OtpPage({super.key, required this.userData});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _otpController = TextEditingController();

  void _verifyOtp() async {
    String otpCode = _otpController.text.trim();
    if (otpCode.isEmpty) return;

    // Hiện vòng xoay chờ xác nhận
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. KIỂM TRA NẾU ĐANG CHẠY TRÊN WEB
      if (widget.userData['isWeb'] == true) {
        ConfirmationResult webResult = widget.userData['webResult'];
        await webResult.confirm(otpCode);
      } 
      // 2. KIỂM TRA NẾU ĐANG CHẠY TRÊN MOBILE
      else {
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: widget.userData['verificationId'],
          smsCode: otpCode,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }

      // 3. NẾU XÁC THỰC THÀNH CÔNG -> LƯU VÀO DATABASE
      String username = widget.userData['username'];
      await FirebaseDatabase.instance.ref("Users/$username").set({
        "name": widget.userData['name'],
        "password": widget.userData['password'],
        "phone": widget.userData['phone'],
        "balance": 100000, // Tặng 100k cho user mới
      });

      Navigator.pop(context); // Tắt vòng xoay
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đăng ký thành công!"))
      );

      // Quay về trang đầu tiên (Trang Đăng nhập)
      Navigator.of(context).popUntil((route) => route.isFirst);

    } catch (e) {
      Navigator.pop(context); // Tắt vòng xoay
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Mã OTP sai hoặc lỗi: ${e.toString()}"))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[800],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mark_email_unread_outlined, size: 80, color: Colors.white),
              const SizedBox(height: 20),
              const Text("NHẬP MÃ OTP", 
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("Mã đã được gửi đến ${widget.userData['phone']}", 
                style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 30),
              TextField(
                controller: _otpController,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 30, color: Colors.white, letterSpacing: 10),
                decoration: const InputDecoration(
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  minimumSize: const Size(200, 50),
                ),
                child: const Text("XÁC NHẬN", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}