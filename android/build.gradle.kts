allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val rootBuildDir = rootProject.layout.projectDirectory.dir("../build")
rootProject.layout.buildDirectory.value(rootBuildDir)

subprojects {
    val newSubprojectBuildDir = rootBuildDir.dir(project.name)
    val projectPath = project.projectDir.absolutePath
    val buildPath = newSubprojectBuildDir.asFile.absolutePath

    // Check if both paths are on the same drive (Windows) to avoid "different roots" errors.
    // AGP tasks like GenerateTestConfig fail if the project and build directories are on different drives.
    val projectRoot = if (projectPath.contains(":")) projectPath.substringBefore(':') else null
    val buildRoot = if (buildPath.contains(":")) buildPath.substringBefore(':') else null

    if (projectRoot == null || projectRoot.equals(buildRoot, ignoreCase = true)) {
        project.layout.buildDirectory.value(newSubprojectBuildDir)
    }

    // Workaround for tools expecting 'testClasses' task, which is not automatically
    // created for Android projects in some Gradle/AGP versions if not using the 'java' plugin.
    afterEvaluate {
        if (tasks.findByName("testClasses") == null) {
            tasks.register("testClasses")
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootBuildDir)
}
