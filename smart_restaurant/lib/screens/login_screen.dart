import 'package:flutter/material.dart';
import '../services/auth_service.dart'; 
import 'register_screen.dart';
import 'home_screen.dart'; // 🚩 1. อย่าลืมนำเข้า HomeScreen นะครับ!

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 🛠️ ฟังก์ชันสำหรับล็อกอิน (อัปเกรดแก้บั๊กปุ่มค้าง)
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();

      // 📡 1. ส่งข้อมูลไปให้ Firebase ตรวจสอบ
      var user = await _authService.signInWithEmail(email, password);

      if (!mounted) return;

      // 2. เช็คผลลัพธ์
      if (user == null) {
        // ล็อกอินไม่ผ่าน -> ปลดล็อกปุ่มและโชว์ Error
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ อีเมลหรือรหัสผ่านไม่ถูกต้อง!'), backgroundColor: Colors.red),
        );
      } else {
        // 🚀 ล็อกอินผ่าน! -> แก้บั๊ก: สั่งปลดล็อกปุ่ม ล้างประวัติหน้าจอเก่า และวาร์ปไปหน้า Home ทันที
        setState(() => _isLoading = false);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false, // ลบหน้าต่างที่ซ้อนทับอยู่ทิ้งให้หมด
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.restaurant_menu, size: 80, color: Colors.deepOrange),
                const SizedBox(height: 20),
                const Text(
                  'Smart Restaurant',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                ),
                const SizedBox(height: 8),
                const Text('เข้าสู่ระบบเพื่อดำเนินการต่อ', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 40),

                // ช่อง Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'กรุณากรอก Email ครับ';
                    if (!value.contains('@') || !value.contains('.')) return 'รูปแบบ Email ไม่ถูกต้อง';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // ช่อง Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'กรุณากรอก Password ครับ';
                    if (value.length < 6) return 'Password ต้องมีอย่างน้อย 6 ตัวอักษร';
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // 🚩 ปุ่ม Login
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('เข้าสู่ระบบ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterScreen()),
                    );
                  },
                  child: const Text('ยังไม่มีบัญชีใช่ไหม? สมัครสมาชิกที่นี่', style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}