import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
val isKeystoreConfigured = keystorePropertiesFile.exists()

android {
    namespace = "pl.bator.tatry_kamera"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "pl.bator.tatry_kamera"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = if (project.hasProperty("FLUTTER_MIN_SDK_VERSION")) {
            (project.findProperty("FLUTTER_MIN_SDK_VERSION") as String).toInt()
        } else {
            flutter.minSdkVersion
        }
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }


    signingConfigs {
        if (isKeystoreConfigured) {
            val keystorePath = keystoreProperties["storeFile"] as? String
            val keystoreFile = keystorePath?.let { file(it) }
            if (keystoreFile?.exists() == true) {
                create("release") {
                    keyAlias = keystoreProperties["keyAlias"] as String
                    keyPassword = keystoreProperties["keyPassword"] as String
                    storeFile = keystoreFile
                    storePassword = keystoreProperties["storePassword"] as String
                }
            }
        }
    }

    buildTypes {
        release {
            val releaseSigningConfig = signingConfigs.findByName("release")
            signingConfig = releaseSigningConfig ?: signingConfigs.getByName("debug")
        }
    }

    testOptions {
        unitTests {
            isIncludeAndroidResources = true
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.work:work-runtime-ktx:2.9.1")
    testImplementation("junit:junit:4.13.2")
}

tasks.register("testClasses")
