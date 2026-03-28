import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'dart:math' as math; 
import '../services/database_service.dart';
import '../models/restaurant.dart';
import 'login_screen.dart';
import 'admin_dashboard_screen.dart';
import 'restaurant_detail_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _dbService = DatabaseService();
  String _searchQuery = ''; 
  final String _staticAdminPassword = '123'; 

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295;
    final double a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a));
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false, 
    );
  }

  void _showAdminLoginDialog() {
    final TextEditingController passwordController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), 
          title: const Text('เข้าสู่โหมดผู้ดูแลระบบ', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('กรุณากรอกรหัสผ่านเพื่อยืนยันตัวตน', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true, 
                decoration: InputDecoration(
                  labelText: 'รหัสผ่าน Admin',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.security, color: Colors.deepOrange),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange, 
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (passwordController.text == _staticAdminPassword) {
                  Navigator.pop(context); 
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
              child: const Text('ยืนยัน'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Restaurants', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 28),
            onPressed: () {}, 
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, size: 28),
            tooltip: 'สำหรับผู้ดูแลระบบ',
            onPressed: _showAdminLoginDialog, 
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 26, color: Colors.white70),
            tooltip: 'ออกจากระบบ',
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), spreadRadius: 0, blurRadius: 20, offset: const Offset(0, 4)),
                ],
              ),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: const InputDecoration(
                  hintText: 'ค้นหาร้านอาหาร หรือหมวดหมู่...',
                  hintStyle: TextStyle(color: Colors.black38, fontSize: 15),
                  prefixIcon: Icon(Icons.search, color: Colors.deepOrange, size: 28),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Restaurant>>(
              stream: _dbService.getRestaurants(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                List<Restaurant> allRestaurants = snapshot.data!;
                List<Restaurant> displayRestaurants = allRestaurants;
                
                if (_searchQuery.isNotEmpty) {
                  displayRestaurants = allRestaurants.where((r) {
                    return r.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                           r.category.toLowerCase().contains(_searchQuery.toLowerCase());
                  }).toList();
                }

                List<Restaurant> topRestaurants = List.from(allRestaurants)..sort((a, b) => b.rating.compareTo(a.rating));
                topRestaurants = topRestaurants.take(4).toList();
                bool isSearching = _searchQuery.isNotEmpty;

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isSearching) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text('🔥 ร้านเด็ดห้ามพลาด', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 240, 
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            itemCount: topRestaurants.length,
                            itemBuilder: (context, index) => _buildTopRestaurantCard(topRestaurants[index]),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text('🍴 ร้านอาหารทั้งหมด', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(height: 16),
                      
                      if (displayRestaurants.isEmpty)
                        _buildEmptyState()
                      else
                        ListView.builder(
                          shrinkWrap: true, 
                          physics: const NeverScrollableScrollPhysics(), 
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: displayRestaurants.length,
                          itemBuilder: (context, index) => _buildNormalRestaurantCard(displayRestaurants[index]),
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fastfood_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('ยังไม่มีเมนูอร่อยในตอนนี้ 😢', style: TextStyle(fontSize: 18, color: Colors.grey[500], fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTopRestaurantCard(Restaurant restaurant) {
    const double myLat = 13.0823;
    const double myLng = 100.9265;
    double distance = _calculateDistance(myLat, myLng, restaurant.lat, restaurant.lng);

    return Container(
      width: 170,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RestaurantDetailScreen(restaurant: restaurant))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    restaurant.imageUrl.isNotEmpty
                        ? Image.network(restaurant.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey)))
                        : Container(color: Colors.grey[200], child: const Icon(Icons.restaurant, color: Colors.grey)),
                    Positioned(
                      top: 10, right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text(restaurant.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, 
                  children: [
                    Text(restaurant.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(restaurant.category, style: TextStyle(color: Colors.deepOrange[400], fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.grey, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text('${distance.toStringAsFixed(1)} กม.', style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🎨 อัปเกรดการจัดเรียง ภายในกรอบให้สวยงามและเป็นระเบียบ (เพิ่มไอคอนดาว)
  Widget _buildNormalRestaurantCard(Restaurant restaurant) {
    const double myLat = 13.0823;
    const double myLng = 100.9265;
    double distance = _calculateDistance(myLat, myLng, restaurant.lat, restaurant.lng);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RestaurantDetailScreen(restaurant: restaurant))),
          child: Padding(
            padding: const EdgeInsets.all(14.0), // ขยายพื้นที่ขอบให้ดูโล่งขึ้น
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 85, height: 85, // ขยายรูปขึ้นนิดหน่อยให้สมดุลกับข้อมูลที่เพิ่มขึ้น
                    child: restaurant.imageUrl.isNotEmpty
                        ? Image.network(restaurant.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image)))
                        : Container(color: Colors.grey[200], child: const Icon(Icons.restaurant)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // แถวที่ 1: ชื่อร้าน
                      Text(restaurant.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      // แถวที่ 2: หมวดหมู่ • ระยะทาง
                      Row(
                        children: [
                          Text(restaurant.category, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(Icons.circle, size: 4, color: Colors.black26), // จุดไข่ปลาคั่นกลาง
                          ),
                          const Icon(Icons.location_on, color: Colors.grey, size: 12),
                          const SizedBox(width: 2),
                          Text('${distance.toStringAsFixed(1)} กม.', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8), 
                      // แถวที่ 3: คะแนน ⭐️ + จำนวนรีวิว 💬
                      StreamBuilder<QuerySnapshot>(
                        stream: _dbService.getReviews(restaurant.id), 
                        builder: (context, snapshot) {
                          int reviewCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                          return Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16), // ใส่ดาวตรงนี้!
                              const SizedBox(width: 4),
                              Text(restaurant.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                              const SizedBox(width: 12),
                              const Icon(Icons.chat_bubble_rounded, color: Colors.black26, size: 14),
                              const SizedBox(width: 4),
                              Text('$reviewCount รีวิว', style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          );
                        }
                      ),
                    ],
                  ),
                ),
                // แผงด้านขวาสุด: เปลี่ยนเป็นวงกลมลูกศรลอยตัวดูพรีเมียม
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.deepOrange),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}