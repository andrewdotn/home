import { ChildProcess, spawn, SpawnOptions } from "child_process";
import { inspect } from "util";

export function runInteractively(cmd: string[], options?: SpawnOptions) {
  const proc = spawn(cmd[0], cmd.slice(1), {
    ...options,
    stdio: ["inherit", "inherit", "inherit"],
  });

  return waitForProcToFinish(proc, cmd);
}

function waitForProcToFinish(
  proc: ChildProcess,
  cmd: string[],
  output: { stdout: string; stderr: string }
): Promise<{ stdout: string; stderr: string }>;
function waitForProcToFinish(proc: ChildProcess, cmd: string[]): Promise<void>;

function waitForProcToFinish(
  proc: ChildProcess,
  cmd: string[],
  output?: { stdout: string; stderr: string }
) {
  return new Promise((resolve, reject) => {
    proc.on("error", (e) => reject(e));
    proc.on("exit", (code, signal) => {
      if (code !== 0 || signal) {
        let msg = `${inspect(cmd)} returned [${code}, ${signal}]`;
        if (output) {
          msg += `; output was ${inspect(output)}`;
        }
        return reject(new Error(msg));
      }
      return resolve(output);
    });
  });
}

export function run(
  cmd: string[],
  options?: SpawnOptions
): Promise<{ stdout: string; stderr: string }> {
  const proc = spawn(cmd[0], cmd.slice(1), {
    ...options,
    stdio: ["ignore", "pipe", "pipe"],
  });

  const output = { stdout: "", stderr: "" };

  proc.stdio[1]!.on("data", (data) => (output.stdout += data));
  proc.stdio[2]!.on("data", (data) => (output.stderr += data));
  return waitForProcToFinish(proc, cmd, output);
}
