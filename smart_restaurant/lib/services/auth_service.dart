import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // 1. สร้างตัวแทน (Instance) ของ Firebase Auth (เสมือนเรียกหัวหน้า รปภ. มารับคำสั่ง)
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 2. ฟังก์ชันเข้าสู่ระบบ (Sign In)
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      // สั่งให้ รปภ. เอาข้อมูลไปเช็คกับฐานข้อมูลกลางของ Google
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password,
      );
      return result.user; // ถ้าสำเร็จ คืนค่าข้อมูลผู้ใช้กลับไป
    } catch (e) {
      print("❌ เกิดข้อผิดพลาดในการ Login: $e");
      return null; // ถ้าล้มเหลว (เช่น รหัสผิด) คืนค่าความว่างเปล่า
    }
  }

  // 3. ฟังก์ชันสมัครสมาชิก (Sign Up) สำหรับผู้ใช้ใหม่
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password,
      );
      return result.user;
    } catch (e) {
      print("❌ เกิดข้อผิดพลาดในการ Register: $e");
      return null;
    }
  }

  // 4. ฟังก์ชันออกจากระบบ (Sign Out)
  Future<void> signOut() async {
    await _auth.signOut();
  }
}