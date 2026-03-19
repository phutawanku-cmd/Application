# 🍽️ Smart Restaurant App (Flutter + Firebase)

แอปพลิเคชันค้นหาและแสดงรายการร้านอาหาร พัฒนาด้วยสถาปัตยกรรมแบบ Full-Stack โดยใช้ **Flutter** สำหรับหน้าบ้าน (Frontend) และ **Firebase Cloud Firestore** สำหรับระบบฐานข้อมูลแบบเรียลไทม์ (Real-time Database)

---

## ✨ ฟีเจอร์หลัก (Key Features)
* 🔐 **Authentication:** ระบบสมัครสมาชิกและเข้าสู่ระบบด้วย Email/Password (Firebase Auth) พร้อมระบบ Auto-Login สลับหน้าจออัตโนมัติ
* 📡 **Real-time Database:** ดึงข้อมูลร้านอาหารและอัปเดตหน้าจอทันทีเมื่อมีข้อมูลใหม่โดยไม่ต้องกดรีเฟรช (StreamBuilder)
* 📍 **Geolocation Math:** คำนวณระยะทางจากพิกัดผู้ใช้ถึงร้านอาหารด้วยสมการ Haversine Formula
* 🌟 **Review & Rating System:** ระบบเขียนรีวิวและให้คะแนนดาว พร้อมโชว์รีวิวล่าสุดแบบจำกัดจำนวน (Pagination) เพื่อประหยัดทรัพยากร
* 🛡️ **Admin Mode:** ระบบซ่อนสิทธิ์การเพิ่มร้านอาหารเฉพาะผู้ดูแลระบบ

---

## 🚀 การติดตั้งและใช้งาน (Setup & Installation)

### 1. Clone โปรเจกต์
```bash
git clone [https://github.com/USERNAME/Application.git](https://github.com/USERNAME/Application.git)
cd Application/smart_restaurant

2. ติดตั้ง Dependencies
Bash
flutter clean
flutter pub get
3. 🔥 การตั้งค่า Firebase (SECURITY WARNING)
⚠️ คำเตือนด้านความปลอดภัย: โปรเจกต์นี้ไม่ได้แนบไฟล์ google-services.json มาด้วยเพื่อความปลอดภัยของฐานข้อมูล คุณต้องสร้างและเชื่อมต่อโปรเจกต์ Firebase ของคุณเอง

ขั้นตอนการเชื่อมต่อ:

ไปที่ Firebase Console

สร้าง Project ใหม่ และเปิดใช้งาน Authentication (Email/Password) และ Firestore Database (Test Mode)

กด Add Android App และใส่ Package Name: com.example.smart_restaurant

ดาวน์โหลดไฟล์ google-services.json

นำไฟล์ไปวางไว้ที่โฟลเดอร์: android/app/google-services.json
(หมายเหตุ: ไฟล์นี้ถูกตั้งค่าใน .gitignore ไว้แล้ว เพื่อป้องกันการเผลออัปโหลดขึ้น GitHub)

🗄️ โครงสร้างฐานข้อมูล (Database Schema)
ในการทดสอบระบบ ให้สร้าง Collection ใน Firestore ตามโครงสร้าง NoSQL ดังนี้:

Collection: restaurants

JSON
{
  "name": "ข้าวมันไก่เจ๊ป้อม",
  "category": "อาหารไทย",
  "lat": 13.0850,
  "lng": 100.9300,
  "menus": [
    { "name": "ข้าวมันไก่ต้ม", "price": 50 },
    { "name": "ข้าวมันไก่ทอด", "price": 50 }
  ]
}
(เมื่อผู้ใช้กดรีวิว ระบบจะสร้าง Sub-collection reviews ซ้อนอยู่ข้างในร้านอาหารนั้นๆ ให้อัตโนมัติ)

📱 การรันแอปพลิเคชัน
1. เช็คอุปกรณ์ที่เชื่อมต่อ (Emulator หรือ เครื่องจริง):

Bash
flutter devices
2. สตาร์ทแอปพลิเคชัน:

Bash
flutter run
Developed with ❤️ using Flutter & Firebase


---

### 🎓 อธิบายหลักการวิศวกรรม (Engineering Insights): พลังของ README

ในวงการอุตสาหกรรมซอฟต์แวร์ ไฟล์ **README.md** ไม่ใช่แค่คำอธิบายโปรเจกต์ แต่มันคือ **"หน้าตาและเรซูเม่ของวิศวกร"** ครับ 
* เวลาที่คุณไปสัมภาษณ์งาน กรรมการหรือ Senior Developer จะกดเข้ามาดู GitHub ของคุณ สิ่งแรกที่เขาอ่านคือ README 
* โครงสร้างที่ผมร่างให้ จะแสดงให้เห็นว่าคุณเข้าใจทั้งภาพรวมของ **Tech Stack (Flutter+Firebase)**, เข้าใจ **สถาปัตยกรรมข้อมูล (Database Schema)**, และที่สำคัญคือเข้าใจเรื่อง **ความปลอดภัย (Security Awareness)** ครับ ซึ่งเป็นคุณสมบัติที่บริษัทไอทีระดับท็อปมองหาเลยครับ!

**💡 ข้อควรระวังสุดท้ายก่อน Push โค้ด:**
ตรวจสอบให้แน่ใจว่าไฟล์ `.gitignore` ของคุณ (อยู่ในโฟลเดอร์หลักของ Flutter) มีบรรทัดนี้อยู่แล้วนะครับ (ปกติ Flutter จะใส่มาให้เป็นค่าเริ่มต้น):
```text
# Miscellaneous
*.class
*.log
*.pyc
*.swp
.DS_Store
.atom/
.buildlog/
.history
.svn/
android/app/google-services.json