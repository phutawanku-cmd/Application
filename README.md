# 🍽️ Smart Restaurant (Flutter + Firebase)

แอปแสดงรายการร้านอาหารโดยใช้ Flutter + Firebase Firestore (Realtime)

---

## 🚀 วิธีใช้งาน (Setup ครั้งแรก)

### 1. Clone โปรเจค
```bash
git clone https://github.com/USERNAME/Application.git
cd Application/smart_restaurant
2. ติดตั้ง dependencies
flutter pub get
3. 🔥 ตั้งค่า Firebase (สำคัญมาก)

โปรเจคนี้ใช้ Firebase

วิธีที่ 1 (ถ้ามีไฟล์ให้แล้ว)

ตรวจสอบว่ามีไฟล์นี้:

android/app/google-services.json

ถ้ามีแล้ว → ข้ามไปขั้นตอนถัดไป

วิธีที่ 2 (ถ้าไม่มีไฟล์)

ไปที่ Firebase Console

สร้าง Project ใหม่

Add Android App

ใส่ Package Name:

com.example.smart_restaurant

ดาวน์โหลดไฟล์ google-services.json

วางไว้ที่:

android/app/google-services.json
4. เปิด Firestore Database

ไป Firebase → Firestore Database

กด Create Database

เลือก Test Mode

5. เพิ่มข้อมูลตัวอย่าง

สร้าง Collection:

restaurants

เพิ่ม Document:

{
  "name": "ข้าวมันไก่เจ๊ป้อม",
  "category": "อาหารไทย",
  "lat": 0,
  "lng": 0,
  "searchKeywords": ["ไก่", "ต้ม", "ทอด"]
}
6. เปิด Emulator หรือเสียบมือถือ

เช็ค device:

flutter devices
7. รันแอป
flutter run
🎯 ผลลัพธ์ที่ควรได้

แอปเปิดขึ้นใน Emulator

แสดงรายการร้านอาหารจาก Firestore

ข้อมูล update แบบ realtime