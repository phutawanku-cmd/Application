import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/restaurant.dart';
import 'edit_restaurant_screen.dart'; // 🚩 ตรวจสอบว่ามีบรรทัดนี้

class UpdateAndDeleteScreen extends StatefulWidget {
  const UpdateAndDeleteScreen({super.key});

  @override
  State<UpdateAndDeleteScreen> createState() => _UpdateAndDeleteScreenState();
}

class _UpdateAndDeleteScreenState extends State<UpdateAndDeleteScreen> {
  final DatabaseService _dbService = DatabaseService();

  // 🗑️ ฟังก์ชันลบร้าน (คงไว้เหมือนเดิม)
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

  // 🚩 หมายเหตุ: เราลบฟังก์ชัน _showEditDialog ออกไปแล้ว เพราะเราจะไปใช้หน้า Edit Screen แทน

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('จัดการข้อมูลร้านอาหาร', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        backgroundColor: const Color(0xFFE64A19), // ส้มอิฐพรีเมียม
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
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          width: 65, height: 65,
                          child: res.imageUrl.isNotEmpty
                              ? Image.network(res.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image)))
                              : Container(color: Colors.grey[200], child: const Icon(Icons.restaurant, color: Colors.grey)),
                        ),
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
                                MaterialPageRoute(
                                  builder: (context) => EditRestaurantScreen(restaurant: res),
                                ),
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