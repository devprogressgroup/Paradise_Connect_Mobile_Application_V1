import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

// Signature yang SUDAH beredar di semua HP sales (dulu di-build via `flutter run --release`
// dari laptop dev, yang otomatis pakai ~/.android/debug.keystore). File-nya di-copy ke
// android/app/field-signing.keystore supaya jadi secret terkelola & tidak hilang/ter-regenerate
// kalau SDK/Android Studio di-reinstall. Dipakai terus supaya update auto-jalan tanpa uninstall.
val fieldKeystoreProperties = Properties()
val fieldKeystorePropertiesFile = rootProject.file("field-key.properties")
if (fieldKeystorePropertiesFile.exists()) {
    fieldKeystoreProperties.load(fieldKeystorePropertiesFile.inputStream())
}

android {
    namespace = "id.co.progressgroup.connect"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "id.co.progressgroup.connect"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Rilis ini pindah ke release keystore (upload-keystore.jks) secara permanen.
            // Device yang masih pakai APK debug-signed lama wajib uninstall manual sekali
            // sebelum install versi ini (signature berubah, update in-place ditolak Android).
            // Setelah migrasi ini, JANGAN ganti-ganti keystore lagi antar rilis.
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
