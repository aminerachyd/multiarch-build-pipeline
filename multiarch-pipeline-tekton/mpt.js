#!/usr/bin/env node

const { program } = require("commander");
const createPipeline = require("./lib/createPipeline");
const createManifestTask = require("./lib/createManifestTask");
const createCodeTestTask = require("./lib/createCodeTestTask");
const createPipelineTrigger = require("./lib/createPipelineTrigger");
const fs = require("fs");

program
  .name("mpt")
  .description(
    "A CLI for launching multiarch build pipelines on Tekton across different clusters"
  )
  .version("0.0.1");

program
  .option("-a, --app-name <name>", "Name of the app")
  .option("-g, --git-url <repo>", "Git repository of the app")
  .option(
    "-r, --image-registry <registry>",
    "Image registry to store the images"
  )
  .option(
    "-n, --namespace <namespace>",
    "Name of the user/organisation on the registry"
  )
  .option(
    "-h, --health-protocol <health-protocol>",
    "Protocol to check the health of the app, either https or grpc"
  )
  .option("-x86, --build-on-x86", "Toggle build on x86 architecture")
  .option("-power, --build-on-power", "Toggle build on IBM Power architecture")
  .option("-z, --build-on-z", "Toggle build on IBM Z architecture")
  .option("--api-server-x86 <api-server-x86-url>", "API server for x86 cluster")
  .option(
    "--api-server-power <api-server-power-url>",
    "API server for power cluster"
  )
  .option("--api-server-z <api-server-z-url>", "API server for z cluster")
  .parse(process.argv);

const options = program.opts();

if (
  !options.appName ||
  !options.gitUrl ||
  !options.imageRegistry ||
  !options.namespace ||
  !options.healthProtocol
) {
  console.log("Please provide all the required options");
  process.exit(1);
}

const pipelineName = options.appName + "-multiarch-pipeline";

if (!options.buildOnX86 && !options.buildOnPower && !options.buildOnZ) {
  console.log("Please provide atleast one build option");
  process.exit(1);
}

if (!options.apiServerX86 && !options.apiServerPower && !options.apiServerZ) {
  console.log("Please provide atleast one API server option");
  process.exit(1);
}

if (options.buildOnX86 && !options.apiServerX86) {
  console.log("Please provide the API server for x86 cluster");
  process.exit(1);
}

if (options.buildOnPower && !options.apiServerPower) {
  console.log("Please provide the API server for Power cluster");
  process.exit(1);
}

if (options.buildOnZ && !options.apiServerZ) {
  console.log("Please provide the API server for Z cluster");
  process.exit(1);
}

try {
  if (!fs.existsSync(`${process.env.HOME}/.mpt`)) {
    fs.mkdirSync(`${process.env.HOME}/.mpt`);
  }
  if (!fs.existsSync(`${process.env.HOME}/.mpt/applied-pipelines`)) {
    fs.mkdirSync(`${process.env.HOME}/.mpt/applied-pipelines`);
  }
  if (!fs.existsSync(`${process.env.HOME}/.mpt/applied-pipelines/tasks`)) {
    fs.mkdirSync(`${process.env.HOME}/.mpt/applied-pipelines/tasks`);
  }
  if (!fs.existsSync(`${process.env.HOME}/.mpt/applied-pipelines/triggers`)) {
    fs.mkdirSync(`${process.env.HOME}/.mpt/applied-pipelines/triggers`);
  }

  createCodeTestTask();
  createManifestTask(options);
  createPipeline({ pipelineName, ...options });

  createPipelineTrigger({ pipelineName, ...options });
} catch (e) {
  console.log("Error:", e);
  process.exit(1);
}
