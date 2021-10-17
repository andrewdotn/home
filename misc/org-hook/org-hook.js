const express = require("express");
const { createWriteStream, readFileSync } = require("fs");
const { createHmac, timingSafeEqual } = require("crypto");

const app = express();

// Must come before body-parser info
app.disable("query parser");

app.use(
  express.raw({
    limit: 10_000_000,
    type: "application/json",
    type: () => true,
  })
);

const log = createWriteStream("hook.log", { flags: "a" });
const hookSecrets = JSON.parse(readFileSync(".org-hook-secrets.json"));

function bodyValidates(req) {
  if (req.get("Content-Type") != "application/json") {
    return { validates: false };
  }
  if (!req.get("X-Hub-Signature-256")) {
    return { validates: false };
  }

  for ([secretName, secret] of Object.entries(hookSecrets)) {
    hmac = createHmac("sha256", secret);
    hmac.update(req.body);
    digest = `sha256=${hmac.digest("hex")}`;

    const buf1 = Buffer.from(digest);
    const buf2 = Buffer.from(req.get("X-Hub-Signature-256"));
    if (buf1.length === buf2.length && timingSafeEqual(buf1, buf2)) {
      return { validates: true, secretName: secretName };
    }
  }

  return { validates: false };
}

app.post("/", (req, res) => {
  let bodyInfo = {};
  let status = 400;

  if (Buffer.isBuffer(req.body)) {
    const { validates, secretName } = bodyValidates(req);
    if (validates) {
      bodyInfo = {
        body: JSON.parse(req.body),
        bodyValidatedWithSecretNamed: secretName,
      };
      status = 200;
    } else {
      bodyInfo = { bodyRaw: req.body.toString("hex") };
    }
  }

  log.write(
    JSON.stringify(
      {
        timestamp: new Date().toISOString(),
        requestIp: req.ip,
        requestIps: req.ips,
        protocol: req.protocol,
        url: req.originalUrl,
        method: req.post,
        headers: req.headers,
        ...bodyInfo,
      },
      null,
      2
    ) + "\n\n",
    (err) => {
      if (err) {
        res.sendStatus(500);
      } else {
        res.sendStatus(status);
      }
    }
  );
});

module.exports = app;

if (require.main === module) {
  const server = app.listen(2000);
  server.on("listening", () => {
    console.log("Listening on", server.address());
  });
}
