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
        // applicationId = "id.co.progressgroup.connect"
        // Di-hardcode (bukan ikut flutter.minSdkVersion) supaya nggak diam-diam naik/turun
        // kalau Flutter SDK di-upgrade. 24 ini juga batas bawah paling ketat yang ada di
        // project ini sekarang — dipaksa oleh plugin local_auth (login biometrik/fingerprint),
        // yang mewajibkan minSdk 24. Turunin di bawah ini bakal gagal build (manifest merger
        // error) kecuali local_auth dilepas.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Nama aplikasi di launcher (dipakai android:label di AndroidManifest.xml).
        // Build debug meng-override ini jadi "Paradise Connect Dev", lihat buildTypes.
        manifestPlaceholders["appName"] = "Paradise Connect"
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
        debug {
            // Bedakan nama di launcher supaya APK dev tidak tertukar dengan APK rilis
            // yang ter-install berdampingan (applicationId debug di-override di bawah).
            manifestPlaceholders["appName"] = "Paradise Connect Dev"
        }
        release {
            // Rilis ini pindah ke release keystore (upload-keystore.jks) secara permanen.
            // Device yang masih pakai APK debug-signed lama wajib uninstall manual sekali
            // sebelum install versi ini (signature berubah, update in-place ditolak Android).
            // Setelah migrasi ini, JANGAN ganti-ganti keystore lagi antar rilis.
            // Pakai findByName supaya build debug tetap jalan di mesin tanpa key.properties;
            // build release tanpa keystore tetap digagalkan lewat cek taskGraph di bawah.
            signingConfig = signingConfigs.findByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

// applicationId untuk build type debug di-override di sini (bukan di defaultConfig)
// supaya APK dev bisa ter-install berdampingan dengan APK rilis di HP yang sama.
// Release TIDAK disentuh, tetap pakai applicationId dari defaultConfig.
// "com.example.progress_group" (underscore) dipakai karena cuma itu yang terdaftar di
// google-services.json; package lain bikin processDebugGoogleServices gagal.
androidComponents {
    onVariants(selector().withBuildType("debug")) { variant ->
        variant.applicationId.set("com.example.progress_group")
    }
}

// Build release wajib ditandatangani upload-keystore.jks. Tanpa key.properties, gagalkan
// di sini daripada diam-diam menghasilkan APK rilis tanpa signature.
gradle.taskGraph.whenReady {
    if (!keystorePropertiesFile.exists() && allTasks.any { it.name.contains("Release") }) {
        throw GradleException("android/key.properties tidak ditemukan: build release butuh upload-keystore.jks.")
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}




// import java.util.Properties

// plugins {
//     id("com.android.application")
//     // START: FlutterFire Configuration
//     id("com.google.gms.google-services")
//     // END: FlutterFire Configuration
//     id("kotlin-android")
//     // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
//     id("dev.flutter.flutter-gradle-plugin")
// }

// val keystoreProperties = Properties()
// val keystorePropertiesFile = rootProject.file("key.properties")
// if (keystorePropertiesFile.exists()) {
//     keystoreProperties.load(keystorePropertiesFile.inputStream())
// }

// // Signature yang SUDAH beredar di semua HP sales (dulu di-build via `flutter run --release`
// // dari laptop dev, yang otomatis pakai ~/.android/debug.keystore). File-nya di-copy ke
// // android/app/field-signing.keystore supaya jadi secret terkelola & tidak hilang/ter-regenerate
// // kalau SDK/Android Studio di-reinstall. Dipakai terus supaya update auto-jalan tanpa uninstall.
// val fieldKeystoreProperties = Properties()
// val fieldKeystorePropertiesFile = rootProject.file("field-key.properties")
// if (fieldKeystorePropertiesFile.exists()) {
//     fieldKeystoreProperties.load(fieldKeystorePropertiesFile.inputStream())
// }

// android {
//     namespace = "id.co.progressgroup.connect"
//     compileSdk = flutter.compileSdkVersion
//     ndkVersion = flutter.ndkVersion

//     compileOptions {
//         isCoreLibraryDesugaringEnabled = true
//         sourceCompatibility = JavaVersion.VERSION_17
//         targetCompatibility = JavaVersion.VERSION_17
//     }

//     kotlinOptions {
//         jvmTarget = JavaVersion.VERSION_17.toString()
//     }

//     defaultConfig {
//         // applicationId dasar dipakai oleh build release. Untuk build debug,
//         // applicationId di-override jadi "com.example.progress_group" lewat
//         // blok androidComponents di bawah (lihat komentarnya) supaya debug
//         // bisa ter-install berdampingan dengan release tanpa bentrok signature.
//         applicationId = "id.co.progressgroup.connect"
//         // Di-hardcode (bukan ikut flutter.minSdkVersion) supaya nggak diam-diam naik/turun
//         // kalau Flutter SDK di-upgrade. 24 ini juga batas bawah paling ketat yang ada di
//         // project ini sekarang — dipaksa oleh plugin local_auth (login biometrik/fingerprint),
//         // yang mewajibkan minSdk 24. Turunin di bawah ini bakal gagal build (manifest merger
//         // error) kecuali local_auth dilepas.
//         minSdk = 24
//         targetSdk = flutter.targetSdkVersion
//         versionCode = flutter.versionCode
//         versionName = flutter.versionName
//     }

//     signingConfigs {
//         if (keystorePropertiesFile.exists()) {
//             create("release") {
//                 keyAlias = keystoreProperties["keyAlias"] as String
//                 keyPassword = keystoreProperties["keyPassword"] as String
//                 storeFile = file(keystoreProperties["storeFile"] as String)
//                 storePassword = keystoreProperties["storePassword"] as String
//             }
//         }
//     }

//     buildTypes {
//         release {
//             // Rilis ini pindah ke release keystore (upload-keystore.jks) secara permanen.
//             // Device yang masih pakai APK debug-signed lama wajib uninstall manual sekali
//             // sebelum install versi ini (signature berubah, update in-place ditolak Android).
//             // Setelah migrasi ini, JANGAN ganti-ganti keystore lagi antar rilis.
//             signingConfig = signingConfigs.getByName("release")
//             isMinifyEnabled = true
//             isShrinkResources = true
//             proguardFiles(
//                 getDefaultProguardFile("proguard-android-optimize.txt"),
//                 "proguard-rules.pro"
//             )
//         }
//         // Buat preview "kayak release" (minify + shrink) tapi tetap pakai debug keystore,
//         // supaya bisa di-install tanpa proses signing release dan berdampingan dengan
//         // build debug & release asli (applicationId beda, lihat suffix ".staging" di bawah).
//         // Build type debug di atas TIDAK diubah, tetap non-minify untuk kerja harian.
//         create("staging") {
//             initWith(getByName("release"))
//             signingConfig = signingConfigs.getByName("debug")
//             applicationIdSuffix = ".staging"
//             matchingFallbacks += listOf("release")
//         }
//     }
// }

// // applicationId untuk build type debug di-override di sini (bukan di defaultConfig)
// // karena blok `buildTypes` cuma bisa set applicationIdSuffix, bukan applicationId penuh.
// // Release TIDAK disentuh, tetap pakai applicationId dari defaultConfig.
// androidComponents {
//     // "com.example.progress_group" (underscore) dipakai, BUKAN "com.example.progressGroup"
//     // (camelCase), karena cuma versi underscore yang terdaftar di google-services.json.
//     // Pakai versi camelCase bikin task processDebugGoogleServices gagal ("No matching
//     // client found") karena Firebase gak punya entry buat package name itu.
//     onVariants(selector().withBuildType("debug")) { variant ->
//         variant.applicationId.set("com.example.progress_group")
//     }
// }

// flutter {
//     source = "../.."
// }

// dependencies {
//     coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
// }
