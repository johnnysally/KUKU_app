allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Workaround: ensure third-party Android library modules that haven't set an
// explicit `namespace` (older plugin versions) get a namespace assigned so
// AGP configuration doesn't fail. Keeps build robust if a plugin in the
// pub cache misses the namespace declaration.
// Note: removed earlier afterEvaluate best-effort namespace assignment because
// calling afterEvaluate on an already-evaluated project causes configuration
// failures. If the `flutter_local_notifications` plugin still fails due to a
// missing `namespace`, prefer updating the plugin version or using a local
// patched plugin via `dependency_overrides` in `pubspec.yaml`.

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
