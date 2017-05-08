package ca.neitsch.gradle.buildstats;

import org.gradle.api.Plugin;
import org.gradle.api.invocation.Gradle;

public class BuildStatsPlugin
    implements Plugin<Gradle>
{
    @Override
    public void apply(Gradle gradle) {
        gradle.addBuildListener(new BuildListener());
    }
}
