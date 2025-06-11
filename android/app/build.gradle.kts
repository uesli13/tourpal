import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}

android {
    namespace = "com.tourpal"
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
        minSdk = 28
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Load Google Maps API Key from environment variable or local.properties
        val googleMapsApiKey = System.getenv("GOOGLE_MAPS_API_KEY") 
            ?: localProperties.getProperty("GOOGLE_MAPS_API_KEY")
            ?: "GOOGLE_MAPS_API_KEY_NOT_SET"
            
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = googleMapsApiKey
        
        // Log warning if API key is not properly set
        if (googleMapsApiKey == "GOOGLE_MAPS_API_KEY_NOT_SET") {
            println("WARNING: GOOGLE_MAPS_API_KEY not found!")
            println("Set it in local.properties or as environment variable")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}