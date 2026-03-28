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
  final _imageUrlController = TextEditingController(); 
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  final DatabaseService _dbService = DatabaseService();
  bool _isLoading = false; 

  final List<Map<String, TextEditingController>> _menuControllers = [];

  // 🚩 1. ฟังก์ชันเช็คว่าลิงก์รูปภาพน่าจะใช้ได้หรือไม่
  bool _isValidImageUrl(String url) {
    if (url.isEmpty) return false;
    return url.startsWith('http') && 
           (url.toLowerCase().contains('.jpg') || 
            url.toLowerCase().contains('.jpeg') || 
            url.toLowerCase().contains('.png') || 
            url.toLowerCase().contains('.webp') ||
            url.contains('firebasestorage'));
  }

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
      
      // 🚩 2. แจ้งเตือนถ้าลิงก์รูปภาพดูไม่ถูกต้องก่อนบันทึก
      if (!_isValidImageUrl(_imageUrlController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ ลิงก์รูปภาพอาจไม่ถูกต้อง รูปอาจไม่แสดงผลในหน้าแรก'),
            backgroundColor: Colors.orange,
          ),
        );
      }

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

        await _dbService.addRestaurant(
          _nameController.text,
          _categoryController.text,
          lat,
          lng,
          menuData, 
          _imageUrlController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ เพิ่มร้านอาหารเรียบร้อย!')));
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
    _imageUrlController.dispose();
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
              // 🖼️ 3. ส่วนแสดงรูปตัวอย่าง (Image Preview)
              if (_imageUrlController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _imageUrlController.text,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      // ถ้าลิงก์เสีย จะแสดงไอคอนแจ้งเตือน
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, size: 50, color: Colors.red),
                            Text('ลิงก์รูปภาพใช้งานไม่ได้', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'ลิงก์รูปภาพร้านอาหาร (URL)', 
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                  hintText: 'https://example.com/image.jpg',
                ),
                // 🚩 4. เมื่อพิมพ์เสร็จ ให้แอปอัปเดตรูป Preview ทันที
                onChanged: (value) => setState(() {}), 
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
                decoration: const InputDecoration(labelText: 'หมวดหมู่', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'กรุณากรอกหมวดหมู่' : null,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Lat', border: OutlineInputBorder()),
                      validator: (value) => value!.isEmpty ? 'ระบุ Lat' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lngController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Lng', border: OutlineInputBorder()),
                      validator: (value) => value!.isEmpty ? 'ระบุ Lng' : null,
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