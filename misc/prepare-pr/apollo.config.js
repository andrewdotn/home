const { readFileSync } = require("fs");
const { resolve } = require("path");

const config = JSON.parse(
  readFileSync(resolve(__dirname, ".pr-config.json")).toString()
)["github.com"];

// I *believe* that this is only used by `apollo client:codegen` to retrieve the
// schema, which requires authentication. Not sharing more code because this
// file is not in typescript, and don’t want to think about compiling yet.
module.exports = {
  client: {
    service: {
      name: "github",
      url: config["url"],
      headers: {
        authorization: `Bearer ${config["token"]}`,
      },
    },
  },
};
