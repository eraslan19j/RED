plugins {
    alias(libs.plugins.android.application)
}

android {
    namespace = "com.dragonrealms.probe"
    compileSdk = 37

    defaultConfig {
        applicationId = "com.dragonrealms.probe"
        // minSdk 26: Bevy'nin ses (bevy_audio) gereksinimi
        minSdk = 26
        targetSdk = 37
        versionCode = 1
        versionName = "0.1.0-probe"
        ndk {
            abiFilters.add("arm64-v8a")
        }
    }
    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }
}

dependencies {
    implementation(libs.appcompat)
    implementation(libs.core)
    implementation(libs.games.activity)
}
