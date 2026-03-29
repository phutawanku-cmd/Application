# 🍽️ Smart Restaurant App

แอปพลิเคชันค้นหาและรีวิวร้านอาหารอัจฉริยะ พัฒนาด้วย **Flutter** และ **Firebase** โดดเด่นด้วยระบบคำนวณระยะทางจาก GPS จริงแบบ Real-time พร้อม UI/UX ระดับพรีเมียมที่ออกแบบมาเพื่อประสบการณ์การใช้งานที่ลื่นไหล

---

## ✨ Features (ฟีเจอร์หลัก)

### 👤 สำหรับผู้ใช้งานทั่วไป (User App)
* **📍 Fast Location & WGS84 Distance:** ระบบดึงพิกัด GPS ความเร็วสูง พร้อมคำนวณระยะทางจากผู้ใช้ถึงร้านอาหารอย่างแม่นยำ (กิโลเมตร)
* **🔥 Smart Grouping:** จัดกลุ่มร้านอาหารอัตโนมัติ
  * ร้านเด็ดห้ามพลาด (จัดอันดับตามคะแนนรีวิวสูงสุด Top 4)
  * ร้านอาหารใกล้ฉัน (รัศมีไม่เกิน 10 กิโลเมตร)
  * ร้านอาหารอื่นๆ 
* **🔍 Real-time Search:** ค้นหาร้านอาหารจาก "ชื่อร้าน" หรือ "หมวดหมู่" ได้ทันที
* **🌟 Rating & Review System:** ระบบให้คะแนนดาว (1-5 ดาว) และเขียนรีวิวความประทับใจ พร้อมแสดงผลแบบ Real-time
* **🎨 Premium UI/UX:** * Seamless Gradient Header (ไล่สีส้มไร้รอยต่อ)
  * Data Badges (ป้ายกำกับข้อมูลอ่านง่าย)
  * Floating Elevated Buttons (ปุ่มลอยมีมิติพร้อมเงาเรืองแสง)

### 🛡️ สำหรับผู้ดูแลระบบ (Executive Dashboard)
* **🔐 Admin Authentication:** ระบบยืนยันตัวตนด้วยรหัสผ่านก่อนเข้าถึงข้อมูลหลังบ้าน
* **📊 Dashboard Stats:** หน้าต่างสรุปผลการดำเนินงาน (ยอดขาย, อัตราการแปลง, จำนวนผู้ใช้)
* **📝 Restaurant Management:** เพิ่ม, ลบ, แก้ไข ข้อมูลร้านอาหาร (ชื่อ, หมวดหมู่, พิกัด Lat/Lng, ลิงก์รูปภาพ) และจัดการเมนูอาหาร

---

## 🛠️ Tech Stack (เทคโนโลยีที่ใช้)
* **Frontend:** Flutter (Dart)
* **Backend (BaaS):** Firebase
  * **Authentication:** ระบบจัดการผู้ใช้งาน
  * **Cloud Firestore:** ฐานข้อมูล NoSQL สำหรับเก็บข้อมูลร้านอาหาร เมนู และรีวิว
* **Location Services:** `geolocator` package สำหรับดึงพิกัด GPS
* **State Management:** `StatefulWidget` & `StreamBuilder` สำหรับดึงข้อมูลแบบ Real-time

---

## 🚀 Getting Started (วิธีการติดตั้งและรันโปรเจกต์)

### สิ่งที่ต้องมีเบื้องต้น (Prerequisites)
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (เวอร์ชันล่าสุด)
- บัญชี [Firebase](https://firebase.google.com/) พร้อมตั้งค่าโปรเจกต์ Android/iOS เรียบร้อยแล้ว

### ขั้นตอนการรัน (Installation)
1. โคลนโปรเจกต์นี้ลงในเครื่องของคุณ:
   ```bash
   git clone [https://github.com/YOUR_USERNAME/smart_restaurant.git](https://github.com/YOUR_USERNAME/smart_restaurant.git)
เข้าไปยังโฟลเดอร์โปรเจกต์:

Bash
cd smart_restaurant
ติดตั้ง Package ต่างๆ ที่จำเป็น:

Bash
flutter pub get
สำคัญ: นำไฟล์การตั้งค่า Firebase มาใส่ในโปรเจกต์

Android: นำ google-services.json ไปวางที่ android/app/

iOS: นำ GoogleService-Info.plist ไปวางที่ ios/Runner/

รันแอปพลิเคชัน:

Bash
flutter run