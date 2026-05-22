import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt hệ thống'),
        backgroundColor: Colors.blue,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. Chế độ Sáng/Tối
          Card(
            child: SwitchListTile(
              title: const Text('Chế độ tối (Dark Mode)'),
              subtitle: const Text('Thay đổi giao diện app sang màu đen'),
              secondary: const Icon(Icons.dark_mode),
              value: settings.isDarkMode,
              onChanged: (bool value) {
                settings.toggleTheme(value);
              },
            ),
          ),
          const SizedBox(height: 10),

          // 2. Chuông thông báo
          Card(
            child: SwitchListTile(
              title: const Text('Chuông thông báo'),
              subtitle: const Text('Phát âm thanh khi có thông báo bãi xe'),
              secondary: const Icon(Icons.notifications_active),
              value: settings.isNotificationSoundOn,
              onChanged: (bool value) {
                settings.toggleNotificationSound(value);
              },
            ),
          ),
          const SizedBox(height: 10),

          // 3. Chọn hình nền app
          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.wallpaper),
              title: const Text('Thay đổi hình nền app'),
              subtitle: const Text('Chọn hình nền cho màn hình chính'),
              children: [
                ListTile(
                  title: const Text('Hình nền mặc định (Xanh TDMU)'),
                  trailing: settings.currentBackground == 'assets/bg_default.png' 
                      ? const Icon(Icons.check, color: Colors.blue) : null,
                  onTap: () => settings.changeBackground('assets/bg_default.png'),
                ),
                ListTile(
                  title: const Text('Hình nền Công nghệ (Neon)'),
                  trailing: settings.currentBackground == 'assets/bg_tech.png' 
                      ? const Icon(Icons.check, color: Colors.blue) : null,
                  onTap: () => settings.changeBackground('assets/bg_tech.png'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}