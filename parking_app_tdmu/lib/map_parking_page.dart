import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_provider.dart';
import 'dart:ui_web' as ui; 
import 'package:web/web.dart' as web; 

class MapParkingPage extends StatefulWidget {
  const MapParkingPage({super.key});

  @override
  State<MapParkingPage> createState() => _MapParkingPageState();
}

class _MapParkingPageState extends State<MapParkingPage> {
  final String viewID = 'smart-parking-map';

  @override
  void initState() {
    super.initState();
    // Đăng ký khung nhìn HTML trỏ vào file map_core.html nằm trong thư mục web
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      viewID,
      (int viewId) => web.HTMLIFrameElement()
        ..src = 'assets/map_core.html' // File HTML xử lý định vị Leaflet
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%',
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = settings.isDarkMode;

    return Scaffold(
      backgroundColor: settings.currentBackground.isEmpty 
          ? Theme.of(context).scaffoldBackgroundColor 
          : Colors.transparent,
      appBar: AppBar(
        title: const Text('Định vị bãi xe gần nhất', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? Colors.grey[900] : Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: settings.currentBackground.isNotEmpty
            ? BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(settings.currentBackground),
                  fit: BoxFit.cover,
                ),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: [
              // Thanh chú thích trực quan
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900]?.withOpacity(0.9) : Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNoteItem(Colors.blue, "Bãi xe Cổng 1 (TDMU)"),
                    _buildNoteItem(Colors.green, "Bãi xe Cổng 2"),
                    _buildNoteItem(Colors.red, "Vị trí của bạn"),
                  ],
                ),
              ),
              
              // Khung hiển thị bản đồ định vị
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.grey[800]! : Colors.grey[300]!, 
                      width: 2
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: HtmlElementView(viewType: viewID),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }
}