import 'package:flutter/material.dart';

class SettingsProvider with ChangeNotifier {
  // 1. Quản lý Chế độ Sáng/Tối
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  // 2. Quản lý Hình nền (Lưu path của ảnh hoặc màu nền)
  String _currentBackground = 'assets/bg_default.png';
  String get currentBackground => _currentBackground;

  // 3. Quản lý Chuông thông báo
  bool _isNotificationSoundOn = true;
  bool get isNotificationSoundOn => _isNotificationSoundOn;

  // Hàm thay đổi Chế độ Sáng/Tối
  void toggleTheme(bool value) {
    _isDarkMode = value;
    notifyListeners(); // Báo cho toàn app biết để vẽ lại giao diện
  }

  // Hàm thay đổi hình nền
  void changeBackground(String newBgPath) {
    _currentBackground = newBgPath;
    notifyListeners();
  }

  // Hàm bật/tắt chuông
  void toggleNotificationSound(bool value) {
    _isNotificationSoundOn = value;
    notifyListeners();
  }
}