import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/restaurant.dart';

class DatabaseService {
  final CollectionReference _db = FirebaseFirestore.instance.collection('restaurants');

  Stream<List<Restaurant>> getRestaurants() {
    return _db.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Restaurant.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
        .toList());
  }

  // 🚩 เพิ่มรับค่า lat, lng
  Future<void> addRestaurant(String name, String category, double lat, double lng, List<Map<String, dynamic>> menus) {
    return _db.add({
      'name': name,
      'category': category,
      'lat': lat, // 🚩 บันทึกพิกัด
      'lng': lng, // 🚩 บันทึกพิกัด
      'menus': menus,
      'searchKeywords': [name, category, ...menus.map((m) => m['name'] as String)],
    });
  }

  Future<void> updateRestaurant(String id, String newName) {
    return _db.doc(id).update({'name': newName});
  }

  Future<void> deleteRestaurant(String id) {
    return _db.doc(id).delete();
  }


  // [SEARCH] ค้นหาร้านอาหารตาม Keyword
  Stream<List<Restaurant>> searchRestaurants(String query) {
    return _db
        .where('searchKeywords', arrayContains: query)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Restaurant.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }
}