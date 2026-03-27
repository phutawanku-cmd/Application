import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import '../models/restaurant.dart'; // 🚩 1. นำเข้าแปลนข้อมูลร้านอาหาร
import 'restaurant_detail_screen.dart'; // 🚩 2. นำเข้าหน้าจอดูรายละเอียดร้าน

class AdminReviewModerationScreen extends StatelessWidget {
  const AdminReviewModerationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseService dbService = DatabaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการรีวิวทั้งหมด (Moderation)'),
        backgroundColor: Colors.red[800], 
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: dbService.getAllReviewsForAdmin(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('❌ เกิดข้อผิดพลาดในการโหลด'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.red));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('🎉 ระบบสะอาด! ไม่มีรีวิวให้จัดการ'));

          var docs = snapshot.data!.docs.toList();
          docs.sort((a, b) {
            Timestamp? tA = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
            Timestamp? tB = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
            if (tA == null || tB == null) return 0;
            return tB.compareTo(tA); 
          });

          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var reviewDoc = docs[index];
              var data = reviewDoc.data() as Map<String, dynamic>;
              
              // 💡 ทริกวิศวกร: แกะรอยหา ID ของร้านอาหาร จากเส้นทาง (Path) ของเอกสารรีวิว
              String restaurantId = reviewDoc.reference.parent.parent!.id;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16.0),
                  leading: const CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(Icons.comment, color: Colors.white)),
                  title: Text(data['userEmail'] ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('ให้คะแนน: ${data['rating']} ดาว 🌟', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(data['comment'] ?? 'ไม่มีข้อความ', style: const TextStyle(fontSize: 15, color: Colors.black87)),
                      const SizedBox(height: 12),
                      
                      // 🚀 ฟีเจอร์ใหม่: ท่อดึงข้อมูลชื่อร้านอาหารมาแปะพร้อมปุ่มกด
                      FutureBuilder<DocumentSnapshot>(
                        // วิ่งไปขอข้อมูลร้านอาหารที่มี ID ตรงกับที่แกะรอยมาได้
                        future: FirebaseFirestore.instance.collection('restaurants').doc(restaurantId).get(),
                        builder: (context, restSnapshot) {
                          // ถ้ากำลังดึงข้อมูล ให้โชว์ข้อความเทาๆ ไปก่อน
                          if (restSnapshot.connectionState == ConnectionState.waiting) {
                            return const Text('กำลังโหลดข้อมูลร้าน...', style: TextStyle(fontSize: 13, color: Colors.grey));
                          }
                          // ถ้าร้านถูกลบไปแล้ว แต่รีวิวยังค้างอยู่
                          if (!restSnapshot.hasData || !restSnapshot.data!.exists) {
                            return const Text('⚠️ รีวิวนี้มาจากร้านที่ถูกลบไปแล้ว', style: TextStyle(fontSize: 13, color: Colors.red));
                          }

                          // ดึงชื่อร้านออกมา
                          var restData = restSnapshot.data!.data() as Map<String, dynamic>;
                          String restaurantName = restData['name'] ?? 'ไม่ทราบชื่อร้าน';

                          // 🖱️ สร้างปุ่มข้อความเล็กๆ (InkWell) สำหรับกดเข้าร้าน
                          return InkWell(
                            borderRadius: BorderRadius.circular(4),
                            onTap: () {
                              // 🧱 ประกอบร่าง Object ร้านอาหาร
                              Restaurant targetRestaurant = Restaurant.fromFirestore(restSnapshot.data!.id, restData);
                              
                              // 🚀 เด้งทะลุไปหน้า Detail พร้อมส่งข้อมูลร้านไปให้ด้วย
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RestaurantDetailScreen(restaurant: targetRestaurant),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.storefront, size: 16, color: Colors.blue),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'รีวิวจากร้าน: $restaurantName',
                                      style: const TextStyle(
                                        fontSize: 13, 
                                        color: Colors.blue, 
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline, // ขีดเส้นใต้ให้รู้ว่ากดได้
                                      ),
                                      overflow: TextOverflow.ellipsis, // ถ้ายาวไปให้ใส่ ...
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.blue),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  // 🗑️ ปุ่มถังขยะสำหรับลบรีวิว (คงโค้ดเดิมที่ป้องกันบั๊กไว้แล้ว)
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_forever, color: Colors.red, size: 32),
                    tooltip: 'ลบรีวิวนี้',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) {
                          bool isDeleting = false;
                          return StatefulBuilder(
                            builder: (contextDialog, setStateDialog) {
                              return AlertDialog(
                                title: const Text('ยืนยันการลบ? ⚠️', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                content: const Text('คุณต้องการลบรีวิวนี้ออกจากระบบอย่างถาวรใช่หรือไม่?'),
                                actions: [
                                  TextButton(
                                    onPressed: isDeleting ? null : () => Navigator.pop(ctx), 
                                    child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey))
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                    onPressed: isDeleting ? null : () async {
                                      setStateDialog(() => isDeleting = true);
                                      try {
                                        await dbService.deleteReview(reviewDoc.reference);
                                        if (ctx.mounted) Navigator.pop(ctx); 
                                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🗑️ ลบรีวิวเรียบร้อย'), backgroundColor: Colors.red));
                                      } catch (e) {
                                        setStateDialog(() => isDeleting = false);
                                        if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('❌ ลบไม่ได้: $e'), backgroundColor: Colors.orange));
                                      }
                                    },
                                    child: isDeleting ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('ลบทิ้งถาวร'),
                                  ),
                                ],
                              );
                            }
                          );
                        },
                      );
                    },
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