import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/database_service.dart';
import '../models/restaurant.dart';
import 'restaurant_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _dbService = DatabaseService();
  String _searchText = "";
  bool _isSortingByDistance = false; 

  // 📍 พิกัดจำลองของผู้ใช้ (User Location)
  final double userLat = 13.1234; 
  final double userLng = 100.9123;

  double _calculateDistance(double resLat, double resLng) {
    var p = 0.017453292519943295;
    var a = 0.5 - math.cos((resLat - userLat) * p) / 2 +
        math.cos(userLat * p) * math.cos(resLat * p) *
            (1 - math.cos((resLng - userLng) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          // --- AppBar สีส้ม HungryHeros ---
          SliverAppBar(
            expandedHeight: 140,
            floating: true,
            pinned: true,
            backgroundColor: const Color(0xFFFF5722),
            title: const Text('HungryHeros 🍽️', 
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            actions: [
              // ปุ่ม Sort ระยะทาง (คลิกเพื่อสลับการเรียง)
              IconButton(
                icon: Icon(_isSortingByDistance ? Icons.near_me : Icons.near_me_outlined, color: Colors.white),
                onPressed: () => setState(() => _isSortingByDistance = !_isSortingByDistance),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search your favorite food...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFFFF5722)),
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                  ),
                  onChanged: (val) => setState(() => _searchText = val),
                ),
              ),
            ),
          ),

          // --- รายการร้านอาหาร (UI เหมือน Figma) ---
          StreamBuilder<List<Restaurant>>(
            stream: _dbService.getRestaurants(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              if (!snapshot.hasData) return const SliverFillRemaining(child: Center(child: Text("No data")));

              List<Restaurant> filtered = snapshot.data!.where((res) {
                return res.name.toLowerCase().contains(_searchText.toLowerCase());
              }).toList();

              // 🚩 ระบบ Sort ตามระยะทาง
              if (_isSortingByDistance) {
                filtered.sort((a, b) => _calculateDistance(a.lat, a.lng).compareTo(_calculateDistance(b.lat, b.lng)));
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final res = filtered[index];
                      final dist = _calculateDistance(res.lat, res.lng);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))],
                        ),
                        child: InkWell(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RestaurantDetailScreen(restaurant: res))),
                          borderRadius: BorderRadius.circular(25),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 🖼️ พื้นที่ภาพ (Full Width & Height 200px)
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                                    child: Image.network(
                                      res.imageUrl,
                                      height: 200, 
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(height: 200, color: Colors.grey[200], child: const Icon(Icons.restaurant, size: 50)),
                                    ),
                                  ),
                                  Positioned(
                                    top: 12, right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                                      child: Row(children: [const Icon(Icons.star, color: Colors.orange, size: 16), Text(' ${res.rating}', style: const TextStyle(fontWeight: FontWeight.bold))]),
                                    ),
                                  ),
                                ],
                              ),
                              // 📝 ข้อมูลร้าน
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(res.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(res.category, style: const TextStyle(color: Colors.grey)),
                                    const Divider(height: 24),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 16, color: Color(0xFFFF5722)),
                                        // 🚩 ตัวเลขระยะทางจะเปลี่ยนตามที่แก้ใน Firebase
                                        Text(' ${dist.toStringAsFixed(1)} km', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        const Spacer(),
                                        const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                        Text(' ${res.openingHours}', style: const TextStyle(color: Colors.grey)),
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
                    childCount: filtered.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}