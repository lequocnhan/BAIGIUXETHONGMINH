import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class UpdateProfilePage extends StatefulWidget {
  final Map userData;
  const UpdateProfilePage({super.key, required this.userData});

  @override
  State<UpdateProfilePage> createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  final _nameController = TextEditingController();
  XFile? _imageFile; 
  bool _isLoading = false;
  List<Map<String, dynamic>> _vehicleList = [];

  final String laptopIp = "192.168.1.205"; 

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userData['name'] ?? "";
    _loadVehicles();
  }

  void _loadVehicles() {
    if (widget.userData['vehicles'] != null) {
      Map? vehiclesRaw = widget.userData['vehicles'] as Map?;
      vehiclesRaw?.forEach((key, value) {
        setState(() {
          _vehicleList.add({
            "plate": value['plate'] ?? "",
            "type": value['type'] ?? "motorcycle",
          });
        });
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera, 
      imageQuality: 50
    );
    if (pickedFile != null) {
      setState(() => _imageFile = pickedFile);
    }
  }

  void _showAddVehicleDialog() {
    TextEditingController plateController = TextEditingController();
    String selectedType = 'motorcycle';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Thêm xe mới"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: plateController,
                decoration: const InputDecoration(labelText: "Biển số xe", hintText: "Ví dụ: 65H52106"),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 15),
              DropdownButton<String>(
                value: selectedType,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'motorcycle', child: Text("Xe máy")),
                  DropdownMenuItem(value: 'car', child: Text("Ô tô")),
                ],
                onChanged: (val) => setDialogState(() => selectedType = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
            ElevatedButton(
              onPressed: () {
                if (plateController.text.isNotEmpty) {
                  setState(() {
                    _vehicleList.add({
                      "plate": plateController.text.toUpperCase().replaceAll(" ", ""),
                      "type": selectedType
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Thêm"),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _sendImageToLaptop(String username) async {
    if (_imageFile == null) return true;
    try {
      var request = http.MultipartRequest('POST', Uri.parse('http://$laptopIp:5000/upload_face'));
      request.fields['username'] = username;
      
      if (kIsWeb) {
        var bytes = await _imageFile!.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: '$username.jpg'));
      } else {
        request.files.add(await http.MultipartFile.fromPath('image', _imageFile!.path));
      }

      var response = await request.send().timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi gửi ảnh: $e");
      return false;
    }
  }

  Future<void> _saveAll() async {
    setState(() => _isLoading = true);
    String username = (widget.userData['username'] ?? "Nhan").toString();
    final dbRef = FirebaseDatabase.instance.ref("Users/$username");

    try {
      if (_imageFile != null) {
        await _sendImageToLaptop(username);
      }
      await dbRef.update({"name": _nameController.text});

      Map<String, dynamic> vehiclesMap = {};
      for (int i = 0; i < _vehicleList.length; i++) {
        vehiclesMap["xe_0${i + 1}"] = {
          "plate": _vehicleList[i]['plate'],
          "type": _vehicleList[i]['type']
        };
      }
      await dbRef.child("vehicles").set(vehiclesMap);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã lưu mọi thay đổi!")));
      Navigator.pop(context);
    } catch (e) {
      print("Lỗi SaveAll: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Logic xử lý ảnh hiển thị cho cả Web và Mobile
    ImageProvider? imageProvider;
    if (_imageFile != null) {
      if (kIsWeb) {
        imageProvider = NetworkImage(_imageFile!.path);
      } else {
        imageProvider = FileImage(File(_imageFile!.path));
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Hồ sơ & Danh sách xe"), backgroundColor: const Color(0xFF1E3C72)),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: imageProvider,
                  child: imageProvider == null 
                      ? const Icon(Icons.camera_alt, size: 40, color: Color(0xFF1E3C72)) 
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Họ và tên", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("DANH SÁCH XE ĐĂNG KÝ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.add_circle, color: Colors.blue, size: 30), onPressed: _showAddVehicleDialog),
              ],
            ),
            const SizedBox(height: 10),
            ..._vehicleList.map((v) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Icon(v['type'] == 'car' ? Icons.directions_car : Icons.motorcycle, color: const Color(0xFF1E3C72)),
                title: Text(v['plate'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(v['type'] == 'car' ? "Ô tô" : "Xe máy"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => setState(() => _vehicleList.remove(v)),
                ),
              ),
            )),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _saveAll,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3C72), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
                child: const Text("LƯU TẤT CẢ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }
}