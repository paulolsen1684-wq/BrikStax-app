allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    // Some plugins (e.g. sentry_flutter 8.x) pin their own bundled Android
    // module to an old Kotlin languageVersion (1.6) in their own
    // build.gradle. This project's Kotlin compiler (2.3.20, see
    // settings.gradle.kts) has dropped support for compiling against a
    // target that old, which breaks :sentry_flutter:compileDebugKotlin with
    // an opaque "Compilation error. See log for more details" and nothing
    // more specific. Forcing every subproject's Kotlin compile tasks onto a
    // modern, definitely-supported language version overrides that stale
    // per-plugin setting project-wide, without touching the plugin's own
    // source or downgrading the project's own Kotlin toolchain.
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            languageVersion.set(org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_2_0)
            apiVersion.set(org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_2_0)
        }
    }
}

// Same class of problem as the Kotlin languageVersion override above, one
// layer down: sentry_flutter's own bundled Android library module hardcodes
// compileSdkVersion 34 in its own build.gradle, but it transitively pulls
// in package_info_plus (used internally to tag crash reports with the app
// version) at a version that requires compileSdk 36+. Our app module is
// already on compileSdk 36 (see android/app/build.gradle.kts) -- it's
// specifically sentry_flutter's own module that's behind.
//
// afterEvaluate is required, not optional: a plain assignment here would
// run before sentry_flutter's own build.gradle sets its (stale) value,
// which would then silently overwrite it back to 34 with no error --
// exactly what happened on the first attempt at this fix, which looked
// identical to no fix at all. Wrapping in afterEvaluate guarantees this
// runs strictly after the subproject's own script has already set its
// value, so this assignment is always the last one and always wins.
//
// Scoped to ONLY :sentry_flutter, not every library subproject: applying
// this blanket to all of them broke :home_widget, which reads compileSdk
// internally at a different point and throws "too late to set compileSdk"
// once afterEvaluate has already fired for it. Different plugins consume
// this value at different times, so only the one project that actually
// needs the override should get it.
project(":sentry_flutter") {
    afterEvaluate {
        extensions.configure<com.android.build.gradle.LibraryExtension> {
            compileSdk = 36
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
