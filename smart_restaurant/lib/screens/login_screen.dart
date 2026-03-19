import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../services/auth_service.dart'; // 🚩 1. นำเข้าแผนก รปภ. ที่เราเพิ่งสร้าง
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // 🚩 2. เรียกใช้งาน AuthService
  final AuthService _authService = AuthService();
  
  // 🚩 3. ตัวแปรสำหรับควบคุมสถานะ "กำลังโหลด" (ล็อกปุ่ม)
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 🛠️ ฟังก์ชันสำหรับล็อกอิน (แยกออกมาเพื่อให้โค้ดดูสะอาด)
  // 🛠️ ฟังก์ชันสำหรับล็อกอิน (ฉบับอัปเกรด แก้บั๊ก setState)
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();

      // 📡 1. ส่งข้อมูลไปให้ Firebase ตรวจสอบ
      var user = await _authService.signInWithEmail(email, password);

      // 🛡️ 2. โล่ป้องกัน! เช็คว่า "หน้า Login นี้ยังเปิดอยู่ไหม?"
      // ถ้าหน้าโดนทำลายไปแล้ว (เพราะ main.dart เปลี่ยนหน้าให้แล้ว) ให้หยุดการทำงานฟังก์ชันนี้ทันที
      if (!mounted) return;

      // 3. ถ้าล็อกอินล้มเหลว (user == null) ค่อยปลดล็อกปุ่มและโชว์ Error
      if (user == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ อีเมลหรือรหัสผ่านไม่ถูกต้อง!'), backgroundColor: Colors.red),
        );
      }
      // 💡 ทริก: ถ้า user ไม่เป็น null เราไม่ต้องทำอะไรเลย! ไม่ต้อง pushReplacement 
      // เพราะ StreamBuilder ใน main.dart จะดึงเราทะลุไปหน้า Home ให้อัตโนมัติครับ
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

                // 🚩 4. ปุ่ม Login ที่อัปเกรดแล้ว
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    // ถ้า _isLoading เป็น true ให้ตั้งค่าเป็น null (ปุ่มจะกดไม่ได้และเป็นสีเทา)
                    onPressed: _isLoading ? null : _login,
                    // ถ้ากำลังโหลด ให้โชว์วงกลมหมุนๆ ถ้าไม่โหลด ให้โชว์คำว่าเข้าสู่ระบบ
                    child: _isLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('เข้าสู่ระบบ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),

                TextButton(
                  onPressed: () {
                    // 🚀 นำทางไปหน้า RegisterScreen
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