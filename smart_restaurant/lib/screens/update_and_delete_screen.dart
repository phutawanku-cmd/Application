import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/restaurant.dart';

class UpdateAndDeleteScreen extends StatefulWidget {
  const UpdateAndDeleteScreen({super.key});

  @override
  State<UpdateAndDeleteScreen> createState() => _UpdateAndDeleteScreenState();
}

class _UpdateAndDeleteScreenState extends State<UpdateAndDeleteScreen> {
  final DatabaseService _dbService = DatabaseService();

  // ฟังก์ชันสำหรับแสดง Dialog ยืนยันการลบ
  void _confirmDelete(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('คุณต้องการลบร้าน "$name" ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _dbService.deleteRestaurant(id);
              if (context.mounted) Navigator.pop(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ลบร้านอาหารเรียบร้อยแล้ว')),
                );
              }
            },
            child: const Text('ลบเลย', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ฟังก์ชันสำหรับแสดง Dialog แก้ไขชื่อร้าน (แบบง่ายตาม DatabaseService ที่มี)
  void _showEditDialog(BuildContext context, String id, String currentName) {
    final TextEditingController editController = TextEditingController(text: currentName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('แก้ไขชื่อร้าน'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(labelText: 'ชื่อร้านใหม่'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (editController.text.trim().isNotEmpty) {
                await _dbService.updateRestaurant(id, editController.text.trim());
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการข้อมูลร้านอาหาร'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Restaurant>>(
        stream: _dbService.getRestaurants(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("ไม่มีข้อมูลร้านอาหาร"));

          final restaurants = snapshot.data!;

          return ListView.builder(
            itemCount: restaurants.length,
            itemBuilder: (context, index) {
              final res = restaurants[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.store)),
                  title: Text(res.name),
                  subtitle: Text(res.category),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ✏️ ปุ่มแก้ไข
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditDialog(context, res.id, res.name),
                      ),
                      // 🗑️ ปุ่มลบ
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, res.id, res.name),
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