plugins {
    id("org.jlleitschuh.gradle.ktlint") version "14.2.0"
}

ktlint {
    version.set("1.8.0")
}

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
    if (name == "app" || name == "macrobenchmark") {
        apply(plugin = "org.jlleitschuh.gradle.ktlint")
        configure<org.jlleitschuh.gradle.ktlint.KtlintExtension> {
            version.set("1.8.0")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
