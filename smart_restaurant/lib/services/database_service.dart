import 'dart:io'; // 🚩 1. นำเข้าเครื่องมือจัดการไฟล์ภาพ
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/restaurant.dart';

class DatabaseService {
  final CollectionReference _db = FirebaseFirestore.instance.collection('restaurants');

  Stream<List<Restaurant>> getRestaurants() {
    return _db.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Restaurant.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
        .toList());
  }

  // 🚩 3. อัปเกรด addRestaurant: รับค่า imageUrl มาด้วยเพื่อบันทึกลงฐานข้อมูล
  Future<void> addRestaurant(String name, String category, double lat, double lng, List<Map<String, dynamic>> menus, String imageUrl) {
    return _db.add({
      'name': name,
      'category': category,
      'lat': lat,
      'lng': lng, 
      'menus': menus,
      'imageUrl': imageUrl, // ⬅️ จดลิงก์รูปลงสมุด
      'rating': 0.0, // เพิ่มค่าเริ่มต้นของดาว
      'searchKeywords': [name, category, ...menus.map((m) => m['name'] as String)],
    });
  }

  Future<void> updateRestaurant(String id, String newName) {
    return _db.doc(id).update({'name': newName});
  }

  Future<void> deleteRestaurant(String id) {
    return _db.doc(id).delete();
  }

  Stream<List<Restaurant>> searchRestaurants(String query) {
    return _db
        .where('searchKeywords', arrayContains: query)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Restaurant.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }
  
  // ==========================================
  // ส่วนจัดการระบบรีวิว (Review & Rating)
  // ==========================================

  Future<void> _updateAverageRating(String restaurantId) async {
    try {
      QuerySnapshot reviewsSnapshot = await _db.doc(restaurantId).collection('reviews').get();

      if (reviewsSnapshot.docs.isEmpty) {
        await _db.doc(restaurantId).update({'rating': 0.0});
        return;
      }

      double totalStars = 0;
      for (var doc in reviewsSnapshot.docs) {
        totalStars += (doc.data() as Map<String, dynamic>)['rating'] ?? 0.0;
      }

      double averageRating = totalStars / reviewsSnapshot.docs.length;
      await _db.doc(restaurantId).update({'rating': averageRating});
      
    } catch (e) {
      print('❌ Error updating average rating: $e');
    }
  }

  Future<void> addReview(String restaurantId, String userId, String userEmail, double rating, String comment) async {
    await _db.doc(restaurantId).collection('reviews').add({
      'userId': userId,             
      'userEmail': userEmail,       
      'rating': rating,           
      'comment': comment,         
      'timestamp': FieldValue.serverTimestamp(), 
    });
    await _updateAverageRating(restaurantId);
  }

  Stream<QuerySnapshot> getReviews(String restaurantId, {int? limit}) {
    var query = _db.doc(restaurantId)
        .collection('reviews')
        .orderBy('timestamp', descending: true);
        
    if (limit != null) {
      query = query.limit(limit);
    }
    
    return query.snapshots();
  }

  // ==========================================
  // ส่วนจัดการของแอดมิน (Admin Features)
  // ==========================================

  Stream<QuerySnapshot> getAllReviewsForAdmin() {
    return FirebaseFirestore.instance.collectionGroup('reviews').snapshots();
  }

  Future<void> deleteReview(DocumentReference reviewRef) async {
    String restaurantId = reviewRef.parent.parent!.id;
    await reviewRef.delete();
    await _updateAverageRating(restaurantId);
  }

  Future<bool> verifyAdminPassword(String inputPassword) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('settings').doc('admin').get();
      if (doc.exists) {
        String actualPassword = doc.get('password');
        return inputPassword == actualPassword;
      }
      return false; 
    } catch (e) {
      print("❌ Error verifying admin password: $e");
      return false;
    }
  }

  // ==========================================
  // 🖼️ ส่วนจัดการรูปภาพ (Firebase Storage)
  // ==========================================

  // 🚩 4. ช่างอัปโหลดภาพมาแล้ว! 
  
} // 🛑 ปีกกาปิดตัวสุดท้าย