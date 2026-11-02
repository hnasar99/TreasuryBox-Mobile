plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "io.treasurybox.treasurybox_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "io.treasurybox.mobile"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "ecosystem"
    productFlavors {
        create("celo") {
            dimension = "ecosystem"
            applicationIdSuffix = ".celo"
            resValue("string", "app_name", "TreasuryBox Celo")
        }
        create("twin") {
            dimension = "ecosystem"
            applicationIdSuffix = ".twin"
            resValue("string", "app_name", "TreasuryBox Twin")
        }
    }

    buildTypes {
        release {
            // Hackathon CI uploads an unsigned-for-store artifact. Debug key
            // lets the APK install; there is no release keystore in the repo.
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
