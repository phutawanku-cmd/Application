import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import '../services/database_service.dart';
import '../models/restaurant.dart';
import 'restaurant_detail_screen.dart';
import 'admin_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _dbService = DatabaseService();
  String _searchText = "";
  bool _isSortingByDistance = false;
  late Stream<List<Restaurant>> _restaurantStream;

  // 📍 พิกัดจำลองของผู้ใช้ (สามารถเปลี่ยนเป็นพิกัดจริงได้ในอนาคต)
  final double userLat = 13.7563;
  final double userLng = 100.5018;

  @override
  void initState() {
    super.initState();
    _restaurantStream = _dbService.getRestaurants();
  }

  // 📏 ฟังก์ชันคำนวณระยะทาง (Haversine Formula)
  double _calculateDistance(double resLat, double resLng) {
    var p = 0.017453292519943295;
    var a = 0.5 - math.cos((resLat - userLat) * p) / 2 +
        math.cos(userLat * p) * math.cos(resLat * p) *
            (1 - math.cos((resLng - userLng) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a));
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
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
              onPressed: () {
                if (passwordController.text.trim() == 'admin123') {
                  Navigator.pop(dialogContext);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminDashboardScreen()));
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('HungryHeros 🍽️', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepOrange,
        actions: [
          IconButton(
            icon: Icon(_isSortingByDistance ? Icons.near_me : Icons.near_me_outlined),
            onPressed: () => setState(() => _isSortingByDistance = !_isSortingByDistance),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async => await FirebaseAuth.instance.signOut(),
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: _showAdminLoginDialog,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ค้นหาร้าน หรือ เมนูอาหาร...',
                prefixIcon: const Icon(Icons.search, color: Colors.deepOrange),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => _searchText = val),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Restaurant>>(
        stream: _restaurantStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("ไม่พบข้อมูลร้านอาหาร"));

          List<Restaurant> restaurants = snapshot.data!;

          // 🔍 ค้นหา (Search Logic)
          List<Restaurant> filtered = restaurants.where((res) {
            final query = _searchText.toLowerCase();
            return res.name.toLowerCase().contains(query) || res.category.toLowerCase().contains(query);
          }).toList();

          // 📍 เรียงลำดับ (Sort Logic)
          if (_isSortingByDistance) {
            filtered.sort((a, b) => _calculateDistance(a.lat, a.lng).compareTo(_calculateDistance(b.lat, b.lng)));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final res = filtered[index];
              final dist = _calculateDistance(res.lat, res.lng);

              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RestaurantDetailScreen(restaurant: res))),
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: Image.network(
                          res.imageUrl,
                          height: 160, width: double.infinity, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(height: 160, color: Colors.grey[200], child: const Icon(Icons.restaurant, size: 50)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(res.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.orange, size: 18),
                                    Text(' ${res.rating}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text("${res.category} • ${res.priceRange}", style: TextStyle(color: Colors.grey[600])),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 14, color: Colors.deepOrange),
                                Text(" ${dist.toStringAsFixed(1)} กม.", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                const Spacer(),
                                Text(res.openingHours, style: const TextStyle(fontSize: 12, color: Colors.green)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}