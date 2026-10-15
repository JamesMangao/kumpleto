plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "io.github.jamesmangao.kumpleto"
    // Play requires API 36 for new apps/updates since 2026-08-31 (see docs/PLAY_RELEASE.md).
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Kept in sync with the reverse-domain repo/GitHub identity.
        applicationId = "io.github.jamesmangao.kumpleto"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        // versionName/versionCode come from pubspec.yaml (version: 0.1.0+1).
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // dev flavor: local development and draft-data builds
    //   (dart run tools/build_data.dart --include-drafts before flutter run --flavor dev)
    // prod flavor: release/store builds; never contains draft data
    //   (flutter build appbundle --flavor prod --release)
    flavorDimensions += "environment"
    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
        }
        create("prod") {
            dimension = "environment"
        }
    }

    buildTypes {
        release {
            // Play App Signing: the upload keystore is created by the human
            // maintainer and configured via android/key.properties (gitignored).
            // Debug signing keeps `flutter build appbundle --flavor prod`
            // working before that file exists; CI produces the same
            // debug-signed artifact for testing only. See docs/PLAY_RELEASE.md.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
