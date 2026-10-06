import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}


// Upload credentials are local-only; never fall back to a debug-signed release.
val uploadProperties = Properties()
val uploadPropertiesFile = rootProject.file("key.properties")
if (uploadPropertiesFile.isFile) {
    uploadPropertiesFile.inputStream().use { uploadProperties.load(it) }
}
val uploadFields = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
val uploadConfigured = uploadFields.all {
    !uploadProperties.getProperty(it).isNullOrBlank()
}
if (gradle.startParameter.taskNames.any { it.contains("release", ignoreCase = true) }) {
    check(uploadConfigured) {
        "Release signing requires private android/key.properties. " +
            "Copy key.properties.example and configure an existing upload key; " +
            "debug builds remain available."
    }
    check(file(uploadProperties.getProperty("storeFile")).isFile) {
        "The configured upload keystore does not exist."
    }
}

android {
    namespace = "com.apollohouser.my_flutter_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.apollohouser.my_flutter_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (uploadConfigured) {
            create("release") {
                storeFile = file(uploadProperties.getProperty("storeFile"))
                storePassword = uploadProperties.getProperty("storePassword")
                keyAlias = uploadProperties.getProperty("keyAlias")
                keyPassword = uploadProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (uploadConfigured) signingConfigs.getByName("release") else null
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
