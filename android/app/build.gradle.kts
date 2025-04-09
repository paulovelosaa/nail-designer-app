plugins {
    id("com.android.application")
    kotlin("android")
}

android {
    namespace = "com.example.nail_designer_app"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.example.nail_designer_app"
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // Descomente abaixo para usar a assinatura do app
            // signingConfig = signingConfigs.getByName("release")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    // Descomente e configure a assinatura quando estiver com a keystore pronta
    /*
    signingConfigs {
        create("release") {
            storeFile = file("naildesigner-key.jks")
            storePassword = "SUA_SENHA"
            keyAlias = "naildesigner"
            keyPassword = "SUA_SENHA"
        }
    }
    */
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.11.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
}
