import { randomBytes } from "crypto";
import { run } from "./run";
import chai, { expect } from "chai";
import chaiAsPromised from "chai-as-promised";
chai.use(chaiAsPromised);

function shortRandomString() {
  return randomBytes(10).toString("hex");
}

describe("run", function () {
  it("raises an error if the command does not exist", async function () {
    const dummyCommand = shortRandomString();

    await expect(run([dummyCommand])).to.eventually.rejectedWith(/ENOENT/);
  });

  it("returns expected values", async function () {
    const expectedStdout = shortRandomString();
    const expectedStderr = shortRandomString();

    const ret = await run([
      "sh",
      "-c",
      `echo ${expectedStdout}; echo ${expectedStderr} 1>&2`,
    ]);

    expect(ret.stdout).to.eql(expectedStdout + "\n");
    expect(ret.stderr).to.eql(expectedStderr + "\n");
  });
});
