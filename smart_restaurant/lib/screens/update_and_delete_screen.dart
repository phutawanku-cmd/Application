import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🚩 เพิ่ม import นี้สำหรับอัปเดตข้อมูล
import '../services/database_service.dart';
import '../models/restaurant.dart';
import 'edit_restaurant_screen.dart'; 

class UpdateAndDeleteScreen extends StatefulWidget {
  const UpdateAndDeleteScreen({super.key});

  @override
  State<UpdateAndDeleteScreen> createState() => _UpdateAndDeleteScreenState();
}

class _UpdateAndDeleteScreenState extends State<UpdateAndDeleteScreen> {
  final DatabaseService _dbService = DatabaseService();

  // 🗑️ ฟังก์ชันลบร้าน
  void _confirmDelete(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('ยืนยันการลบร้าน', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('คุณแน่ใจหรือไม่ว่าต้องการลบร้าน "$name" ออกจากระบบอย่างถาวร?', textAlign: TextAlign.center, style: const TextStyle(color: Colors.black87)),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () async {
              await _dbService.deleteRestaurant(id);
              if (context.mounted) Navigator.pop(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🗑️ ลบร้านอาหารเรียบร้อยแล้ว'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('ลบทิ้งถาวร', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 📸 ฟังก์ชันอัปเดตรูปภาพด่วน (Quick Image Update)
  void _showUpdateImageDialog(BuildContext context, String id, String currentUrl) {
    final TextEditingController urlController = TextEditingController(text: currentUrl);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('อัปเดตรูปภาพร้าน 📸', style: TextStyle(fontWeight: FontWeight.w900)),
        content: TextField(
          controller: urlController,
          decoration: InputDecoration(
            labelText: 'ลิงก์รูปภาพ (Image URL)',
            hintText: 'วางลิงก์รูปภาพใหม่ที่นี่...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.deepOrange, width: 2)),
            prefixIcon: const Icon(Icons.link, color: Colors.deepOrange),
          ),
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
            ),
            onPressed: () async {
              final newUrl = urlController.text.trim();
              // อัปเดตไปยัง Firestore โดยตรงแบบรวดเร็ว
              await FirebaseFirestore.instance.collection('restaurants').doc(id).update({'imageUrl': newUrl});
              if (context.mounted) Navigator.pop(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('📸 อัปเดตรูปภาพเรียบร้อย!'), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('บันทึกรูปภาพ', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('จัดการข้อมูลร้านอาหาร', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        backgroundColor: const Color(0xFFE64A19), 
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<Restaurant>>(
        stream: _dbService.getRestaurants(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.store_mall_directory_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('ไม่มีข้อมูลร้านอาหารในระบบ', style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          final restaurants = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: restaurants.length,
            itemBuilder: (context, index) {
              final res = restaurants[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      // 📸 อัปเกรดส่วนรูปภาพ: ใส่ Stack เพื่อวางปุ่มกล้องถ่ายรูปทับลงไป
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              width: 70, height: 70, // ขยายรูปขึ้นนิดหน่อยให้ปุ่มกล้องไม่บังมิด
                              child: res.imageUrl.isNotEmpty
                                  ? Image.network(res.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image)))
                                  : Container(color: Colors.grey[200], child: const Icon(Icons.restaurant, color: Colors.grey)),
                            ),
                          ),
                          // 🚀 ปุ่มเปลี่ยนรูปภาพ (Quick Update) ลอยอยู่มุมขวาล่างของรูป
                          Positioned(
                            bottom: -2,
                            right: -2,
                            child: InkWell(
                              onTap: () => _showUpdateImageDialog(context, res.id, res.imageUrl),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.deepOrange,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2), // ขอบขาวให้ดูป๊อปอัป
                                ),
                                child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(res.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(res.category, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 🚀 ปุ่มแก้ไข (พุ่งไปหน้า Edit Screen)
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => EditRestaurantScreen(restaurant: res)),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.edit_rounded, color: Colors.orange, size: 20),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // ปุ่มลบ
                          InkWell(
                            onTap: () => _confirmDelete(context, res.id, res.name),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                            ),
                          ),
                        ],
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