import { readFile } from "fs/promises";
import { resolve } from "path";

interface RemoteConfig {
  graphQlUrl: string;
  apiUrl: string;
  token: string;
}
type Config = { [hostname: string]: RemoteConfig } & { _default?: string };

export function configFilePath() {
  return resolve(__dirname, "..", ".pr-config.json");
}

export async function loadConfig(): Promise<Config> {
  return JSON.parse((await readFile(configFilePath())).toString());
}
