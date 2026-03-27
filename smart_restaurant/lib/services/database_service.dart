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
  
  // ==========================================
  // ส่วนจัดการระบบรีวิว (Review & Rating)
  // ==========================================

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

  // ==========================================
  // ส่วนจัดการของแอดมิน (Admin Features)
  // ==========================================

  // 🛡️ [ADMIN] 1. ดึงรีวิวทั้งหมดจากทุกร้านอาหารด้วย Collection Group
  Stream<QuerySnapshot> getAllReviewsForAdmin() {
    // collectionGroup จะไปกวาดหา Sub-collection ที่ชื่อ 'reviews' จากทุกๆ ร้านมารวมกัน
    return FirebaseFirestore.instance.collectionGroup('reviews').snapshots();
  }

  // 🛡️ [ADMIN] 2. ลบรีวิวโดยใช้ DocumentReference
  Future<void> deleteReview(DocumentReference reviewRef) async {
    // สั่งลบเอกสารเป้าหมายทิ้งทันที
    await reviewRef.delete();
  }

  // 🔐 [SECURITY] 3. ฟังก์ชันตรวจสอบรหัสผ่าน Admin จาก Database
  Future<bool> verifyAdminPassword(String inputPassword) async {
    try {
      // 1. วิ่งไปอ่านเอกสาร 'admin' ในแฟ้ม 'settings'
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('settings').doc('admin').get();
      
      // 2. เช็คว่ามีเอกสารนี้อยู่จริงไหม
      if (doc.exists) {
        // 3. ดึงรหัสผ่านที่เก็บไว้มาเทียบกับที่ผู้ใช้พิมพ์
        String actualPassword = doc.get('password');
        return inputPassword == actualPassword;
      }
      return false; // ถ้าหาไฟล์ไม่เจอ ให้ถือว่ารหัสผิดไปเลย
    } catch (e) {
      print("❌ Error verifying admin password: $e");
      return false;
    }
  }

} // 🛑 ปีกกาปิดของ class DatabaseService ต้องอยู่บรรทัดล่างสุดตรงนี้เท่านั้นครับ!