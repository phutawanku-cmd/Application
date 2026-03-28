plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")

    id("com.google.gms.google-services") // 🔥 เพิ่มบรรทัดนี้
}

android {
    namespace = "com.example.smart_restaurant"
    
    // 🚩 แก้จุดที่ 1: ใส่เลข 34 ลงไปตรงๆ แทน flutter.compileSdkVersion
    compileSdk = 36

    // 🚩 แก้จุดที่ 2: ลบบรรทัด ndkVersion ออก หรือคอมเมนต์ไว้ (เพื่อเลิกใช้ NDK ที่พัง)
    // ndkVersion = flutter.ndkVersion 

  

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_21.toString()
    }

    defaultConfig {
        applicationId = "com.example.smart_restaurant"
        
        // 🚩 แก้จุดที่ 3: ใส่เลข 21 (Min SDK ที่ Firebase รองรับ)
        minSdk = flutter.minSdkVersion 
        
        // 🚩 แก้จุดที่ 4: ใส่เลข 34 (Target SDK ที่เสถียรที่สุดตอนนี้)
        targetSdk = 34 

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
