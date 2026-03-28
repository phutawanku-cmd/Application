import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/restaurant.dart';

class EditRestaurantScreen extends StatefulWidget {
  final Restaurant restaurant; // รับข้อมูลร้านที่จะแก้ไข
  const EditRestaurantScreen({super.key, required this.restaurant});

  @override
  State<EditRestaurantScreen> createState() => _EditRestaurantScreenState();
}

class _EditRestaurantScreenState extends State<EditRestaurantScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers สำหรับข้อมูลต่างๆ
  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _imageUrlController;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  
  final FocusNode _imageUrlFocusNode = FocusNode();
  final DatabaseService _dbService = DatabaseService();
  bool _isLoading = false;

  final List<Map<String, TextEditingController>> _menuControllers = [];

  @override
  void initState() {
    super.initState();
    // 🏗️ ดึงข้อมูลเดิมมาใส่ในช่องกรอกทันที
    _nameController = TextEditingController(text: widget.restaurant.name);
    _categoryController = TextEditingController(text: widget.restaurant.category);
    _imageUrlController = TextEditingController(text: widget.restaurant.imageUrl);
    _latController = TextEditingController(text: widget.restaurant.lat.toString());
    _lngController = TextEditingController(text: widget.restaurant.lng.toString());

    // แปลงรายการเมนูเดิมให้กลายเป็น Controllers
    for (var menu in widget.restaurant.menus) {
      _menuControllers.add({
        'name': TextEditingController(text: menu['name'] ?? ''),
        'price': TextEditingController(text: (menu['price'] ?? 0).toString()),
      });
    }

    _imageUrlFocusNode.addListener(() {
      if (!_imageUrlFocusNode.hasFocus) setState(() {});
    });
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

  Future<void> _updateRestaurant() async {
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

        // 🚀 สั่งอัปเดตข้อมูลแบบ Full Update
        await _dbService.updateRestaurantFull(
          widget.restaurant.id,
          _nameController.text,
          _categoryController.text,
          lat,
          lng,
          menuData,
          _imageUrlController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ อัปเดตข้อมูลร้านเรียบร้อย!'), backgroundColor: Colors.green)
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ เกิดข้อผิดพลาด: $e')));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('แก้ไขข้อมูลร้าน', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFFE64A19), // ส้มอิฐพรีเมียม
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildSectionCard(
                title: 'ข้อมูลและรูปภาพ',
                icon: Icons.edit_note,
                child: Column(
                  children: [
                    // Preview รูปภาพ
                    Container(
                      width: double.infinity, height: 180,
                      decoration: BoxDecoration(
                        color: Colors.grey[100], 
                        borderRadius: BorderRadius.circular(16), 
                        border: Border.all(color: Colors.grey.shade300)
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _imageUrlController.text.isNotEmpty
                            ? Image.network(_imageUrlController.text, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50))
                            : const Icon(Icons.image_search, size: 50),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(_imageUrlController, 'ลิงก์รูปภาพใหม่', Icons.link, focusNode: _imageUrlFocusNode),
                    const SizedBox(height: 12),
                    _buildTextField(_nameController, 'ชื่อร้าน', Icons.restaurant),
                    const SizedBox(height: 12),
                    _buildTextField(_categoryController, 'หมวดหมู่', Icons.category),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionCard(
                title: 'พิกัดร้าน (GPS)',
                icon: Icons.location_on,
                child: Row(
                  children: [
                    Expanded(child: _buildTextField(_latController, 'Lat', Icons.map, keyboard: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField(_lngController, 'Lng', Icons.map, keyboard: TextInputType.number)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionCard(
                title: 'จัดการเมนูอาหาร',
                icon: Icons.restaurant_menu,
                headerAction: OutlinedButton.icon(
                  onPressed: _addMenuField,
                  icon: const Icon(Icons.add),
                  label: const Text('เพิ่มเมนู'),
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFE64A19)),
                ),
                child: Column(
                  children: _menuControllers.asMap().entries.map((entry) {
                    int index = entry.key;
                    var menu = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: TextFormField(controller: menu['name'], decoration: const InputDecoration(hintText: 'ชื่อเมนู', border: OutlineInputBorder()))),
                          const SizedBox(width: 8),
                          Expanded(flex: 1, child: TextFormField(controller: menu['price'], keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'ราคา', border: OutlineInputBorder()))),
                          IconButton(icon: const Icon(Icons.delete_sweep, color: Colors.red), onPressed: () => _removeMenuField(index)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: _isLoading ? null : _updateRestaurant,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('บันทึกการเปลี่ยนแปลง', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {FocusNode? focusNode, TextInputType? keyboard}) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFE64A19)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      validator: (v) => v!.isEmpty ? 'กรุณากรอกข้อมูล' : null,
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child, Widget? headerAction}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
            children: [
              Row(children: [Icon(icon, size: 22, color: Colors.black87), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
              if (headerAction != null) headerAction,
            ]
          ),
          const Divider(height: 30),
          child,
        ],
      ),
    );
  }
}