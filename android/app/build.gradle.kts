import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // Uploads the mapping and native symbols so release crashes read as
    // source lines in Crashlytics.
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing credentials live outside the repo (C:/android-keys/atlas).
// Absent on machines that only build debug, so this stays optional.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.atlas_flutter_app"
    // Pinned ahead of flutter.compileSdkVersion because flutter_secure_storage
    // v11 ships AAR metadata requiring callers to compile against 37+.
    // compileSdk only governs which APIs are available at compile time; device
    // reach (minSdk) and runtime behaviour (targetSdk) still follow Flutter's
    // tested defaults below.
    compileSdk = 37
    // Use Flutter's tested NDK rather than pinning a newer one — a pinned
    // bleeding-edge NDK rebuilds the native (sqlite3) sources unnecessarily.
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.pranta.atlas"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true

        // flutter_inapp_purchase ships one Android module per store (play /
        // amazon / horizon) behind a product flavour dimension. Without this the
        // build cannot resolve which one to link and fails on a missing
        // dimension rather than anything that names billing.
        missingDimensionStrategy("platform", "play")
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Flutter turns R8 on for release builds (code and resource
            // shrinking, with optimisation). These rules keep it from
            // stripping the billing classes, which would break purchases only
            // in release.
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            // Signed with the upload key when key.properties is present,
            // otherwise falls back to debug so release builds still run locally.
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // WindowCompat.enableEdgeToEdge, for the same edge-to-edge window on every
    // Android version (15 and later enforce it anyway).
    implementation("androidx.core:core-ktx:1.18.0")
}

flutter {
    source = "../.."
}
