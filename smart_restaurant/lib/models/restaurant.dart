class Restaurant {
  final String id;
  final String name;
  final String category;
  final double lat;
  final double lng;
  final String priceRange;
  final String openingHours;
  final double rating;
  final String description;
  final String imageUrl;
  final List<String> searchKeywords;
  final List<Map<String, dynamic>> menus;
  // 🚩 เพิ่มตัวแปรนี้เพื่อใช้เก็บระยะทางที่คำนวณได้ (ไม่ต้องส่งมาจาก Firestore)

  double? distance;
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
    required this.imageUrl,
    required this.searchKeywords,
    required this.menus,
    this.distance, // 🚩 เพิ่มใน Constructor แบบ optional
  });

  factory Restaurant.fromFirestore(String id, Map<String, dynamic> data) {
    return Restaurant(
      id: id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      lat: (data['lat'] ?? 0.0).toDouble(),
      lng: (data['lng'] ?? 0.0).toDouble(),
      priceRange: data['priceRange'] ?? 'ไม่ระบุ',
      openingHours: data['openingHours'] ?? 'ไม่ระบุ',
      rating: (data['rating'] ?? 0.0).toDouble(),
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      searchKeywords: List<String>.from(data['searchKeywords'] ?? []),
      menus: List<Map<String, dynamic>>.from(data['menus'] ?? []),
    );
  }

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
      'imageUrl': imageUrl,
      'searchKeywords': searchKeywords,
      'menus': menus,
    };
  }
}
 