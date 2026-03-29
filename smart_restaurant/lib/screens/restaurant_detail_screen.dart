import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // 🚩 [ลบฟังก์ชัน _calculateDistance ทิ้ง] เพราะเราจะใช้ค่าที่คำนวณมาจากหน้าแรกแล้ว

  void _showReviewDialog() {
    final TextEditingController commentController = TextEditingController();
    double currentRating = 5.0;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder( 
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text('ให้คะแนนร้านนี้ 🌟', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('คะแนน:'),
                      Slider(
                        value: currentRating,
                        min: 1.0, max: 5.0,
                        divisions: 4,
                        activeColor: Colors.amber,
                        label: currentRating.toInt().toString(),
                        onChanged: (value) => setStateDialog(() => currentRating = value),
                      ),
                      Text('${currentRating.toInt()} ดาว', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'ความประทับใจของคุณ',
                      hintText: 'พิมพ์รีวิวที่นี่...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE64A19), foregroundColor: Colors.white),
                  onPressed: () async {
                    if (commentController.text.trim().isEmpty) return;
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
    // 🚩 [ลบพิกัด myLat, myLng หลอกๆ ออก] 
    // และดึงค่าระยะทางมาจาก Object restaurant ที่หน้าแรกส่งมาให้
    double? displayDistance = widget.restaurant.distance;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.restaurant.name),
        backgroundColor: const Color(0xFFE64A19),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ส่วนแสดงข้อมูลเบื้องต้น
            Container(
              width: double.infinity,
              color: const Color(0xFFE64A19).withOpacity(0.05),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('หมวดหมู่: ${widget.restaurant.category}', style: const TextStyle(fontSize: 16, color: Color(0xFFE64A19), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 6),
                      // 🚩 แสดงระยะทางที่ส่งมาจากหน้าแรก (เชื่อถือได้ 100%)
                      Text(
                        displayDistance != null 
                          ? 'ห่างจากคุณ: ${displayDistance.toStringAsFixed(2)} กม.' 
                          : 'กำลังคำนวณระยะทาง...', 
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 10),
              child: Text('รายการเมนูอาหาร 🍽️', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            ),
            
            widget.restaurant.menus.isEmpty
              ? const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('ยังไม่มีเมนูอาหาร'))
              : ListView.builder(
                  shrinkWrap: true, 
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.restaurant.menus.length,
                  itemBuilder: (context, index) {
                    final menu = widget.restaurant.menus[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      leading: CircleAvatar(backgroundColor: Colors.grey[100], child: Text('${index + 1}', style: const TextStyle(color: Colors.black87))),
                      title: Text(menu['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Text('${menu['price'] ?? 0} บาท', style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.w900)),
                    );
                  },
                ),

            const Divider(thickness: 1, height: 60, indent: 20, endIndent: 20),

            // ส่วนแสดงรีวิว
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('รีวิวจากผู้ใช้งาน 🌟', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            ),
            
            StreamBuilder<QuerySnapshot>(
              stream: _dbService.getReviews(widget.restaurant.id, limit: 3), 
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Padding(padding: EdgeInsets.all(20), child: Text('ยังไม่มีรีวิวสำหรับร้านนี้', style: TextStyle(color: Colors.grey)));
                }

                return Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true, 
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                        return Container(
                          margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(data['userEmail'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Row(children: [Text('${data['rating']}', style: const TextStyle(fontWeight: FontWeight.w900)), const Icon(Icons.star, color: Colors.amber, size: 16)]),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(data['comment'] ?? '', style: const TextStyle(color: Colors.black87)),
                            ],
                          ),
                        );
                      },
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => AllReviewsScreen(restaurantId: widget.restaurant.id, restaurantName: widget.restaurant.name)));
                      },
                      icon: const Icon(Icons.forum_outlined, color: Color(0xFFE64A19)),
                      label: const Text('ดูรีวิวทั้งหมด', style: TextStyle(color: Color(0xFFE64A19), fontWeight: FontWeight.bold)),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showReviewDialog,
        backgroundColor: Colors.amber,
        icon: const Icon(Icons.rate_review, color: Colors.black87),
        label: const Text('เขียนรีวิว', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
    );
  }
}