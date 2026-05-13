import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart'; 
import 'scanner_page.dart';
import 'update_profile_page.dart';
import 'payment_screen.dart'; // ĐẢM BẢO CÓ FILE NÀY

class HomePage extends StatefulWidget {
  final Map userData;
  const HomePage({super.key, required this.userData});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late DatabaseReference _userRef;
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  final String laptopIp = "192.168.1.205";

  @override
  void initState() {
    super.initState();
    String username = widget.userData['username'] ?? "Nhan";
    _userRef = FirebaseDatabase.instance.ref("Users/$username");
  }

  void _goToUpdateProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UpdateProfilePage(userData: widget.userData)),
    );
  }

  // --- HÀM HIỂN THỊ DANH SÁCH THÔNG BÁO ---
  void _showNotificationsList(Map? notifications) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 15),
              Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("Thông báo", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3C72))),
              ),
              const Divider(height: 1),
              if (notifications == null)
                const Expanded(child: Center(child: Text("Bạn chưa có thông báo nào", style: TextStyle(color: Colors.grey))))
              else
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    children: notifications.entries.map((e) {
                      var val = e.value;
                      return Card(
                        elevation: 0,
                        color: val['type'] == 'alert' ? Colors.red[50] : Colors.blue[50],
                        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: val['type'] == 'alert' ? Colors.red : Colors.blue,
                            child: Icon(
                              val['type'] == 'alert' ? Icons.warning_amber_rounded : Icons.notifications_active_outlined,
                              color: Colors.white, size: 20,
                            ),
                          ),
                          title: Text(val['title'] ?? "Thông báo", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          subtitle: Text(val['content'] ?? ""),
                          trailing: Text(val['time'] ?? "", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ),
                      );
                    }).toList().reversed.toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // --- LUỒNG NẠP TIỀN MỚI ---
  
  // BƯỚC 1: NHẬP SỐ TIỀN
  void _showTopUpDialog() {
    TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Nạp tiền vào ví"),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: "Nhập số tiền muốn nạp", suffixText: "VNĐ"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () {
              if (amountController.text.isNotEmpty) {
                int amount = int.parse(amountController.text);
                Navigator.pop(context);
                _showInvoiceQR(amount); // Chuyển sang bước hiện mã hóa đơn
              }
            },
            child: const Text("Tạo hóa đơn"),
          ),
        ],
      ),
    );
  }

  // BƯỚC 2: HIỆN QR HÓA ĐƠN NỘI BỘ ĐỂ QUÉT
  void _showInvoiceQR(int amount) {
    String username = widget.userData['username'] ?? "Nhan";
    String transId = "TXN${DateTime.now().millisecondsSinceEpoch}";
    String invoiceData = "tdmu_parking:$amount:$username:$transId";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Hóa đơn nạp tiền", textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Số tiền: ${currencyFormatter.format(amount)}", 
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              width: 200, height: 200,
              child: QrImageView(data: invoiceData, size: 200),
            ),
            const SizedBox(height: 15),
            const Text("Dùng nút 'Quét mã' trên App để thanh toán hóa đơn này", 
              textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: StreamBuilder(
        stream: _userRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            Map data = snapshot.data!.snapshot.value as Map;
            
            widget.userData['name'] = data['name'];
            widget.userData['balance'] = data['balance'];
            widget.userData['in_parking'] = data['in_parking'] ?? false;
            widget.userData['notifications'] = data['notifications'];

            String plate = "CHƯA CÓ";
            if (data['vehicles'] != null) {
              Map v = data['vehicles'] as Map;
              if (v.isNotEmpty) plate = v.values.first['plate'] ?? "CHƯA CÓ";
            }
            widget.userData['plate_number'] = plate;

            return SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(data['notifications']),
                  _buildWalletCard(),
                  _buildMenuGrid(),
                  _buildRecentActivity(data['history']),
                ],
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildHeader(Map? notifications) {
    String username = widget.userData['username'] ?? "Nhan";
    String profileImageUrl = "http://$laptopIp:5000/get_face/$username.jpg";

    return Container(
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Xin chào,", style: TextStyle(color: Colors.grey, fontSize: 14)),
                Text(widget.userData['name'] ?? "Người dùng", 
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3C72))),
              ],
            ),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF1E3C72), size: 30),
                onPressed: () => _showNotificationsList(notifications),
              ),
              if (notifications != null)
                Positioned(
                  right: 12, top: 12,
                  child: Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                  ),
                )
            ],
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _goToUpdateProfile,
            child: CircleAvatar(
              radius: 25,
              backgroundColor: const Color(0xFF1E3C72),
              child: ClipOval(
                child: Image.network(
                  profileImageUrl,
                  fit: BoxFit.cover,
                  width: 50, height: 50,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white, size: 30),
                  key: ValueKey(DateTime.now().millisecondsSinceEpoch.toString()),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildWalletCard() {
    bool inParking = widget.userData['in_parking'] ?? false;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 200, width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1E3C72), Color(0xFF2A5298)]),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Ví điện tử TDMU", style: TextStyle(color: Colors.white70, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: inParking ? Colors.greenAccent : Colors.white24, borderRadius: BorderRadius.circular(10)),
                      child: Text(inParking ? "ĐANG TRONG BÃI" : "NGOÀI BÃI", style: const TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                const SizedBox(height: 15),
                Text(currencyFormatter.format(int.parse(widget.userData['balance'].toString())), style: const TextStyle(color: Colors.white, fontSize: 35, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text("BIỂN SỐ: ${widget.userData['plate_number']}", style: const TextStyle(color: Colors.white, fontSize: 14, letterSpacing: 1.5, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Positioned(
            right: 20, bottom: 25,
            child: GestureDetector(
              onTap: () => _showFullQR(context),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: QrImageView(data: widget.userData['username'] ?? "no_id", size: 60.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        children: [
          _menuAction(Icons.qr_code_scanner, "Quét mã", Colors.orange, () async {
               await Navigator.push(context, MaterialPageRoute(builder: (context) => const ScannerPage()));
          }),
          _menuAction(Icons.add_card, "Nạp tiền", Colors.green, _showTopUpDialog),
          _menuAction(Icons.history, "Lịch sử", Colors.purple, () {}),
          _menuAction(Icons.map_outlined, "Sơ đồ", Colors.blue, () {}),
          _menuAction(Icons.directions_car, "Vị trí xe", Colors.red, () {}),
          _menuAction(Icons.receipt_long, "Vé tháng", Colors.teal, () {}),
          _menuAction(Icons.notifications_none, "Thông báo", Colors.amber, () => _showNotificationsList(widget.userData['notifications'])),
          _menuAction(Icons.settings, "Cài đặt", Colors.grey, _goToUpdateProfile),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(Map? history) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Giao dịch gần đây", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          if (history == null) 
            const Center(child: Text("Chưa có giao dịch nào", style: TextStyle(color: Colors.grey)))
          else
            ...history.entries.map((e) => _activityItem(
              e.value['type'] == "VAO" ? "Vào cổng" : "Ra cổng", 
              e.value['amount'] ?? "0đ", 
              e.value['time'] ?? "--:--", 
              e.value['type'] == "VAO" ? Icons.login : Icons.logout,
              e.value['type'] == "VAO" ? Colors.blue : Colors.redAccent
            )).toList().reversed.take(3),
        ],
      ),
    );
  }

  Widget _menuAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _activityItem(String title, String amount, String time, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 15),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(time, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ]),
          const Spacer(),
          Text(amount, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showFullQR(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Mã thành viên TDMU", textAlign: TextAlign.center),
        content: SizedBox(width: 250, height: 250, child: Center(child: QrImageView(data: widget.userData['username'] ?? "no_id", size: 220.0))),
      ),
    );
  }
}