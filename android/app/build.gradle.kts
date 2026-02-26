plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.starbound.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.starbound.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Enable multidex for complex apps
        multiDexEnabled = true
    }

    // Define signing configurations
    signingConfigs {
        create("release") {
            // Read from environment variables or gradle.properties
            storeFile = file(System.getenv("STARBOUND_KEYSTORE_PATH")
                ?: project.findProperty("starboundKeystorePath") as String?
                ?: "../keystore/release.keystore")
            storePassword = System.getenv("STARBOUND_KEYSTORE_PASSWORD")
                ?: project.findProperty("starboundKeystorePassword") as String?
            keyAlias = System.getenv("STARBOUND_KEY_ALIAS")
                ?: project.findProperty("starboundKeyAlias") as String?
                ?: "starbound-release"
            keyPassword = System.getenv("STARBOUND_KEY_PASSWORD")
                ?: project.findProperty("starboundKeyPassword") as String?
        }
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
            signingConfig = signingConfigs.getByName("debug")
        }

        release {
            // Enable code shrinking, obfuscation, and optimization
            isMinifyEnabled = true
            isShrinkResources = true

            // Use release signing config
            signingConfig = signingConfigs.getByName("release")

            // ProGuard rules
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    // Flavor dimensions for different environments
    flavorDimensions += "environment"
    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
        }
        create("staging") {
            dimension = "environment"
            applicationIdSuffix = ".staging"
            versionNameSuffix = "-staging"
        }
        create("prod") {
            dimension = "environment"
            // No suffix for production
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}
