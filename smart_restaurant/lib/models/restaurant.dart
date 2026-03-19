class Restaurant {
  final String id;
  final String name; // [cite: 222]
  final String category; // [cite: 223]
  final double lat; // [cite: 225]
  final double lng; // [cite: 225]
  final String priceRange; // 🚩 เพิ่มตาม FR-07 [cite: 137, 224]
  final String openingHours; // 🚩 เพิ่มตาม FR-18 [cite: 152, 226]
  final double rating; // 🚩 เพิ่มตาม FR-20 [cite: 154, 227]
  final String description; // 🚩 เพิ่มตามสเปคหน้า 12 [cite: 228]
  final List<String> searchKeywords;
  final List<Map<String, dynamic>> menus; // [cite: 151]

  Restaurant({
    required this.id,
    required this.name,
    required this.category,
    required this.lat,
    required this.lng,
    required this.priceRange,
    required this.openingHours,
    required this.rating,
    required this.description,
    required this.searchKeywords,
    required this.menus,
  });

  // 📥 ดึงข้อมูลจาก Firestore มาสร้างเป็น Object ใน Flutter
  factory Restaurant.fromFirestore(String id, Map<String, dynamic> data) {
    return Restaurant(
      id: id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      lat: (data['lat'] ?? 0.0).toDouble(),
      lng: (data['lng'] ?? 0.0).toDouble(),
      priceRange: data['priceRange'] ?? 'ไม่ระบุ', // [cite: 224]
      openingHours: data['openingHours'] ?? 'ไม่ระบุ', // [cite: 226]
      rating: (data['rating'] ?? 0.0).toDouble(), // [cite: 227]
      description: data['description'] ?? '', // [cite: 228]
      searchKeywords: List<String>.from(data['searchKeywords'] ?? []),
      menus: List<Map<String, dynamic>>.from(data['menus'] ?? []),
    );
  }

  // 📤 แปลงจาก Object เป็น Map เพื่อส่งไปบันทึกบน Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'lat': lat,
      'lng': lng,
      'priceRange': priceRange,
      'openingHours': openingHours,
      'rating': rating,
      'description': description,
      'searchKeywords': searchKeywords,
      'menus': menus,
    };
  }
}