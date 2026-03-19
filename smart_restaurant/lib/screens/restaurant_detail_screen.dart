import 'package:flutter/material.dart';
import 'dart:math' as math; // 🚩 ใช้ทำสมการคณิตศาสตร์
import '../models/restaurant.dart';

class RestaurantDetailScreen extends StatelessWidget {
  final Restaurant restaurant;

  const RestaurantDetailScreen({super.key, required this.restaurant});

  // 🛠️ ฟังก์ชันคำนวณระยะทาง (Haversine Formula) - ไม่ต้องใช้ Plugin!
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295; // ค่าแปลงองศาเป็นเรเดียน (Math.PI / 180)
    final double a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a)); // 12742 = 2 * R (รัศมีโลก 6371 km)
  }

  @override
  Widget build(BuildContext context) {
    // 🚩 สมมติพิกัดปัจจุบันของเรา (คุณสามารถเปลี่ยนเลขนี้เป็นพิกัดมหาวิทยาลัยหรือบ้านได้ครับ)
    const double myLat = 13.0823;
    const double myLng = 100.9265;

    // คำนวณระยะห่าง
    double distance = _calculateDistance(myLat, myLng, restaurant.lat, restaurant.lng);

    return Scaffold(
      appBar: AppBar(
        title: Text(restaurant.name),
        backgroundColor: Colors.deepOrange,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🚩 แถบแสดงข้อมูลร้านและระยะทาง
          Container(
            width: double.infinity,
            color: Colors.deepOrange[50],
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('หมวดหมู่: ${restaurant.category}', style: const TextStyle(fontSize: 16, color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(
                      'ห่างจากคุณ: ${distance.toStringAsFixed(2)} กิโลเมตร', // ปัดทศนิยม 2 ตำแหน่ง
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('รายการเมนูอาหาร 🍽️', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          
          Expanded(
            child: restaurant.menus.isEmpty
                ? const Center(child: Text('ยังไม่มีเมนูอาหารในร้านนี้'))
                : ListView.builder(
                    itemCount: restaurant.menus.length,
                    itemBuilder: (context, index) {
                      final menu = restaurant.menus[index];
                      return ListTile(
                        leading: CircleAvatar(backgroundColor: Colors.grey[200], child: Text('${index + 1}')),
                        title: Text(menu['name'] ?? ''),
                        trailing: Text('${menu['price'] ?? 0} บาท', style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}