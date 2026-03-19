import 'package:flutter/material.dart';
import '../services/database_service.dart';

class AddRestaurantScreen extends StatefulWidget {
  const AddRestaurantScreen({super.key});

  @override
  State<AddRestaurantScreen> createState() => _AddRestaurantScreenState();
}

class _AddRestaurantScreenState extends State<AddRestaurantScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  // 🚩 เพิ่ม Controller สำหรับพิกัด (ใส่ค่าโซนชลบุรีไว้เป็น Default ให้เทสง่ายๆ)
  final TextEditingController _latController = TextEditingController(text: "13.0833"); 
  final TextEditingController _lngController = TextEditingController(text: "100.9261");
  
  final DatabaseService _dbService = DatabaseService();
  final List<Map<String, TextEditingController>> _menuControllers = [];
  bool _isLoading = false;

  void _addMenuItemField() {
    setState(() {
      _menuControllers.add({
        'name': TextEditingController(),
        'price': TextEditingController(),
      });
    });
  }

  void _removeMenuItemField(int index) {
    setState(() => _menuControllers.removeAt(index));
  }

  Future<void> _saveData() async {
    if (_nameController.text.isEmpty || _categoryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบ')));
      return;
    }

    setState(() => _isLoading = true);

    // 🚩 ดึงค่าพิกัดมาแปลงเป็นตัวเลข
    double lat = double.tryParse(_latController.text.trim()) ?? 0.0;
    double lng = double.tryParse(_lngController.text.trim()) ?? 0.0;

    List<Map<String, dynamic>> menusToSave = _menuControllers.map((controllers) {
      return {
        'name': controllers['name']!.text.trim(),
        'price': int.tryParse(controllers['price']!.text.trim()) ?? 0,
      };
    }).toList();

    try {
      // 🚩 ส่งพิกัดเข้าไปด้วย
      await _dbService.addRestaurant(
        _nameController.text.trim(),
        _categoryController.text.trim(),
        lat,
        lng,
        menusToSave,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _latController.dispose();
    _lngController.dispose();
    for (var controllers in _menuControllers) {
      controllers['name']!.dispose();
      controllers['price']!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เพิ่มร้านอาหารใหม่'), backgroundColor: Colors.deepOrange),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'ชื่อร้านอาหาร', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _categoryController, decoration: const InputDecoration(labelText: 'หมวดหมู่', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              
              // 🚩 ส่วนกรอกพิกัดแบบง่ายๆ
              Row(
                children: [
                  Expanded(child: TextField(controller: _latController, decoration: const InputDecoration(labelText: 'ละติจูด (Lat)', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: TextField(controller: _lngController, decoration: const InputDecoration(labelText: 'ลองจิจูด (Lng)', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 24),

              const Text('เมนูอาหาร', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _menuControllers.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        Expanded(child: TextField(controller: _menuControllers[index]['name'], decoration: const InputDecoration(hintText: 'ชื่อเมนู', border: OutlineInputBorder()))),
                        const SizedBox(width: 8),
                        SizedBox(width: 80, child: TextField(controller: _menuControllers[index]['price'], decoration: const InputDecoration(hintText: 'ราคา', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                        const SizedBox(width: 8),
                        IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => _removeMenuItemField(index)),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], foregroundColor: Colors.deepOrange, padding: const EdgeInsets.symmetric(vertical: 16)), onPressed: _addMenuItemField, icon: const Icon(Icons.add_circle), label: const Text('➕ เพิ่มเมนูอาหาร'))),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white), onPressed: _isLoading ? null : _saveData, child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('บันทึกข้อมูล', style: TextStyle(fontSize: 18)))),
            ],
          ),
        ),
      ),
    );
  }
}