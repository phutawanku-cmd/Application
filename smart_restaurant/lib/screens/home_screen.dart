import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
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
    _initFastLocation(); 
  }

  Future<void> _initFastLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position? lastPosition = await Geolocator.getLastKnownPosition();
    if (lastPosition != null && mounted) {
      setState(() => _currentPosition = lastPosition);
    }

    Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 5),
    ).then((position) {
      if (mounted) setState(() => _currentPosition = position);
    }).catchError((e) => print("GPS Error: $e"));
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

  // 🛡️ ฟังก์ชันแสดงป๊อปอัปยืนยันก่อนออกจากระบบ
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('ออกจากระบบ', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('คุณแน่ใจหรือไม่ว่าต้องการออกจากระบบ?', style: TextStyle(color: Colors.black87, fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent, 
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context); // ปิดป๊อปอัปก่อน
              _logout(); // แล้วค่อยเรียกคำสั่งล็อกเอาต์ของจริง
            },
            child: const Text('ยืนยัน', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAdminLoginDialog() {
    final TextEditingController passwordController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), 
          title: const Text('เข้าสู่โหมดผู้ดูแลระบบ', style: TextStyle(fontWeight: FontWeight.w900)),
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.deepOrange, width: 2)),
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () {
                if (passwordController.text == _staticAdminPassword) {
                  Navigator.pop(context); 
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminDashboardScreen()));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ รหัสผ่านไม่ถูกต้อง!'), backgroundColor: Colors.red));
                }
              },
              child: const Text('ยืนยัน', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8), 
      appBar: AppBar(
        title: const Text('HungryHeros', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF5722), Color.fromARGB(255, 253, 123, 84)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.admin_panel_settings, size: 26, color: Colors.white), tooltip: 'สำหรับผู้ดูแลระบบ', onPressed: _showAdminLoginDialog),
          IconButton(icon: const Icon(Icons.logout, size: 24, color: Colors.white), tooltip: 'ออกจากระบบ', onPressed: _confirmLogout),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF5722), Color.fromARGB(255, 253, 116, 74)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ยินดีต้อนรับ', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                const Text('วันนี้อยากทานอะไรดีครับ?', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 20),
                
                // 🔍 ช่องค้นหา
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), spreadRadius: 0, blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: const InputDecoration(
                      hintText: 'ค้นหาร้านอาหาร หรือหมวดหมู่...',
                      hintStyle: TextStyle(color: Colors.black38, fontSize: 16, fontWeight: FontWeight.w500),
                      prefixIcon: Icon(Icons.search, color: Color(0xFFFF5722), size: 26),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Restaurant>>(
              stream: _dbService.getRestaurants(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
                if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyState();

                List<Restaurant> allRestaurants = List.from(snapshot.data!);

                if (_currentPosition != null) {
                  for (var r in allRestaurants) {
                    r.distance = Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, r.lat, r.lng) / 1000;
                  }
                  allRestaurants.sort((a, b) => (a.distance ?? 999).compareTo(b.distance ?? 999));
                }

                List<Restaurant> searchResults = [];
                if (_searchQuery.isNotEmpty) {
                  searchResults = allRestaurants.where((r) => 
                    r.name.toLowerCase().contains(_searchQuery.toLowerCase()) || r.category.toLowerCase().contains(_searchQuery.toLowerCase())
                  ).toList();
                }

                List<Restaurant> topRestaurants = List.from(allRestaurants)..sort((a, b) => b.rating.compareTo(a.rating));
                topRestaurants = topRestaurants.take(4).toList();

                List<Restaurant> nearbyRestaurants = allRestaurants.where((r) => r.distance != null && r.distance! <= 10.0).toList();
                List<Restaurant> otherRestaurants = allRestaurants.where((r) => r.distance == null || r.distance! > 10.0).toList();

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_searchQuery.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
                          child: Text('🔍 ผลการค้นหา', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87)),
                        ),
                        if (searchResults.isEmpty)
                          _buildEmptyState()
                        else
                          ListView.builder(
                            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: searchResults.length, itemBuilder: (context, index) => _buildNormalRestaurantCard(searchResults[index]),
                          ),
                      ] 
                      else ...[
                        const Padding(
                          padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                          child: Text('🔥 ร้านเด็ดห้ามพลาด', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87)),
                        ),
                        SizedBox(
                          height: 250, 
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 14),
                            itemCount: topRestaurants.length, itemBuilder: (context, index) => _buildTopRestaurantCard(topRestaurants[index]),
                          ),
                        ),
                        const SizedBox(height: 16),

                        const Padding(
                          padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
                          child: Text('📍 ร้านใกล้ฉัน ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87)),
                        ),
                        if (nearbyRestaurants.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            child: Container(
                              width: double.infinity, padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(16)),
                              child: const Text('ยังไม่มีร้านอาหารในรัศมี 10 กม. 😢', style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: nearbyRestaurants.length, itemBuilder: (context, index) => _buildNormalRestaurantCard(nearbyRestaurants[index]),
                          ),

                        if (otherRestaurants.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                            child: Text('🍴 ร้านอาหารอื่นๆ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87)),
                          ),
                          ListView.builder(
                            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: otherRestaurants.length, itemBuilder: (context, index) => _buildNormalRestaurantCard(otherRestaurants[index]),
                          ),
                        ],
                      ],
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
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
            child: Icon(Icons.ramen_dining_outlined, size: 80, color: Colors.deepOrange[200]),
          ),
          const SizedBox(height: 24),
          const Text('ยังไม่มีเมนูอร่อยในตอนนี้ 😢', style: TextStyle(fontSize: 18, color: Colors.black54, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // 🌟 การ์ดร้านแนะนำ (แนวนอน) - สีคุมโทนพรีเมียม ขาว/ส้ม/ดำ
  Widget _buildTopRestaurantCard(Restaurant restaurant) {
    double distance = restaurant.distance ?? 0.0;
    return Container(
      width: 200, 
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 8))]),
      child: Material(
        color: Colors.transparent, borderRadius: BorderRadius.circular(24), clipBehavior: Clip.antiAlias,
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
                    Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.4), Colors.transparent, Colors.black.withOpacity(0.6)]))),
                    
                    // 🎨 ป้ายคะแนน: พื้นขาวโปร่งใส ตัวอักษรดำ เพื่อความคลีน
                    Positioned(
                      top: 12, right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)]),
                        child: Row(children: [const Icon(Icons.star_rounded, color: Colors.amber, size: 16), const SizedBox(width: 4), Text(restaurant.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.black87))]),
                      ),
                    ),
                    
                    // 🎨 ป้ายระยะทาง: พื้นขาวโปร่งใส ไอคอนส้ม ตัวอักษรดำ (ลบสีแดงออก)
                    Positioned(
                      bottom: 12, left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [const Icon(Icons.location_on_rounded, color: Colors.deepOrange, size: 14), const SizedBox(width: 4), Text('${distance.toStringAsFixed(1)} กม.', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.black87))]),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, 
                  children: [
                    Text(restaurant.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text(restaurant.category, style: TextStyle(color: Colors.deepOrange[600], fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // 🎨 การ์ดร้านอาหารปกติ (แนวตั้ง) - คุมโทนเทาและส้ม สบายตา
  Widget _buildNormalRestaurantCard(Restaurant restaurant) {
    double distance = restaurant.distance ?? 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6))]),
      child: Material(
        color: Colors.transparent, borderRadius: BorderRadius.circular(24), clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RestaurantDetailScreen(restaurant: restaurant))),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    width: 100, height: 100, 
                    child: restaurant.imageUrl.isNotEmpty
                        ? Image.network(restaurant.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image)))
                        : Container(color: Colors.deepOrange[50], child: Icon(Icons.restaurant, color: Colors.deepOrange[200], size: 40)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(restaurant.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: [
                          // 🎨 ป้ายหมวดหมู่: พื้นส้มอ่อน ตัวอักษรส้มเข้ม
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.deepOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text(restaurant.category, style: const TextStyle(color: Colors.deepOrange, fontSize: 12, fontWeight: FontWeight.w900)),
                          ),
                          // 🎨 ป้ายระยะทาง: พื้นเทาอ่อน ไอคอนส้ม ตัวอักษรดำ (แทนที่สีชมพู/แดง)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on_rounded, color: Colors.deepOrange, size: 14),
                                const SizedBox(width: 4),
                                Text('${distance.toStringAsFixed(1)} กม.', style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12), 
                      StreamBuilder<QuerySnapshot>(
                        stream: _dbService.getReviews(restaurant.id), 
                        builder: (context, snapshot) {
                          int reviewCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 18), const SizedBox(width: 4),
                                Text(restaurant.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.black87)),
                                const SizedBox(width: 12), Container(width: 1, height: 12, color: Colors.grey.shade300), const SizedBox(width: 12),
                                // 🎨 ไอคอนและข้อความรีวิว: เปลี่ยนเป็นสีเทากลางๆ เพื่อลดความขัดแย้งของสี (แทนที่สีฟ้า)
                                Icon(Icons.forum_rounded, color: Colors.grey.shade400, size: 16), const SizedBox(width: 4),
                                Text('$reviewCount ความเห็น', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w900)),
                              ],
                            ),
                          );
                        }
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}