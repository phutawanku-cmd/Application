import 'package:flutter/material.dart';
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

  // 🛠️ ประตูดัก Admin (Mock Login)
  void _showAdminLoginDialog() {
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
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
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey[900], foregroundColor: Colors.white),
              onPressed: () {
                if (passwordController.text == 'admin123') {
                  Navigator.pop(context); // ปิดหน้าต่าง Login
                  
                  // 🚩 รหัสถูก -> เปิดหน้า Admin Dashboard ทันที!
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('❌ รหัสผ่านไม่ถูกต้อง!'), backgroundColor: Colors.red),
                  );
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
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, size: 28), // เปลี่ยนไอคอนให้ดูเป็น Admin
            tooltip: 'Admin Mode',
            onPressed: _showAdminLoginDialog,
          ),
          const SizedBox(width: 8),
        ],
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