import java.util.Properties

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

    // Play App Signing: the upload keystore is created by the human
    // maintainer and configured via android/key.properties (gitignored, see
    // docs/PLAY_RELEASE.md §2). While that file is absent the release build
    // keeps the debug key, so `flutter build appbundle --flavor prod` and CI
    // produce the same debug-signed artifact for installability testing only.
    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = Properties().apply {
        if (keystorePropertiesFile.exists()) {
            keystorePropertiesFile.inputStream().use { load(it) }
        }
    }

    if (keystorePropertiesFile.exists()) {
        signingConfigs {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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
