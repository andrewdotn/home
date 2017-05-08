package ca.neitsch.gradle.buildstats;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.time.temporal.IsoFields;
import java.time.temporal.JulianFields;

public class BuildStats {
    private Instant _startTime;
    private String _projectDir;
    private String _projectName;
    private String _rootProjectDir;
    private String _rootProjectName;
    private Instant _endTime;

    public Instant getStartTime() {
        return _startTime;
    }

    public void setStartTime(Instant startTime) {
        this._startTime = startTime;
    }

    public String getProjectDir() {
        return _projectDir;
    }

    public void setProjectDir(String projectDir) {
        this._projectDir = projectDir;
    }

    public String getProjectName() {
        return _projectName;
    }

    public void setProjectName(String projectName) {
        this._projectName = projectName;
    }

    public String getRootProjectDir() {
        return _rootProjectDir;
    }

    public void setRootProjectDir(String rootProjectDir) {
        this._rootProjectDir = rootProjectDir;
    }

    public String getRootProjectName() {
        return _rootProjectName;
    }

    public void setRootProjectName(String rootProjectName) {
        this._rootProjectName = rootProjectName;
    }

    public Instant getEndTime() {
        return _endTime;
    }

    public void setEndTime(Instant endTime) {
        this._endTime = endTime;
    }

    public long getDuration() {
        return _startTime.until(_endTime, ChronoUnit.MILLIS);
    }
}
