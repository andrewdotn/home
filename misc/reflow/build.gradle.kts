import org.gradle.api.tasks.testing.logging.TestExceptionFormat

plugins {
    id("java")
    id("org.jetbrains.intellij") version "1.4.0"
}

repositories {
    mavenCentral()
}

dependencies {
    testImplementation("commons-io:commons-io:2.11.0")
}

intellij {
    // for a full list of IntelliJ IDEA releases please see
    // https://www.jetbrains.com/intellij-repository/releases
    version.set("IC-2021.3")
    pluginName.set("ca_neitsch_intellij_reflow")
    updateSinceUntilBuild.set(false)
}

tasks {
    // Somewhat older java supported by sdk
    withType<JavaCompile> {
        sourceCompatibility = "11"
        targetCompatibility = "11"
    }

    test {
        testLogging {
            exceptionFormat = TestExceptionFormat.FULL

            showCauses = true
            showExceptions = true
        }
    }
}

group = "ca.neitsch.intellij.reflow"
version = "0.0" // Plugin version
