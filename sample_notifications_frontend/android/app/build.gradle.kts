plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.sample_notifications_frontend"
        ndkVersion = "27.0.12077973"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.sample_notifications_frontend"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.1.0"))
    implementation("com.google.firebase:firebase-messaging")
}

flutter {
    source = "../.."
}

/**
 * Ensure CI/build pipelines can find the APK at a stable, repo-relative path.
 *
 * Some build systems expect `app-release.apk` to exist at the Flutter project root:
 *   <flutter_project_root>/app-release.apk
 *
 * Flutter normally generates:
 *   build/app/outputs/flutter-apk/app-release.apk
 *
 * This task copies the generated APK to the expected location after release builds.
 */
val copyReleaseApkToProjectRoot by tasks.registering(Copy::class) {
    // Where Flutter typically writes the release APK (relative to android/app).
    val flutterReleaseApk = layout.projectDirectory.file(
        "../../build/app/outputs/flutter-apk/app-release.apk"
    )

    from(flutterReleaseApk)
    into(layout.projectDirectory.dir("../.."))
    rename { "app-release.apk" }

    doFirst {
        if (!flutterReleaseApk.asFile.exists()) {
            throw GradleException(
                "Release APK not found at: ${flutterReleaseApk.asFile.absolutePath}. " +
                    "Run `flutter build apk --release` (or Gradle assembleRelease) first."
            )
        }
    }
}

/**
 * Hook copy task to common release-producing tasks.
 *
 * In CI, different invocations may be used:
 * - `flutter build apk --release` (Flutter tool orchestrates Gradle tasks)
 * - `./gradlew assembleRelease`
 * - `./gradlew bundleRelease`
 * - Flavor-specific tasks such as `assembleProdRelease`
 *
 * To make the artifact location reliable, finalize *any* Release assemble/bundle task
 * with the copy task.
 */
tasks.matching { task ->
    // Match common Gradle task naming patterns that produce a Release artifact.
    // We keep it simple and conservative: only Release + assemble/bundle tasks.
    val n = task.name
    (n.startsWith("assemble") || n.startsWith("bundle")) && n.endsWith("Release")
}.configureEach {
    finalizedBy(copyReleaseApkToProjectRoot)
}

/**
 * A deterministic task name CI can call to ensure the APK ends up at:
 *   <flutter_project_root>/app-release.apk
 *
 * Note: This does not itself build the APK; it validates that the Flutter-produced
 * APK exists and then copies it to the project root.
 */
tasks.register("ciReleaseApk") {
    group = "build"
    description = "Copies Flutter's release APK to the Flutter project root as app-release.apk (expects it already built)."
    dependsOn(copyReleaseApkToProjectRoot)
}
