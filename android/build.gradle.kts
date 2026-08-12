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
    // jvmTarget: newer Kotlin Gradle Plugin versions now hard-fail
    // (previously just warned) when a module's own Java and Kotlin compile
    // tasks target different JVM versions -- Flutter's own build output
    // lists six plugins in this project that apply KGP (flutter_timezone,
    // home_widget, mobile_scanner, package_info_plus, sentry_flutter,
    // share_plus), and each one's bundled build.gradle leaves
    // jvmTarget/sourceCompatibility at whatever old default it shipped
    // with. This blanket KotlinCompile override is safe project-wide
    // (task-configuration-avoidance closures like this run late enough to
    // reliably win against a plugin's own script -- confirmed: it fixed
    // the Kotlin side for both flutter_timezone and home_widget on the
    // first try, no per-plugin scoping needed here). The matching
    // Java-side half of this fix is NOT safe to do the same way -- see the
    // scoped per-plugin overrides below.
    //
    // languageVersion/apiVersion are deliberately NOT here -- a blanket
    // version of that specific override was a real bug, not just
    // unnecessary caution (see git history: it used to be scoped to
    // :sentry_flutter below, before that whole override was found to be
    // unnecessary and removed 2026-08-12; when it briefly existed as a
    // blanket rule it broke :share_plus:compileDebugKotlin with cascading
    // "Unresolved reference" errors).
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
}

// Java-side half of the JVM-target fix, one plugin at a time. First attempt
// tried a single blanket `subprojects { tasks.withType<JavaCompile>() { ... } }`
// alongside the Kotlin override above -- that DIDN'T work: Kotlin picked up
// 17 immediately, but each plugin's own compileDebugJavaWithJavac stayed at
// its stale default regardless, because AGP's own `android.compileOptions{}`
// DSL sets sourceCompatibility/targetCompatibility directly on the
// JavaCompile task at its own later point, silently overwriting whatever a
// plain tasks.withType().configureEach{} set earlier (the same ordering
// failure mode sentry_flutter's now-removed compileSdk override used to hit
// too, just on a different property -- see git history). Fix shape is the
// same each time: scope to one subproject, go through afterEvaluate so the
// assignment is guaranteed to run after that plugin's own script (and
// AGP's own task wiring) has already set its stale value, and configure
// the DSL extension property directly rather than the raw task.
fun Project.forceJava17() {
    afterEvaluate {
        extensions.configure<com.android.build.gradle.LibraryExtension> {
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
    }
}

// Confirmed needed so far (each hit as a real build failure, one at a time,
// in order): :flutter_timezone (stale default was Java 11),
// :home_widget (stale default was Java 1.8 -- different plugins pin
// different stale defaults, but it's the same shape of problem each time).
// home_widget was also the one plugin that couldn't take a blanket
// compileSdk override (see git history -- it read compileSdk internally at
// an unusually early point and threw "too late to set compileSdk" once
// afterEvaluate had already fired); that was specifically about the
// `compileSdk` property, not `compileOptions`, so forceJava17() here is
// unaffected and still safe.
project(":flutter_timezone") { forceJava17() }
project(":home_widget") { forceJava17() }

// Pre-applied rather than waiting to hit each of these as a separate build
// failure in turn, since they're the remaining plugins from the same
// six-plugin KGP warning list above and this fix shape has now proven
// correct twice. If any of these turns out not to need it (already
// consistent, or reads compileOptions at some other odd time the way
// home_widget does for compileSdk), the fix is a no-op or should be pulled
// back out for that one plugin specifically -- not evidence the whole
// pattern is wrong.
project(":mobile_scanner") { forceJava17() }
project(":package_info_plus") { forceJava17() }
project(":share_plus") { forceJava17() }

// sentry_flutter used to need two extra hand-rolled overrides on top of
// forceJava17() -- compileSdk forced to 36 (its 8.14.2 bundled
// build.gradle hardcoded 34, behind this app's compileSdk 36) and Kotlin
// languageVersion/apiVersion forced to 2.0 (8.14.2 pinned languageVersion
// = "1.6", incompatible with this project's Kotlin compiler, 2.3.20).
//
// 2026-08-12: verified directly against the currently-resolved
// sentry_flutter 9.26.0's own bundled android/build.gradle (pub cache) that
// neither is true anymore. It already declares `compileSdkVersion 36`
// itself, and sets no languageVersion/apiVersion pin at all -- both of
// those overrides were dead weight, quietly doing nothing on every build
// since the 9.25.0 upgrade (2026-08-07) with nothing to signal they'd gone
// stale, exactly the risk flagged when that upgrade happened. It still
// hardcodes Java 8 (compileOptions + kotlinOptions.jvmTarget) though --
// same stale-default problem every other plugin on this list has -- so it
// still needs forceJava17(), just that, same as the others above.
//
// NOT verified with an actual build (Gradle builds can't run from this
// environment -- see CLAUDE.md's Commands section) -- confirmed only by
// reading the resolved dependency's own bundled build.gradle directly, not
// by a successful `flutter build apk`/`flutter run`. Treat as strong
// evidence, not proof, until it's actually been built.
project(":sentry_flutter") { forceJava17() }

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
