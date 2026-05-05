import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'home_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();

  void _handleLogin() async {
    String username = _userController.text.trim();
    String password = _passController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đầy đủ tài khoản/mật khẩu")),
      );
      return;
    }

    // Hiện vòng xoay chờ
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Truy cập Database để kiểm tra User
      final ref = FirebaseDatabase.instance.ref("Users/$username");
      final snapshot = await ref.get();

      if (!mounted) return;
      Navigator.pop(context); // Tắt vòng xoay

      if (snapshot.exists) {
        Map data = snapshot.value as Map;
        // Kiểm tra mật khẩu
        if (data['password'] == password) {
          // THÀNH CÔNG: Chuyền toàn bộ data (tên, số dư...) qua Home
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(userData: data),
            ),
          );
        } else {
          _showError("Mật khẩu không chính xác!");
        }
      } else {
        _showError("Tài khoản không tồn tại!");
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showError("Lỗi kết nối: $e");
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[900],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const SizedBox(height: 80),
            const Icon(Icons.local_parking, size: 100, color: Colors.white),
            const Text(
              "TDMU SMART PARKING",
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 50),
            _inputField("Username", _userController, Icons.person),
            const SizedBox(height: 15),
            _inputField("Mật khẩu", _passController, Icons.lock, isPass: true),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text("ĐĂNG NHẬP", style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage()));
              },
              child: const Text("Chưa có tài khoản? Đăng ký ngay", style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(String hint, TextEditingController ctr, IconData icon, {bool isPass = false}) {
    return TextField(
      controller: ctr,
      obscureText: isPass,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.blue[900]),
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }
}