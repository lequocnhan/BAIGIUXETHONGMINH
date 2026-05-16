import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class PaymentScreen extends StatefulWidget {
  final int amount;
  final String username;
  final String transId;

  const PaymentScreen({
    super.key,
    required this.amount,
    required this.username,
    required this.transId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late DatabaseReference _transRef;

  final _currency = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
  );

  @override
  void initState() {
    super.initState();

    _transRef = FirebaseDatabase.instance
        .ref("Users/${widget.username}/current_payment");

    _initData();
  }

  Future<void> _initData() async {
    await _transRef.set({
      "amount": widget.amount,
      "status": "pending",
      "transId": widget.transId,
      "time": DateFormat('HH:mm - dd/MM/yyyy').format(DateTime.now()),
    });
  }

  String _vietQRUrl() {
    return "https://img.vietqr.io/image/mbbank-0123456789-compact.png"
        "?amount=${widget.amount}"
        "&addInfo=NAP%20TIEN%20${widget.username}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thanh toán nạp tiền"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: StreamBuilder(
          stream: _transRef.onValue,
          builder: (context, snapshot) {
            if (snapshot.hasData &&
                snapshot.data!.snapshot.value != null) {
              final data = snapshot.data!.snapshot.value as Map;

              if (data['status'] == "success") {
                return _buildSuccessUI();
              }
            }
            return _buildPendingUI(_vietQRUrl());
          },
        ),
      ),
    );
  }

  Widget _buildPendingUI(String url) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          const Text(
            "ĐANG CHỜ XÁC NHẬN...",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          Image.network(url, width: 300),
          const Padding(
            padding: EdgeInsets.all(25),
            child: Text(
              "Vui lòng quét VietQR để chuyển khoản. "
              "Hệ thống sẽ tự động cập nhật khi Admin duyệt.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessUI() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 80),
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 120,
          ),
          const SizedBox(height: 20),
          const Text(
            "THÀNH CÔNG!",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 50),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(
                horizontal: 50,
                vertical: 15,
              ),
            ),
            onPressed: () async {
              final userRef = FirebaseDatabase.instance
                  .ref("Users/${widget.username}/balance");

              final current = await userRef.get();
              final currentBalance =
                  int.tryParse(current.value.toString()) ?? 0;

              await userRef.set(currentBalance + widget.amount);

              await FirebaseDatabase.instance
                  .ref("Users/${widget.username}/notifications")
                  .push()
                  .set({
                "title": "Nạp tiền thành công",
                "content":
                    "Ví của bạn đã được cộng ${_currency.format(widget.amount)}.",
                "time": DateFormat('HH:mm').format(DateTime.now()),
                "type": "payment",
              });

              if (mounted) Navigator.pop(context);
            },
            child: const Text(
              "HOÀN THÀNH",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          )
        ],
      ),
    );
  }
}