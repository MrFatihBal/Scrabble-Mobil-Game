plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin") // Flutter plugin her zaman en sonda olmalı
}

android {
    namespace = "com.example.kelimeoyunu"

    // Firebase NDK uyumu için NDK sürümünü sabitliyoruz
    ndkVersion = "27.0.12077973"

    compileSdk = 34 // veya flutter.compileSdkVersion da kalabilir

    defaultConfig {
        applicationId = "com.example.kelimeoyunu"
        minSdk = 23 // Firebase Auth için zorunlu minimum SDK
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
