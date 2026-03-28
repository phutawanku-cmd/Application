import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import '../models/restaurant.dart'; 
import 'restaurant_detail_screen.dart'; 

class AdminReviewModerationScreen extends StatelessWidget {
  const AdminReviewModerationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseService dbService = DatabaseService();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // พื้นหลังเทาอ่อนพรีเมียม
      appBar: AppBar(
        title: const Text('จัดการรีวิว (Moderation)', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        backgroundColor: const Color(0xFFFF5722), // สีส้มสดตามธีม
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: dbService.getAllReviewsForAdmin(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('❌ เกิดข้อผิดพลาดในการโหลด'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFFFF5722)));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_user_rounded, size: 80, color: Colors.green.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text('ระบบสะอาด! ไม่มีรีวิวให้จัดการ', style: TextStyle(color: Colors.grey[500], fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          var docs = snapshot.data!.docs.toList();
          // จัดเรียงรีวิวใหม่ล่าสุดขึ้นก่อน
          docs.sort((a, b) {
            Timestamp? tA = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
            Timestamp? tB = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
            if (tA == null || tB == null) return 0;
            return tB.compareTo(tA); 
          });

          return ListView.builder(
            padding: const EdgeInsets.all(20.0),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var reviewDoc = docs[index];
              var data = reviewDoc.data() as Map<String, dynamic>;
              String restaurantId = reviewDoc.reference.parent.parent!.id;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 👤 รูปโปรไฟล์จำลอง สีส้ม
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.person, color: Colors.orange, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['userEmail'] ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                                    const SizedBox(width: 4),
                                    Text('${data['rating']} ดาว', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // 🗑️ ปุ่มลบรีวิวแบบมินิมอล
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                            onPressed: () => _confirmDelete(context, dbService, reviewDoc),
                          ),
                        ],
                      ),
                      const Divider(height: 24, thickness: 1),
                      Text(data['comment'] ?? 'ไม่มีข้อความรีวิว', style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.4)),
                      const SizedBox(height: 16),
                      
                      // 🏠 ลิงก์เชื่อมไปยังร้านอาหาร (FutureBuilder ชุดเดิมที่ระบบสมบูรณ์)
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('restaurants').doc(restaurantId).get(),
                        builder: (context, restSnapshot) {
                          if (restSnapshot.connectionState == ConnectionState.waiting) return const SizedBox();
                          if (!restSnapshot.hasData || !restSnapshot.data!.exists) return const Text('⚠️ ร้านถูกลบแล้ว', style: TextStyle(fontSize: 12, color: Colors.red));

                          var restData = restSnapshot.data!.data() as Map<String, dynamic>;
                          String restaurantName = restData['name'] ?? 'ไม่ทราบชื่อร้าน';

                          return InkWell(
                            onTap: () {
                              Restaurant target = Restaurant.fromFirestore(restSnapshot.data!.id, restData);
                              Navigator.push(context, MaterialPageRoute(builder: (context) => RestaurantDetailScreen(restaurant: target)));
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.storefront_rounded, size: 14, color: Colors.blueGrey),
                                  const SizedBox(width: 6),
                                  Text('ร้าน: $restaurantName', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                                  const Icon(Icons.chevron_right_rounded, size: 14, color: Colors.blueGrey),
                                ],
                              ),
                            ),
                          );
                        },
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

  // 🛡️ ป๊อปอัปยืนยันการลบสไตล์พรีเมียม
  void _confirmDelete(BuildContext context, DatabaseService dbService, QueryDocumentSnapshot doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('ลบรีวิวนี้?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('รีวิวนี้จะถูกลบออกจากระบบอย่างถาวรและไม่สามารถกู้คืนได้'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              await dbService.deleteReview(doc.reference);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('ลบทิ้งถาวร'),
          ),
        ],
      ),
    );
  }
}