plugins {
    alias(libs.plugins.android.application)
}

android {
    namespace = "com.printer.demo"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.printer.demo"
        minSdk = 22
        targetSdk = 36
        versionCode = 1
        versionName = "1.2.100.2"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        ndk.abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a"))

//        packagingOptions {
//            jniLibs {
////                useLegacyPackaging = false
//                // 当遇到多个 libc++_shared.so 时，选择第一个找到的
//                pickFirsts += "**/libc++_shared.so"
//            }
//        }
    }

    buildFeatures {
        buildConfig = true
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    sourceSets {
        getByName("main"){
            jniLibs.srcDirs("libs")
        }
    }
}

dependencies {
    implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.jar","*.aar"))))
    implementation(libs.appcompat)
    implementation(libs.material)
    implementation(libs.activity)
    implementation(libs.fragment.ktx)
    implementation(libs.constraintlayout)
    testImplementation(libs.junit)
    androidTestImplementation(libs.ext.junit)
    androidTestImplementation(libs.espresso.core)

    implementation(libs.colorpickerview)
    implementation(libs.androidfilepicker)
    implementation(libs.xxpermissions)
    implementation(libs.circleindicator)
    implementation(libs.xpopup)

//    implementation(project(":CardPrinter_SDK"))
}