import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/restaurant.dart';

class DatabaseService {
  final CollectionReference _db = FirebaseFirestore.instance.collection('restaurants');

  Stream<List<Restaurant>> getRestaurants() {
    return _db.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Restaurant.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
        .toList());
  }

  Future<void> addRestaurant(String name, String category, double lat, double lng, List<Map<String, dynamic>> menus) {
    return _db.add({
      'name': name,
      'category': category,
      'lat': lat, // 🚩 บันทึกพิกัด
      'lng': lng, 
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
  
  // ส่วนจัดการระบบรีวิว (Review & Rating)
  

  // 1. [WRITE] ฟังก์ชันเพิ่มรีวิวลงใน Sub-collection 'reviews' ของร้านอาหาร
  Future<void> addReview(String restaurantId, String userId, String userEmail, double rating, String comment) {
    // วิ่งเข้าไปที่ร้านอาหาร (doc) -> เปิดสมุดเยี่ยมชม (collection) -> เขียนข้อความ (add)
    return _db.doc(restaurantId).collection('reviews').add({
      'userId': userId,             
      'userEmail': userEmail,       
      'rating': rating,           
      'comment': comment,         
      'timestamp': FieldValue.serverTimestamp(), // 🚩 ประทับตราเวลาของเซิร์ฟเวอร์
    });
  }

  // 2. [READ] ฟังก์ชันดึงข้อมูลรีวิวทั้งหมดของร้านนั้นๆ ออกมาแสดงแบบ Real-time
  Stream<QuerySnapshot> getReviews(String restaurantId, {int? limit}) {
    var query = _db.doc(restaurantId)
        .collection('reviews')
        .orderBy('timestamp', descending: true);
        
    if (limit != null) {
      query = query.limit(limit);
    }
    
    return query.snapshots();
  }
}