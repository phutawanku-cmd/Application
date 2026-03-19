import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../models/restaurant.dart';
import 'restaurant_detail_screen.dart';
import 'admin_dashboard_screen.dart'; // 🚩 นำเข้าหน้า Admin Dashboard

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _dbService = DatabaseService();
  String _searchText = "";
  late Stream<List<Restaurant>> _restaurantStream;

  @override
  void initState() {
    super.initState();
    _restaurantStream = _dbService.getRestaurants();
  }

   void _showAdminLoginDialog() {
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context, 
      builder: (dialogContext) { 
        return AlertDialog(
          title: const Text('🔐 Admin Mode'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'กรอกรหัสผ่าน (admin123)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext), // ปิดกล่องเฉพาะเมื่อกดยกเลิก
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey[900], foregroundColor: Colors.white),
              onPressed: () {
                String enteredPassword = passwordController.text.trim(); // .trim() ช่วยตัดช่องว่างซ้ายขวาทิ้งให้

                // 🚦 เช็คเงื่อนไขที่ 1: ปล่อยช่องว่าง
                if (enteredPassword.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('⚠️ กรุณากรอกรหัสผ่านครับ!'), backgroundColor: Colors.orange),
                  );
                  // ❌ ไม่เรียก Navigator.pop -> กล่องจะไม่ปิด
                } 
                // 🚦 เช็คเงื่อนไขที่ 2: รหัสถูกต้อง
                else if (enteredPassword == 'admin123') {
                  // 🧹 สั่งปิดกล่อง Dialog ทันที
                  Navigator.pop(dialogContext);
                  
                  // 🚀 เปิดหน้า Admin Dashboard
                  if (mounted) {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                    );
                  }
                } 
                // 🚦 เช็คเงื่อนไขที่ 3: รหัสผิดพลาด
                else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('❌ รหัสผ่านไม่ถูกต้อง!'), backgroundColor: Colors.red),
                  );
                  // 💡 ทริกวิศวกร: ล้างช่องข้อความให้ผู้ใช้กรอกใหม่ได้ง่ายๆ โดยไม่ต้องกดลบเอง
                  passwordController.clear();
                  // ❌ ไม่เรียก Navigator.pop -> กล่องจะไม่ปิด
                }
              },
              child: const Text('เข้าสู่ระบบ'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Restaurant 🍽️'),
        backgroundColor: Colors.deepOrange,
        actions: [
          // 🚪 1. ปุ่ม Logout (วางด้านซ้าย)
          IconButton(
            icon: const Icon(Icons.logout, size: 28),
            tooltip: 'ออกจากระบบ',
            onPressed: () async {
              // ออกจากระบบ (ยามใน main.dart จะเด้งเรากลับหน้า Login ทันที)
              await FirebaseAuth.instance.signOut();
            },
          ),
          const SizedBox(width: 8),

          // ⚙️ 2. ปุ่ม Admin Mode (วางด้านขวา)
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, size: 28), 
            tooltip: 'Admin Mode',
            onPressed: _showAdminLoginDialog,
          ),
          const SizedBox(width: 8),
        ],
        // ... โค้ดส่วน bottom (ช่องค้นหา) ของเดิม ...
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'ค้นหาร้าน หรือ ชื่อเมนูอาหาร...',
                fillColor: Colors.white,
                filled: true,
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (val) {
                setState(() => _searchText = val);
              },
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Restaurant>>(
        stream: _restaurantStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("ไม่มีข้อมูล"));

          List<Restaurant> allRestaurants = snapshot.data!;
          
          List<Restaurant> filteredRestaurants = allRestaurants.where((res) {
            final searchWord = _searchText.toLowerCase().trim();
            if (searchWord.isEmpty) return true;

            bool matchNameOrCategory = res.name.toLowerCase().contains(searchWord) || 
                                       res.category.toLowerCase().contains(searchWord);

            bool matchMenu = res.menus.any((menu) {
              final menuName = (menu['name'] ?? '').toString().toLowerCase();
              return menuName.contains(searchWord);
            });

            return matchNameOrCategory || matchMenu;
          }).toList();

          if (filteredRestaurants.isEmpty) {
            return Center(
              child: Text(
                'ไม่พบร้านที่ขาย "$_searchText"',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: filteredRestaurants.length,
            itemBuilder: (context, index) {
              Restaurant res = filteredRestaurants[index];
              return ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RestaurantDetailScreen(restaurant: res),
                    ),
                  );
                },
                leading: CircleAvatar(
                  backgroundColor: Colors.deepOrange[100], 
                  foregroundColor: Colors.deepOrange, 
                  child: const Icon(Icons.storefront)
                ),
                title: Text(res.name),
                subtitle: Text(res.category),
                // 🛑 ลบ trailing: Row(...) ที่มีปุ่มแก้ไขและถังขยะออกไปแล้วครับ!
                // ตอนนี้หน้า Home จะดูสะอาดตา และปลอดภัย 100%
              );
            },
          );
        },
      ),
    );
  }
}