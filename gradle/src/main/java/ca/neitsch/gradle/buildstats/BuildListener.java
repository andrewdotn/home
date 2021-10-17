package ca.neitsch.gradle.buildstats;

import com.google.common.collect.Lists;
import com.google.common.collect.Maps;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import org.gradle.BuildResult;
import org.gradle.api.Task;
import org.gradle.api.execution.TaskExecutionGraph;
import org.gradle.api.execution.TaskExecutionGraphListener;
import org.gradle.api.execution.TaskExecutionListener;
import org.gradle.api.initialization.Settings;
import org.gradle.api.invocation.Gradle;
import org.gradle.api.tasks.TaskState;

import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;
import java.time.Instant;
import java.time.ZonedDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;

public class BuildListener
        implements org.gradle.BuildListener, TaskExecutionGraphListener, TaskExecutionListener
{
    private ZonedDateTime _startTime;
    private List<Task> _allTasks;
    private ConcurrentMap<Task, JsonObject> _taskInfo = Maps.newConcurrentMap();
    private ConcurrentMap<Task, ZonedDateTime> _taskStart = Maps.newConcurrentMap();

    public BuildListener() {
        _startTime = ZonedDateTime.now();
    }

    @Override
    public void buildStarted(Gradle gradle) {
    }

    @Override
    public void settingsEvaluated(Settings settings) {
    }

    @Override
    public void projectsLoaded(Gradle gradle) {
    }

    @Override
    public void projectsEvaluated(Gradle gradle) {
        gradle.getTaskGraph().addTaskExecutionGraphListener(this);
    }

    @Override
    public void buildFinished(BuildResult buildResult) {
        JsonObject out = new JsonObject();
        out.addProperty("startTime", _startTime.toString());
        out.addProperty("duration", durationBetween(_startTime, ZonedDateTime.now()));
        out.addProperty("rootDir", buildResult.getGradle().getRootProject().getProjectDir().toString());
        out.addProperty("projectName", buildResult.getGradle().getRootProject().getName());
        Throwable buildFailure = buildResult.getFailure();
        if (buildFailure == null) {
            out.addProperty("buildFailure", (String)null);
        } else {
            out.addProperty("buildFailure", chainedFailure(buildResult.getFailure()));
        }

        JsonArray taskArray = new JsonArray();
        _taskInfo.entrySet().stream().forEach(e -> taskArray.add(e.getValue()));
        out.add("tasks", taskArray);

        Gson g = new GsonBuilder()
                .setPrettyPrinting()
                .serializeNulls()
                .create();

        String outFilename = System.getProperty("user.home")
                + "/" + ".gradle/build_history.json";

        try (BufferedWriter writer = new BufferedWriter(
                new FileWriter(outFilename, true))) {
            writer.write(g.toJson(out) + "\n");
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    @Override
    public void graphPopulated(TaskExecutionGraph graph) {
        // The graph is empty when buildFinished() runs; perhaps the tasks
        // are removed from the graph as they are completed?
        _allTasks = Lists.newArrayList(graph.getAllTasks());
        graph.addTaskExecutionListener(this);
    }

    @Override
    public void beforeExecute(Task task) {
        _taskStart.put(task, ZonedDateTime.now());
    }

    @Override
    public void afterExecute(Task task, TaskState state) {
        ZonedDateTime startTime = _taskStart.get(task);
        JsonObject o = new JsonObject();
        o.addProperty("path", task.getPath());
        o.addProperty("startTime", startTime.toString());
        o.addProperty("duration", durationBetween(startTime, ZonedDateTime.now()));
        o.addProperty("executed", task.getState().getExecuted());
        o.addProperty("didWork", task.getState().getDidWork());
        if (task.getState().getFailure() != null) {
            o.addProperty("failure", chainedFailure(task.getState().getFailure()));
        }
        _taskInfo.put(task, o);
    }

    static private double durationBetween(ZonedDateTime a, ZonedDateTime b) {
        return ChronoUnit.NANOS.between(a, b) / 1e9;
    }

    static private String chainedFailure(Throwable t) {
        if (t == null)
            return null;
        String s = t.getClass().getSimpleName() + ": " + t.getMessage();
        if (t.getCause() == null) {
            return s;
        }
        return s + "\nCaused by " + chainedFailure(t.getCause());
    }
}
