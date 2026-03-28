import 'package:flutter/material.dart';
import '../services/database_service.dart';

class AddRestaurantScreen extends StatefulWidget {
  const AddRestaurantScreen({super.key});

  @override
  State<AddRestaurantScreen> createState() => _AddRestaurantScreenState();
}

class _AddRestaurantScreenState extends State<AddRestaurantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  
  // 🔗 เพิ่มกล่องรับลิงก์รูปภาพ (Image URL)
  final _imageUrlController = TextEditingController(); 

  // 📍 กล่องควบคุมพิกัด
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  final DatabaseService _dbService = DatabaseService();
  bool _isLoading = false; 

  final List<Map<String, TextEditingController>> _menuControllers = [];

  void _addMenuField() {
    setState(() {
      _menuControllers.add({
        'name': TextEditingController(),
        'price': TextEditingController(),
      });
    });
  }

  void _removeMenuField(int index) {
    setState(() {
      _menuControllers[index]['name']?.dispose();
      _menuControllers[index]['price']?.dispose();
      _menuControllers.removeAt(index);
    });
  }

  Future<void> _saveRestaurant() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        double lat = double.tryParse(_latController.text) ?? 0.0;
        double lng = double.tryParse(_lngController.text) ?? 0.0;

        List<Map<String, dynamic>> menuData = _menuControllers.map((m) {
          return {
            'name': m['name']!.text,
            'price': double.tryParse(m['price']!.text) ?? 0.0,
          };
        }).toList();

        // 🚀 สั่งบันทึกลงฐานข้อมูล โดยโยนลิงก์รูปภาพเข้าไปตรงๆ เลย!
        await _dbService.addRestaurant(
          _nameController.text,
          _categoryController.text,
          lat,
          lng,
          menuData, 
          _imageUrlController.text, // 🚩 ดึงข้อความจากช่องกรอกลิงก์ส่งไปเลย
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ เพิ่มร้านอาหารพร้อมเมนูเรียบร้อย!')));
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ เกิดข้อผิดพลาด: $e')));
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _imageUrlController.dispose(); // กวาดขยะตัวนี้ด้วย
    _latController.dispose();
    _lngController.dispose();
    for (var m in _menuControllers) {
      m['name']?.dispose();
      m['price']?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เพิ่มร้านอาหารใหม่')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              // 🔗 ช่องกรอกลิงก์รูปภาพ (ง่ายและชัวร์สุด!)
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'ลิงก์รูปภาพร้านอาหาร (URL)', 
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                  hintText: 'เช่น https://example.com/image.jpg',
                ),
                validator: (value) => value!.isEmpty ? 'กรุณาวางลิงก์รูปภาพ' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'ชื่อร้านอาหาร', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'กรุณากรอกชื่อร้าน' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'หมวดหมู่ (เช่น คาเฟ่, อาหารญี่ปุ่น)', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'กรุณากรอกหมวดหมู่' : null,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'ละติจูด (Lat)', border: OutlineInputBorder()),
                      validator: (value) => value!.isEmpty ? 'ระบุละติจูด' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lngController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'ลองจิจูด (Lng)', border: OutlineInputBorder()),
                      validator: (value) => value!.isEmpty ? 'ระบุลองจิจูด' : null,
                    ),
                  ),
                ],
              ),
              const Divider(height: 32, thickness: 2),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('รายการเมนูอาหาร', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                    onPressed: _addMenuField,
                    icon: const Icon(Icons.add),
                    label: const Text('เพิ่มเมนู'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              ..._menuControllers.asMap().entries.map((entry) {
                int index = entry.key;
                var menu = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: menu['name'],
                          decoration: const InputDecoration(labelText: 'ชื่อเมนู', border: OutlineInputBorder()),
                          validator: (value) => value!.isEmpty ? 'กรุณากรอกชื่อ' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: menu['price'],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'ราคา', border: OutlineInputBorder()),
                          validator: (value) => value!.isEmpty ? 'กรอกราคา' : null,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeMenuField(index), 
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: _isLoading ? null : _saveRestaurant,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('บันทึกข้อมูลร้านและเมนู', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}