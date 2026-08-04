import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val signingProperties = Properties()
val signingPropertiesFile = rootProject.file("key.properties")
if (signingPropertiesFile.exists()) {
    signingPropertiesFile.inputStream().use(signingProperties::load)
}

val requiredSigningProperties = listOf(
    "storeFile",
    "storePassword",
    "keyAlias",
    "keyPassword",
)
val releaseSigningConfigured = requiredSigningProperties.all { property ->
    !signingProperties.getProperty(property).isNullOrBlank()
}
val allowDebugReleaseSigning =
    providers.gradleProperty("allowDebugReleaseSigning").orNull?.toBoolean()
        ?: System.getenv("OFRIVO_ALLOW_DEBUG_RELEASE_SIGNING")?.toBoolean()
        ?: false

android {
    namespace = "com.example.ofrivo_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.ofrivo_mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseSigningConfigured) {
            create("release") {
                storeFile = rootProject.file(signingProperties.getProperty("storeFile"))
                storePassword = signingProperties.getProperty("storePassword")
                keyAlias = signingProperties.getProperty("keyAlias")
                keyPassword = signingProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Local smoke builds may opt into debug signing explicitly. A closed-beta
            // build uses `android/key.properties` and the release signing config.
            signingConfig = if (releaseSigningConfigured) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

gradle.taskGraph.whenReady {
    val includesReleaseTask = allTasks.any { task -> task.name.contains("Release") }
    if (includesReleaseTask && !releaseSigningConfigured && !allowDebugReleaseSigning) {
        throw GradleException(
            "Closed-beta release signing is not configured. Create android/key.properties " +
                "from key.properties.example, or set OFRIVO_ALLOW_DEBUG_RELEASE_SIGNING=true " +
                "only for a local smoke build.",
        )
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
