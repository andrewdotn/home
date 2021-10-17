const express = require("express");
const orgHook = require('./org-hook');
const { resolve } = require("path");
const { appendFileSync } = require("fs");
const { inspect } = require('util');

const startLog = resolve(__dirname, "start.log");
function log(msg) {
  appendFileSync(
    startLog,
    `${new Date().toISOString()}: ${process.pid}: ${msg}\n`
  );
}
log("Started.");

// Based on https://stackoverflow.com/a/14032965/14558
// By Emil Condrea, https://stackoverflow.com/users/832363/emil-condrea
function exitHandler(what, exitCode) {
  // node.js docs say that for SIGTERM and SIGINT, “If one of these signals
  // has a listener installed, its default behavior will be removed
  // (Node.js will no longer exit).” So we’ll exit on our own.
  const shouldExit = ['SIGINT', 'SIGTERM', 'SIGHUP'].includes(what);

  if (exitCode !== undefined) {
    what = `${what}: exit code ${exitCode}`;
  }
  log(what);
  if (shouldExit) {
    log('exiting from exitHandler');
    process.exit();
  }
}

console.log(`hello stdout at ${new Date().toISOString()}`);
console.error(`hello stderr at ${new Date().toISOString()}`);

for (const evt of [
  "exit",
  "SIGUSR1",
  "SIGUSR2",
  "uncaughtException",
  "SIGINT", "SIGTERM", "SIGHUP"
]) {
  process.on(evt, exitHandler.bind(null, evt));
}

const app = express();

if (process.env.NODE_ENV === 'production') {
  app.disable('x-powered-by');
}
app.set("etag", false);

if (process.env.IN_PASSENGER) {
  app.enable('trust proxy');
}

app.get("/", (req, res) => {
  res.sendStatus(404);
});

app.use('/org-hook', orgHook);

app.listen("passenger");
