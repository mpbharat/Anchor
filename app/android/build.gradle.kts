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

// Some plugins still hardcode an old compileSdk (flutter_webrtc pins 31), which
// AGP rejects because their own AndroidX dependencies require 33/34+. Raise any
// plugin compiling below MIN_PLUGIN_COMPILE_SDK. Reflection is used because AGP
// types aren't on this build script's classpath.
val MIN_PLUGIN_COMPILE_SDK = 36

subprojects {
    if (project.name == "app") return@subprojects
    afterEvaluate {
        val android = extensions.findByName("android") ?: return@afterEvaluate
        try {
            val current = android.javaClass.methods
                .firstOrNull { it.name == "getCompileSdkVersion" && it.parameterCount == 0 }
                ?.invoke(android) as? String // e.g. "android-31"
            val level = current?.substringAfter("android-")?.toIntOrNull()
            if (level == null || level < MIN_PLUGIN_COMPILE_SDK) {
                android.javaClass.methods
                    .firstOrNull { it.name == "setCompileSdkVersion" && it.parameterCount == 1 && it.parameterTypes[0] == Int::class.javaPrimitiveType }
                    ?.invoke(android, MIN_PLUGIN_COMPILE_SDK)
                logger.lifecycle("[anchor] raised ${project.name} compileSdk ${current ?: "unset"} -> $MIN_PLUGIN_COMPILE_SDK")
            }
        } catch (e: Exception) {
            logger.warn("[anchor] could not raise compileSdk for ${project.name}: ${e.message}")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
