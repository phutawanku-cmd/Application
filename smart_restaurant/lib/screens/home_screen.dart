import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
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
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // ฟังก์ชันขออนุญาตและดึงพิกัดผู้ใช้
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;
    Position position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentPosition = position;
      });
    }
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
      builder: (context) => AlertDialog(
        title: const Text('เข้าสู่โหมดผู้ดูแลระบบ', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'รหัสผ่าน Admin', prefixIcon: Icon(Icons.security)),
        ),

        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
            onPressed: () {
              if (passwordController.text == _staticAdminPassword) {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminDashboardScreen()));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ รหัสผ่านไม่ถูกต้อง!'), backgroundColor: Colors.red));
              }
            },
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('🍽️ Smart Restaurant', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.admin_panel_settings), onPressed: _showAdminLoginDialog),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),

      body: Column(
        children: [
          // ช่องค้นหา
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 8)],
              ),

              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: const InputDecoration(
                  hintText: 'ค้นหาร้านอาหาร หรือหมวดหมู่...',
                  prefixIcon: Icon(Icons.search, color: Colors.deepOrange),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Restaurant>>(
              stream: _dbService.getRestaurants(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('ยังไม่มีร้านอาหารในระบบครับ 😅'));
                }

                // --- เริ่มจัดการ Logic การเรียงลำดับ ---
                List<Restaurant> allRestaurants = List.from(snapshot.data!);

                // 1. คำนวณระยะทาง
                if (_currentPosition != null) {
                  for (var r in allRestaurants) {
                    r.distance = Geolocator.distanceBetween(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                      r.lat,
                      r.lng,
                    ) / 1000;
                  }

                  // 2. เรียงลำดับจากน้อยไปมาก (ใกล้ไปไกล)
                  allRestaurants.sort((a, b) {
                    if (a.distance == null) return 1;
                    if (b.distance == null) return -1;
                    return a.distance!.compareTo(b.distance!);
                  });
                }

                // 3. กรองตามคำค้นหา
                List<Restaurant> displayRestaurants = _searchQuery.isEmpty 
                    ? allRestaurants 
                    : allRestaurants.where((r) => 
                        r.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        r.category.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

                // 4. ร้านแนะนำ (Sort ตาม Rating)
                List<Restaurant> topRestaurants = List.from(snapshot.data!)
                  ..sort((a, b) => b.rating.compareTo(a.rating));
                topRestaurants = topRestaurants.take(4).toList();

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_searchQuery.isEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 8, 16, 10),
                          child: Text('🔥 ร้านอาหารแนะนำยอดฮิต', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ),

                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: topRestaurants.length,
                            itemBuilder: (context, index) => _buildTopCard(topRestaurants[index]),
                          ),
                        ),
                        const Divider(height: 40, indent: 16, endIndent: 16),
                      ],

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _searchQuery.isNotEmpty ? '🔍 ผลการค้นหา' : '📍 ร้านที่ใกล้คุณที่สุด',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: displayRestaurants.length,
                        itemBuilder: (context, index) => _buildNormalCard(displayRestaurants[index]),
                      ),
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

  Widget _buildTopCard(Restaurant restaurant) {
    return Container(
      width: 150,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RestaurantDetailScreen(restaurant: restaurant))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Expanded(
                child: restaurant.imageUrl.isNotEmpty
                    ? Image.network(restaurant.imageUrl, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image))
                    : Container(color: Colors.grey[300], child: const Icon(Icons.restaurant, size: 40)),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(restaurant.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        Text(restaurant.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12)),
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

  Widget _buildNormalCard(Restaurant restaurant) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: restaurant.imageUrl.isNotEmpty
              ? Image.network(restaurant.imageUrl, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image))
              : Container(width: 60, height: 60, color: Colors.grey[200], child: const Icon(Icons.restaurant)),
        ),

        title: Text(restaurant.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(restaurant.category, style: TextStyle(color: Colors.deepOrange[300])),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red, size: 14),
                Text(
                  restaurant.distance != null ? ' ${restaurant.distance!.toStringAsFixed(2)} กม.' : ' กำลังคำนวณ...',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RestaurantDetailScreen(restaurant: restaurant))),
      ),
    );
  }
}
 