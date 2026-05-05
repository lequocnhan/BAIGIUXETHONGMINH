import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// QUAN TRỌNG: Thêm dòng này để hỗ trợ Recaptcha trên Web
import 'package:flutter/foundation.dart' show kIsWeb;
import 'otp_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  // Khai báo biến verifier để dùng cho Web
  ConfirmationResult? _confirmationResult;

  void _handleRegister() async {
    String phoneNumber = _phoneController.text.trim();
    String username = _userController.text.trim();
    
    if (phoneNumber.isEmpty || username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đầy đủ Username và SĐT"))
      );
      return;
    }

    // Chuyển định dạng SĐT sang +84
    if (phoneNumber.startsWith('0')) {
      phoneNumber = '+84${phoneNumber.substring(1)}';
    }

    // Hiện vòng xoay chờ
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      if (kIsWeb) {
        // CÁCH XỬ LÝ RIÊNG CHO WEB
        final auth = FirebaseAuth.instance;
        
        // signInWithPhoneNumber sẽ tự động tìm container 'recaptcha-container' đã tạo trong index.html
        _confirmationResult = await auth.signInWithPhoneNumber(phoneNumber);
        
        if (!mounted) return;
        Navigator.pop(context); // Tắt vòng xoay

        // Chuyển sang trang OTP với dữ liệu cần thiết
        Map data = {
          "username": username,
          "name": _nameController.text.trim(),
          "password": _passController.text.trim(),
          "phone": phoneNumber,
          "webResult": _confirmationResult,
          "isWeb": true,
        };
        
        Navigator.push(context, MaterialPageRoute(builder: (context) => OtpPage(userData: data)));
      } else {
        // Cấu hình cho Mobile
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          codeSent: (String verificationId, int? resendToken) {
            Navigator.pop(context);
            Map data = {
              "username": username,
              "name": _nameController.text.trim(),
              "password": _passController.text.trim(),
              "phone": phoneNumber,
              "verificationId": verificationId,
              "isWeb": false,
            };
            Navigator.push(context, MaterialPageRoute(builder: (context) => OtpPage(userData: data)));
          },
          verificationFailed: (e) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: ${e.message}")));
          },
          verificationCompleted: (credential) {},
          codeAutoRetrievalTimeout: (id) {},
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi hệ thống: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[900],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const SizedBox(height: 50),
            const Icon(Icons.person_add, size: 80, color: Colors.white),
            const Text("ĐĂNG KÝ HỆ THỐNG", 
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            _input("Username", _userController),
            _input("Họ tên", _nameController),
            _input("Số điện thoại", _phoneController),
            _input("Mật khẩu", _passController, isPass: true),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _handleRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange, 
                minimumSize: const Size(double.infinity, 50)
              ),
              child: const Text("GỬI MÃ XÁC THỰC", style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _input(String hint, TextEditingController ctr, {bool isPass = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: ctr,
        obscureText: isPass,
        decoration: InputDecoration(
          hintText: hint, 
          filled: true, 
          fillColor: Colors.white, 
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))
        ),
      ),
    );
  }
}