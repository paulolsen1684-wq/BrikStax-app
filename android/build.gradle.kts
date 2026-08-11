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
    // languageVersion/apiVersion are deliberately NOT here anymore --
    // see the :sentry_flutter block below for why a blanket version of
    // that specific override was a real bug, not just an unnecessary one.
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
// plain tasks.withType().configureEach{} set earlier -- the exact same
// ordering failure mode documented below for sentry_flutter's compileSdk
// override, just on a different property. Fix shape is the same each time:
// scope to one subproject, go through afterEvaluate so the assignment is
// guaranteed to run after that plugin's own script (and AGP's own task
// wiring) has already set its stale value, and configure the DSL extension
// property directly rather than the raw task.
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
// home_widget is also the one plugin the compileSdk override below already
// flags as sensitive to blanket treatment -- that was specifically about
// the `compileSdk` property being read at an unusually early point by this
// plugin, not `compileOptions`, so it's still safe to include here.
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

// sentry_flutter's own bundled Android library module hardcodes
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
//
// Also carries the same Java-target fix as forceJava17() above (inlined
// here rather than calling it, since this block already has its own
// afterEvaluate/LibraryExtension scaffolding for compileSdk) -- sentry_flutter
// is on the same six-plugin KGP list as the others, so it likely needs both.
project(":sentry_flutter") {
    afterEvaluate {
        extensions.configure<com.android.build.gradle.LibraryExtension> {
            compileSdk = 36
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
    }

    // languageVersion/apiVersion: sentry_flutter 8.x's own bundled Android
    // module pins its Kotlin compile tasks to languageVersion = "1.6" in
    // its own build.gradle. This project's Kotlin compiler (2.3.20, see
    // settings.gradle.kts) has dropped support for compiling against a
    // target that old, which breaks :sentry_flutter:compileDebugKotlin with
    // an opaque "Compilation error. See log for more details" and nothing
    // more specific.
    //
    // This was ORIGINALLY applied as a blanket subprojects{} override
    // (bumping every plugin's Kotlin tasks to languageVersion/apiVersion
    // 2.0) on the reasoning that no other plugin here would conflict with
    // a modern-but-not-bleeding-edge Kotlin version -- that reasoning was
    // WRONG, and it was a real bug, not just unnecessary caution: it broke
    // :share_plus:compileDebugKotlin with cascading "Unresolved reference"
    // errors (ShareSuccessManager, SharePlusPendingIntent, etc. -- classes
    // that genuinely exist in share_plus 12.0.2's own Kotlin sources, in
    // the same module, but presumably use language syntax/API newer than
    // 2.0 that got rejected once capped down to it). Unlike jvmTarget
    // (a bytecode-output setting, safe to unify blanket), languageVersion/
    // apiVersion caps which Kotlin *language features* the compiler will
    // accept -- forcing every plugin down to the same cap as sentry_flutter's
    // stale 1.6-pin fix is only correct for sentry_flutter itself. Scoped
    // here instead: bump sentry_flutter's stale 1.6 up to a modern,
    // definitely-supported 2.0, and leave every other plugin's Kotlin
    // tasks free to compile at whatever version they actually need (up to
    // this project's real Kotlin compiler version, 2.3.20).
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            languageVersion.set(org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_2_0)
            apiVersion.set(org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_2_0)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
