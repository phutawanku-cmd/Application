import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';

class AllReviewsScreen extends StatelessWidget {
  final String restaurantId;
  final String restaurantName;

  // 🧱 Constructor รับค่า ID และชื่อร้าน เพื่อใช้ดึงข้อมูลให้ถูกตู้เอกสาร
  const AllReviewsScreen({super.key, required this.restaurantId, required this.restaurantName});

  @override
  Widget build(BuildContext context) {
    final DatabaseService dbService = DatabaseService();

    return Scaffold(
      backgroundColor: Colors.grey[100], // พื้นหลังสีเทาอ่อนให้การ์ดรีวิวดูโดดเด่น
      appBar: AppBar(
        title: Text('รีวิวทั้งหมด: $restaurantName', style: const TextStyle(fontSize: 18)),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      // 📡 ท่อดึงข้อมูล (รอบนี้ไม่ใส่ limit เพื่อดึงมาทั้งหมด)
      body: StreamBuilder<QuerySnapshot>(
        stream: dbService.getReviews(restaurantId), // เรียกใช้ฟังก์ชันเดิม แต่ไม่ต้องส่ง limit เข้าไป
        builder: (context, snapshot) {
          // 🚦 จัดการสถานะต่างๆ (Error, Loading, Empty)
          if (snapshot.hasError) return const Center(child: Text('❌ เกิดข้อผิดพลาดในการโหลดข้อมูล'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('ยังไม่มีรีวิวครับ'));

          // 📝 แสดงผลรีวิวทั้งหมด
          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              
              // 🎨 การ์ด UI (Reusability - ใช้หน้าตาเหมือนหน้า Detail เพื่อให้ผู้ใช้คุ้นเคย)
              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: Colors.amber, 
                                radius: 16,
                                child: Icon(Icons.person, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                data['userEmail']?.toString().split('@')[0] ?? 'Unknown', // ทริก: โชว์แค่ชื่อหน้า @ ปิดบังอีเมลเต็มเพื่อ Privacy
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Text('${data['rating']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                                const SizedBox(width: 4),
                                const Icon(Icons.star, color: Colors.orange, size: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, thickness: 1),
                      Text(
                        data['comment'] ?? '', 
                        style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.4),
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