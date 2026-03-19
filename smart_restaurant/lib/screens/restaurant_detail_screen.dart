import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import '../models/restaurant.dart';
import '../services/database_service.dart';
import 'all_reviews_screen.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final Restaurant restaurant;

  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  final DatabaseService _dbService = DatabaseService();
  final User? currentUser = FirebaseAuth.instance.currentUser; 

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295;
    final double a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a));
  }

  // 🛠️ ฟังก์ชันเปิดกล่องสำหรับเขียนรีวิว
  void _showReviewDialog() {
    final TextEditingController commentController = TextEditingController();
    double currentRating = 5.0; // คะแนนเริ่มต้น

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder( 
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('ให้คะแนนร้านนี้ 🌟'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('คะแนน:'),
                      Slider(
                        value: currentRating,
                        min: 1.0,
                        max: 5.0,
                        divisions: 4, // แบ่ง 5 ระดับ (1, 2, 3, 4, 5)
                        activeColor: Colors.amber,
                        label: currentRating.toString(),
                        onChanged: (value) {
                          setStateDialog(() => currentRating = value);
                        },
                      ),
                      Text('${currentRating.toInt()} ดาว', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'ความประทับใจของคุณ',
                      hintText: 'พิมพ์รีวิวที่นี่...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
                  onPressed: () async {
                    if (commentController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาพิมพ์ข้อความรีวิวก่อนครับ!')));
                      return;
                    }
           
                    if (currentUser != null) {
                      await _dbService.addReview(
                        widget.restaurant.id,
                        currentUser!.uid,
                        currentUser!.email ?? 'Unknown User',
                        currentRating,
                        commentController.text.trim(),
                      );
                    }

                    if (mounted) Navigator.pop(dialogContext);
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ส่งรีวิวเรียบร้อย ขอบคุณครับ!'), backgroundColor: Colors.green));
                    }
                  },
                  child: const Text('ส่งรีวิว'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const double myLat = 13.0823;
    const double myLng = 100.9265;
    double distance = _calculateDistance(myLat, myLng, widget.restaurant.lat, widget.restaurant.lng);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.restaurant.name),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: Colors.deepOrange[50],
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('หมวดหมู่: ${widget.restaurant.category}', style: const TextStyle(fontSize: 16, color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.red),
                      const SizedBox(width: 4),
                      Text('ห่างจากคุณ: ${distance.toStringAsFixed(2)} กม.', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('รายการเมนูอาหาร 🍽️', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            widget.restaurant.menus.isEmpty
                ? const Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Text('ยังไม่มีเมนูอาหาร'))
                : ListView.builder(
                    shrinkWrap: true, 
                    physics: const NeverScrollableScrollPhysics(), // 🚩 ปิดการไถจอของตัวมันเอง
                    itemCount: widget.restaurant.menus.length,
                    itemBuilder: (context, index) {
                      final menu = widget.restaurant.menus[index];
                      return ListTile(
                        leading: CircleAvatar(backgroundColor: Colors.grey[200], child: Text('${index + 1}')),
                        title: Text(menu['name'] ?? ''),
                        trailing: Text('${menu['price'] ?? 0} บาท', style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold)),
                      );
                    },
                  ),

            const Divider(thickness: 2, height: 40),

            // ส่วนแสดงรีวิวและเรตติ้ง (Real-time Stream) ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('รีวิวจากผู้ใช้งาน 🌟', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            
            // 📡 ท่อต่อตรงเข้า Database เพื่อดึงข้อมูล Sub-collection 'reviews'
            StreamBuilder<QuerySnapshot>(
              stream: _dbService.getReviews(widget.restaurant.id, limit: 3), 
              builder: (context, snapshot) {
                // สถานะ: เกิดข้อผิดพลาด
                if (snapshot.hasError) return const Center(child: Text('❌ เกิดข้อผิดพลาดในการโหลดรีวิว'));
                
                // สถานะ: กำลังโหลดข้อมูล
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                
                // สถานะ: ไม่มีรีวิวเลย
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('ยังไม่มีรีวิวสำหรับร้านนี้ เป็นคนแรกที่รีวิวเลยสิ!', style: TextStyle(color: Colors.grey)),
                  );
                }

                // สถานะ: มีข้อมูลรีวิว (สร้างเป็น Column เพื่อมัดรวม ListView กับปุ่ม "ดูรีวิวทั้งหมด" ไว้ด้วยกัน)
                return Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true, 
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var reviewDoc = snapshot.data!.docs[index];
                        var data = reviewDoc.data() as Map<String, dynamic>;
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          color: Colors.white,
                          elevation: 2,
                          child: ListTile(
                            leading: const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.person, color: Colors.white)),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(data['userEmail'] ?? 'Unknown', overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold))),
                                Row(
                                  children: [
                                    Text('${data['rating']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const Icon(Icons.star, color: Colors.amber, size: 20),
                                  ],
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(data['comment'] ?? '', style: const TextStyle(fontSize: 15, color: Colors.black87)),
                            ),
                          ),
                        );
                      },
                    ),

                    // 🚪 ปุ่มทะลุไปหน้า "รีวิวทั้งหมด" 
                    TextButton.icon(
                      onPressed: () {
                        // 🚀 นำทางไปหน้า AllReviewsScreen พร้อมส่ง ID และชื่อร้านตามไปด้วย
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AllReviewsScreen(
                              restaurantId: widget.restaurant.id,
                              restaurantName: widget.restaurant.name,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.forum, color: Colors.deepOrange),
                      label: const Text('ดูรีวิวทั้งหมด', style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 80), // เว้นที่ว่างด้านล่างกันปุ่มลอย (FAB) บังเนื้อหา
          ],
        ),
      ),
      // 🌟 ปุ่มลอยสำหรับกดเขียนรีวิว
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showReviewDialog,
        backgroundColor: Colors.amber,
        icon: const Icon(Icons.rate_review, color: Colors.black87),
        label: const Text('เขียนรีวิว', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
    );
  }
}