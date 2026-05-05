import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBxedvFCklxAyJdfpXIa5akiTrbqVN8N-U",
      authDomain: "tdmusmartparking.firebaseapp.com",
      databaseURL: "https://tdmusmartparking-default-rtdb.asia-southeast1.firebasedatabase.app",
      projectId: "tdmusmartparking",
      storageBucket: "tdmusmartparking.firebasestorage.app",
      messagingSenderId: "1011054007785",
      appId: "1:1011054007785:web:758cc93fc3752ef951e778",
      measurementId: "G-8Q157R0XKJ",
    ),
  );
  runApp(const MaterialApp(
    home: LoginPage(),
    debugShowCheckedModeBanner: false,
  ));
}