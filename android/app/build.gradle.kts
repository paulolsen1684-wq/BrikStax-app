import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    // Push notifications (Firebase Cloud Messaging) -- reads
    // google-services.json below. Native Firebase dependencies come
    // transitively through the firebase_core/firebase_messaging pub
    // packages (see pubspec.yaml), not hand-added here -- that's the normal
    // Flutter pattern, unlike a pure-native Android app where you'd list
    // firebase-bom/firebase-analytics etc. directly in this file's own
    // dependencies block.
    id("com.google.gms.google-services")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.brikstax.brikstax"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications (added for the Daily
        // Five local reminder feature) -- its AAR metadata declares a
        // dependency on Java 8+ APIs (java.time, etc.) that aren't natively
        // available below API 26, so AGP needs to desugar them into the
        // app's own dex output. This is a standard, documented requirement
        // for that plugin (see developer.android.com/studio/write/java8-support),
        // not a project-specific workaround like the toolchain overrides in
        // ../build.gradle.kts.
        isCoreLibraryDesugaringEnabled = true
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    defaultConfig {
        applicationId = "com.brixstax.android"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
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

dependencies {
    implementation("androidx.appcompat:appcompat:1.7.0")
    // Pairs with isCoreLibraryDesugaringEnabled above -- the actual
    // desugaring implementation, required by flutter_local_notifications.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}