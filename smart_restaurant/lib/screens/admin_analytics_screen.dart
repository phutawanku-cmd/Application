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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Executive Dashboard', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF5722), Color(0xFFFF8A65)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🏷️ ส่วนหัวต้อนรับแบบหรูหรา
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF5722), Color(0xFFFF8A65)],
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
                  const Text('รายงานประสิทธิภาพระบบ', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  const Text('ยินดีต้อนรับกลับ ', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                ],
              ),
            ),

            // 📈 ส่วนที่ 1: Metric Cards ลอยซ้อนทับ (Overlapping)
            Transform.translate(
              offset: const Offset(0, -25),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: StreamBuilder<List<Restaurant>>(
                        stream: dbService.getRestaurants(),
                        builder: (context, snapshot) {
                          int totalRes = snapshot.hasData ? snapshot.data!.length : 0;
                          return _buildFancyMetricCard('Total Shops', '$totalRes', Icons.storefront_rounded, Colors.blue);
                        }
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: dbService.getAllReviewsForAdmin(),
                        builder: (context, snapshot) {
                          int totalRev = snapshot.hasData ? snapshot.data!.docs.length : 0;
                          return _buildFancyMetricCard('All Reviews', '$totalRev', Icons.auto_awesome_rounded, Colors.orange);
                        }
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 🥇 ส่วนที่ 2: Ranking Leaderboard
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                children: [
                  const Icon(Icons.leaderboard_rounded, color: Colors.deepOrange),
                  const SizedBox(width: 8),
                  const Text('Top Performing Shops', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87)),
                ],
              ),
            ),

            StreamBuilder<List<Restaurant>>(
              stream: dbService.getRestaurants(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyState();

                List<Restaurant> restaurants = snapshot.data!;
                restaurants.sort((a, b) => b.rating.compareTo(a.rating));
                List<Restaurant> topList = restaurants.take(5).toList();

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: topList.length,
                  itemBuilder: (context, index) {
                    var res = topList[index];
                    return _buildRankingItem(res, index);
                  }
                );
              }
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // 🎨 วิดเจ็ตการ์ดตัวเลขแบบใหม่ (Fancy Metric Card)
  Widget _buildFancyMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black87)),
          Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // 🎨 วิดเจ็ตแสดงอันดับแบบมี Progress Bar (Ranking Item)
  Widget _buildRankingItem(Restaurant res, int index) {
    double progressValue = res.rating / 5.0; // คำนวณความยาวแถบคะแนน
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // อันดับเลข
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: index == 0 ? Colors.amber : (index == 1 ? Colors.grey[400] : (index == 2 ? Colors.brown[300] : Colors.grey[100])),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text('${index + 1}', style: TextStyle(color: index < 3 ? Colors.white : Colors.black54, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(width: 12),
              // ข้อมูลร้าน
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(res.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    Text(res.category, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  ],
                ),
              ),
              // คะแนน
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Text(res.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.orange)),
                      const Icon(Icons.star_rounded, color: Colors.orange, size: 20),
                    ],
                  ),
                  const Text('avg rating', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 📊 แถบคะแนน Progress Bar (เพิ่มความน่าสนใจทางสายตา)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progressValue,
              backgroundColor: Colors.grey[100],
              valueColor: AlwaysStoppedAnimation<Color>(index == 0 ? Colors.amber : Colors.orange),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(Icons.query_stats_rounded, size: 80, color: Colors.grey[200]),
            const SizedBox(height: 16),
            const Text('No data found yet.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}