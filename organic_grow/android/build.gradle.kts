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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    tasks.configureEach {
        if (this.javaClass.name.contains("KotlinCompile")) {
            try {
                val kotlinOptions = this.javaClass.getMethod("getKotlinOptions").invoke(this)
                val getFreeCompilerArgs = kotlinOptions.javaClass.getMethod("getFreeCompilerArgs")
                val currentArgs = getFreeCompilerArgs.invoke(kotlinOptions) as List<*>
                val setFreeCompilerArgs = kotlinOptions.javaClass.getMethod("setFreeCompilerArgs", List::class.java)
                setFreeCompilerArgs.invoke(kotlinOptions, currentArgs + "-Xskip-metadata-version-check")
            } catch (e: Exception) {}
        }
    }
}

