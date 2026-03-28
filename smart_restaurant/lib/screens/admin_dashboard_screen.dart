import 'package:flutter/material.dart';
import 'update_and_delete_screen.dart';
import 'admin_review_moderation_screen.dart'; // 🚩 นำเข้าหน้าจอจัดการรีวิวสำหรับแอดมิน


class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ Admin Dashboard'),
        backgroundColor: Colors.blueGrey[900], // เปลี่ยนสีให้ดูดุดันสมเป็น Admin
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ยินดีต้อนรับ, ผู้ดูแลระบบ',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // 🛠️ เมนูที่ 1: เพิ่มร้านอาหาร (ใช้งานได้จริง)
            Card(
              elevation: 4,
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.add_business, color: Colors.white)),
                title: const Text('เพิ่มร้านอาหารใหม่', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('เพิ่มข้อมูลร้าน, พิกัด และเมนูอาหาร'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UpdateAndDeleteScreen()), // 👈 เปลี่ยนตรงนี้
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // 🛠️ เมนูที่ 2: จัดการร้านอาหาร แก้ไข/ลบ (เตรียมไว้สำหรับรอบหน้า)
            Card(
              elevation: 4,
              child: ListTile(
                leading: const CircleAvatar(
                    backgroundColor: Colors.orange, 
                    child: Icon(Icons.edit_document, color: Colors.white)
                ),
                title: const Text('จัดการข้อมูลร้านอาหาร', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('แก้ไขรายละเอียด หรือลบร้านออกจากระบบ'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // 🚀 ยิงไปหน้าจัดการข้อมูลได้เลย!
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UpdateAndDeleteScreen()), 
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // 🛠️ เมนูที่ 3: สถิติและรายงาน (Mock UI ไว้ก่อน)
            Card(
              elevation: 4,
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.analytics, color: Colors.white)),
                title: const Text('สถิติระบบ (Dashboard)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('ดูจำนวนผู้เข้าชม และร้านยอดนิยม'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('สถิติระบบจะมาพร้อมกับ User Authentication 🚧')),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // 🛠️ เมนูที่ 4: จัดการรีวิว
            Card(
              elevation: 4,
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.reviews, color: Colors.white)),
                title: const Text('จัดการรีวิว (Moderation)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('ตรวจสอบและลบรีวิวที่ไม่เหมาะสม'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // 🚀 เด้งไปหน้าจัดการรีวิวฉบับแอดมิน!
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminReviewModerationScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}