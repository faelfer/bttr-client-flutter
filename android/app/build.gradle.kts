plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.bttr.bttr_client_flutter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.bttr.bttr_client_flutter"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["bttrCleartextTraffic"] = "false"
    }

    buildTypes {
        getByName("debug") {
            manifestPlaceholders["bttrCleartextTraffic"] = "true"
        }
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            // Only the isolated CI benchmark can reach the local HTTP WireMock.
            manifestPlaceholders["bttrCleartextTraffic"] =
                (System.getenv("BTTR_PERFORMANCE_BUILD") == "1").toString()
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.profileinstaller:profileinstaller:1.4.1")
}
