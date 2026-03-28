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
  final FocusNode _imageUrlFocusNode = FocusNode();

  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  final DatabaseService _dbService = DatabaseService();
  bool _isLoading = false; 

  final List<Map<String, TextEditingController>> _menuControllers = [];

  @override
  void initState() {
    super.initState();
    // 🚩 ระบบแสดงรูปตัวอย่างอัตโนมัติ ยังคงอยู่!
    _imageUrlFocusNode.addListener(() {
      if (!_imageUrlFocusNode.hasFocus) {
        setState(() {}); 
      }
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

        await _dbService.addRestaurant(
          _nameController.text,
          _categoryController.text,
          lat,
          lng,
          menuData, 
          _imageUrlController.text, 
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
    _imageUrlController.dispose(); 
    _imageUrlFocusNode.dispose(); 
    _latController.dispose();
    _lngController.dispose();
    for (var m in _menuControllers) {
      m['name']?.dispose();
      m['price']?.dispose();
    }
    super.dispose();
  }

  // 🎨 ฟังก์ชันช่วยสร้างสไตล์กล่องข้อความให้เป็นธีมเดียวกัน
  InputDecoration _inputStyle(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.deepOrange),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.deepOrange, width: 2)),
      filled: true,
      fillColor: Colors.grey[50], // สีพื้นหลังกล่องข้อความอ่อนๆ
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // 🎨 สีพื้นหลังสไตล์ Admin Dashboard
      appBar: AppBar(
        title: const Text('เพิ่มร้านอาหารใหม่', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        backgroundColor: const Color(0xFFFF5722), // สีส้มสด
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              // 📦 การ์ดส่วนที่ 1: ข้อมูลร้านและรูปภาพปก
              _buildSectionCard(
                title: 'ข้อมูลทั่วไป & รูปภาพปก',
                icon: Icons.storefront,
                child: Column(
                  children: [
                    // 🖼️ กล่องแสดงรูปตัวอย่าง
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300, width: 1.5),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _imageUrlController.text.isNotEmpty
                            ? Image.network(
                                _imageUrlController.text,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text('ลิงก์รูปภาพไม่ถูกต้อง หรือรูปเสีย', style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_search, size: 50, color: Colors.grey[400]),
                                  const SizedBox(height: 8),
                                  Text('วางลิงก์รูปลงในช่องด้านล่างเพื่อแสดงตัวอย่าง', style: TextStyle(color: Colors.grey[500])),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _imageUrlController,
                      focusNode: _imageUrlFocusNode, 
                      decoration: _inputStyle('ลิงก์รูปภาพร้านอาหาร (URL)', Icons.link, hint: 'เช่น https://example.com/image.jpg'),
                      validator: (value) => value!.isEmpty ? 'กรุณาวางลิงก์รูปภาพ' : null,
                      onFieldSubmitted: (_) => setState(() {}), 
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _nameController,
                      decoration: _inputStyle('ชื่อร้านอาหาร', Icons.restaurant),
                      validator: (value) => value!.isEmpty ? 'กรุณากรอกชื่อร้าน' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _categoryController,
                      decoration: _inputStyle('หมวดหมู่', Icons.category, hint: 'เช่น คาเฟ่, อาหารญี่ปุ่น'),
                      validator: (value) => value!.isEmpty ? 'กรุณากรอกหมวดหมู่' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 📦 การ์ดส่วนที่ 2: พิกัดร้าน
              _buildSectionCard(
                title: 'พิกัดร้านอาหาร (GPS)',
                icon: Icons.location_on,
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latController,
                        keyboardType: TextInputType.number,
                        decoration: _inputStyle('ละติจูด (Lat)', Icons.map),
                        validator: (value) => value!.isEmpty ? 'ระบุละติจูด' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lngController,
                        keyboardType: TextInputType.number,
                        decoration: _inputStyle('ลองจิจูด (Lng)', Icons.map),
                        validator: (value) => value!.isEmpty ? 'ระบุลองจิจูด' : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 📦 การ์ดส่วนที่ 3: เมนูอาหาร
              _buildSectionCard(
                title: 'รายการเมนูอาหาร',
                icon: Icons.menu_book,
                headerAction: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.deepOrange,
                    side: const BorderSide(color: Colors.deepOrange),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _addMenuField,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('เพิ่มเมนู', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                child: _menuControllers.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: Text('คลิก "เพิ่มเมนู" เพื่อใส่รายการอาหาร', style: TextStyle(color: Colors.grey[500]))),
                      )
                    : Column(
                        children: _menuControllers.asMap().entries.map((entry) {
                          int index = entry.key;
                          var menu = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                // ตัวเลขลำดับเมนู
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: Colors.deepOrange[100], shape: BoxShape.circle),
                                  child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: menu['name'],
                                    decoration: const InputDecoration(labelText: 'ชื่อเมนู', border: InputBorder.none),
                                    validator: (value) => value!.isEmpty ? 'กรอกชื่อ' : null,
                                  ),
                                ),
                                Container(width: 1, height: 30, color: Colors.grey[300]), // เส้นคั่น
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 1,
                                  child: TextFormField(
                                    controller: menu['price'],
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'ราคา (฿)', border: InputBorder.none),
                                    validator: (value) => value!.isEmpty ? 'กรอกราคา' : null,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _removeMenuField(index), 
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 30),

              // 🚀 ปุ่มบันทึกข้อมูลยักษ์
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // ใช้สีเขียวเพื่อบอกว่าคือการ "ยืนยัน/เสร็จสิ้น"
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isLoading ? null : _saveRestaurant,
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
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

  // 🎨 ฟังก์ชันช่วยสร้างการ์ดล้อมรอบแต่ละหมวดหมู่ (เพื่อความสะอาดตา)
  Widget _buildSectionCard({required String title, required IconData icon, required Widget child, Widget? headerAction}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: Colors.black87, size: 24),
                    const SizedBox(width: 8),
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
                if (headerAction != null) headerAction,
              ],
            ),
            const Divider(height: 30, thickness: 1),
            child,
          ],
        ),
      ),
    );
  }
}