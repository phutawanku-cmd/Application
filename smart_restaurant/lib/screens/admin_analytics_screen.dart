import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import '../models/restaurant.dart';

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseService dbService = DatabaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 สถิติระบบ (Analytics)'),
        backgroundColor: Colors.blue[800], // ใช้สีน้ำเงินสื่อถึงความน่าเชื่อถือและข้อมูล
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ภาพรวมระบบ (System Overview)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // 📈 ส่วนที่ 1: การ์ดสรุปตัวเลข (ดึงข้อมูลแบบ Real-time ด้วย StreamBuilder)
            Row(
              children: [
                Expanded(
                  child: StreamBuilder<List<Restaurant>>(
                    stream: dbService.getRestaurants(),
                    builder: (context, snapshot) {
                      int totalRes = snapshot.hasData ? snapshot.data!.length : 0;
                      return _buildStatCard('ร้านอาหาร', '$totalRes ร้าน', Icons.store, Colors.green);
                    }
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: dbService.getAllReviewsForAdmin(),
                    builder: (context, snapshot) {
                      int totalRev = snapshot.hasData ? snapshot.data!.docs.length : 0;
                      return _buildStatCard('รีวิวทั้งหมด', '$totalRev รายการ', Icons.comment, Colors.orange);
                    }
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            const Text('🏆 5 อันดับร้านค้ายอดฮิต (Top Rated)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // 🥇 ส่วนที่ 2: จัดอันดับร้านอาหาร (Sorting Algorithm)
            StreamBuilder<List<Restaurant>>(
              stream: dbService.getRestaurants(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Text('ยังไม่มีข้อมูลร้านอาหารในระบบ');

                List<Restaurant> restaurants = snapshot.data!;
                
                // ⚙️ อัลกอริทึมจัดเรียง: เรียงตามคะแนนดาวจาก "มากไปน้อย"
                restaurants.sort((a, b) => b.rating.compareTo(a.rating));
                
                // ✂️ ตัดเอามาแสดงแค่ 5 อันดับแรก (Top 5)
                List<Restaurant> top5 = restaurants.take(5).toList();

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: top5.length,
                  itemBuilder: (context, index) {
                    var res = top5[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getRankColor(index),
                          radius: 20,
                          child: Text('#${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                        ),
                        title: Text(res.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text('หมวดหมู่: ${res.category}'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: Colors.amber[100], borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(res.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)),
                              const SizedBox(width: 4),
                              const Icon(Icons.star, color: Colors.orange, size: 18),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                );
              }
            ),
          ],
        ),
      ),
    );
  }

  // 🎨 ฟังก์ชันช่วยสร้างการ์ดตัวเลขให้สวยงาม (Reusable Widget)
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          CircleAvatar(backgroundColor: color.withOpacity(0.2), radius: 24, child: Icon(icon, size: 28, color: color)),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  // 🎨 ฟังก์ชันเปลี่ยนสีเหรียญรางวัล (ทอง, เงิน, ทองแดง)
  Color _getRankColor(int index) {
    if (index == 0) return Colors.amber; // ที่ 1 สีทอง
    if (index == 1) return Colors.blueGrey[300]!; // ที่ 2 สีเงิน
    if (index == 2) return Colors.brown[400]!; // ที่ 3 สีทองแดง
    return Colors.blueGrey[800]!; // ที่เหลือสีเข้มปกติ
  }
}