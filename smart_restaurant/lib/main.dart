import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Restaurant',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      // 🛠️ 3. ใช้ StreamBuilder เป็นยามเฝ้าประตู สับรางอัตโนมัติ!
      home: StreamBuilder<User?>(
        // ดักฟังการเปลี่ยนแปลงสถานะ (ล็อกอิน/ล็อกเอาท์)
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // สถานะที่ 1: กำลังโหลดเช็คข้อมูล (โชว์วงกลมหมุนๆ แป๊บเดียว)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          // สถานะที่ 2: พบข้อมูลผู้ใช้ (มี Token ค้างอยู่) -> ยิงไปหน้า Home เลย
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          // สถานะที่ 3: ไม่พบข้อมูล (เพิ่งโหลดแอปครั้งแรก หรือเพิ่งล็อกเอาท์) -> ไปหน้า Login
          return const LoginScreen();
        },
      ),
    );
  }
}