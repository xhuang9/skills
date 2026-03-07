#!/usr/bin/env node

import { existsSync, realpathSync } from "node:fs";
import path from "node:path";
import process from "node:process";
import { execFileSync } from "node:child_process";
import { pathToFileURL } from "node:url";

const EXIT_DELEGATE = 0;
const EXIT_CONFIRM = 10;
const EXIT_SKIP = 20;
const EXIT_ERROR = 30;
const DEFAULT_MODEL = "gemini-3-pro-preview";

function parseArgs(argv) {
  const args = {
    cwd: process.cwd(),
    model: null,
    output: "json",
  };

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    switch (arg) {
      case "--cwd":
        args.cwd = argv[++i] ?? args.cwd;
        break;
      case "--model":
        args.model = argv[++i] ?? args.model;
        break;
      case "--output":
        args.output = argv[++i] ?? args.output;
        break;
      case "--help":
      case "-h":
        printHelp();
        process.exit(0);
        break;
      default:
        throw new Error(`Unknown argument: ${arg}`);
    }
  }

  if (args.output !== "json" && args.output !== "text") {
    throw new Error(`Invalid --output value: ${args.output}`);
  }

  return args;
}

function printHelp() {
  process.stdout.write(`Usage: check_usage.mjs [options]

Options:
  --cwd DIR
  --model NAME
  --output json|text
  --help
`);
}

function findGeminiPackageRoot() {
  const geminiBin =
    process.env.GEMINI_BIN ||
    execFileSync("bash", ["-lc", "command -v gemini"], {
      encoding: "utf8",
    }).trim();
  if (!existsSync(geminiBin)) {
    throw new Error(`gemini binary not found at ${geminiBin}`);
  }

  const resolvedEntry = realpathSync(geminiBin);
  const candidates = [
    path.dirname(path.dirname(resolvedEntry)),
    path.join(
      path.dirname(path.dirname(resolvedEntry)),
      "libexec",
      "lib",
      "node_modules",
      "@google",
      "gemini-cli",
    ),
    path.join(
      path.dirname(path.dirname(path.dirname(resolvedEntry))),
      "libexec",
      "lib",
      "node_modules",
      "@google",
      "gemini-cli",
    ),
  ];

  for (const packageRoot of candidates) {
    const configPath = path.join(packageRoot, "dist", "src", "config", "config.js");
    if (existsSync(configPath)) {
      return packageRoot;
    }
  }

  throw new Error(`gemini package root not found for ${resolvedEntry}`);
}

function normalizeModelId(modelId) {
  return modelId.replace(/_vertex$/, "");
}

function dedupeBuckets(buckets) {
  const deduped = new Map();

  for (const bucket of buckets) {
    if (!bucket.modelId) {
      continue;
    }

    const key = normalizeModelId(bucket.modelId);
    const existing = deduped.get(key);
    const preferCurrent =
      !existing ||
      (existing.modelId.endsWith("_vertex") && !bucket.modelId.endsWith("_vertex"));

    if (preferCurrent) {
      deduped.set(key, {
        modelId: key,
        sourceModelId: bucket.modelId,
        remainingFraction: bucket.remainingFraction ?? null,
        remainingPercent:
          bucket.remainingFraction == null
            ? null
            : Number((bucket.remainingFraction * 100).toFixed(1)),
        remainingAmount: bucket.remainingAmount ?? null,
        resetTime: bucket.resetTime ?? null,
        tokenType: bucket.tokenType ?? null,
      });
    }
  }

  return [...deduped.values()].sort((a, b) => a.modelId.localeCompare(b.modelId));
}

function pickTargetBucket(models, requestedModel, fallbackModel = DEFAULT_MODEL) {
  const normalizedRequested = normalizeModelId(requestedModel);
  const normalizedFallback = normalizeModelId(fallbackModel);
  return (
    models.find((model) => model.modelId === normalizedRequested) ??
    models.find((model) => model.modelId === normalizedFallback) ??
    models[0] ??
    null
  );
}

function decideUsage({ email, tier, projectId, targetBucket, googleAiCredits }) {
  if (!email || !tier) {
    return { decision: "skip", reason: "not_authenticated" };
  }

  if (!projectId) {
    return { decision: "confirm", reason: "missing_project_id" };
  }

  if (!targetBucket) {
    return { decision: "confirm", reason: "missing_target_bucket" };
  }

  if (targetBucket.remainingFraction == null) {
    return {
      decision: googleAiCredits && googleAiCredits > 0 ? "confirm" : "skip",
      reason:
        googleAiCredits && googleAiCredits > 0
          ? "missing_fraction_but_credits_available"
          : "missing_fraction",
    };
  }

  if (targetBucket.remainingFraction <= 0) {
    return {
      decision: googleAiCredits && googleAiCredits > 0 ? "confirm" : "skip",
      reason:
        googleAiCredits && googleAiCredits > 0
          ? "quota_exhausted_but_credits_available"
          : "quota_exhausted",
    };
  }

  if (targetBucket.remainingFraction <= 0.15) {
    return { decision: "confirm", reason: "low_remaining_quota" };
  }

  return { decision: "delegate", reason: "healthy_quota" };
}

function exitCodeForDecision(decision) {
  if (decision === "delegate") {
    return EXIT_DELEGATE;
  }
  if (decision === "confirm") {
    return EXIT_CONFIRM;
  }
  if (decision === "skip") {
    return EXIT_SKIP;
  }
  return EXIT_ERROR;
}

function printResult(result, output) {
  if (output === "text") {
    const lines = [
      `decision: ${result.decision}`,
      `reason: ${result.reason}`,
      `tier: ${result.tier ?? "unknown"}`,
      `email: ${result.email ?? "unknown"}`,
      `credits: ${result.googleAiCredits ?? "unknown"}`,
      `project_id: ${result.projectId ?? "unknown"}`,
      `target_model: ${result.targetModel}`,
      `target_remaining_pct: ${
        result.targetBucket?.remainingPercent == null
          ? "unknown"
          : `${result.targetBucket.remainingPercent}%`
      }`,
      `target_reset_time: ${result.targetBucket?.resetTime ?? "unknown"}`,
    ];
    process.stdout.write(`${lines.join("\n")}\n`);
    return;
  }

  process.stdout.write(`${JSON.stringify(result, null, 2)}\n`);
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const packageRoot = findGeminiPackageRoot();

  const configModuleUrl = pathToFileURL(
    path.join(packageRoot, "dist", "src", "config", "config.js"),
  ).href;
  const settingsModuleUrl = pathToFileURL(
    path.join(packageRoot, "dist", "src", "config", "settings.js"),
  ).href;
  const coreModuleUrl = pathToFileURL(
    path.join(packageRoot, "node_modules", "@google", "gemini-cli-core", "dist", "index.js"),
  ).href;

  const originalConsole = {
    log: console.log,
    warn: console.warn,
    error: console.error,
    debug: console.debug,
  };

  console.log = () => {};
  console.warn = () => {};
  console.error = () => {};
  console.debug = () => {};

  try {
    process.env.NO_BROWSER = process.env.NO_BROWSER || "true";

    const [{ parseArguments, loadCliConfig }, { loadSettings }, core] = await Promise.all([
      import(configModuleUrl),
      import(settingsModuleUrl),
      import(coreModuleUrl),
    ]);

    const {
      createSessionId,
      UserAccountManager,
      getCodeAssistServer,
      getG1CreditBalance,
    } = core;

    const settings = loadSettings(args.cwd);
    const configuredModel = settings.merged.model?.name || DEFAULT_MODEL;
    const effectiveModel = args.model || configuredModel;

    process.argv = ["node", "check_usage"];
    const parsedArgv = await parseArguments(settings.merged);
    const config = await loadCliConfig(settings.merged, createSessionId(), parsedArgv, {
      cwd: args.cwd,
    });

    await config.refreshAuth(settings.merged.security.auth.selectedType);
    await config.initialize();
    await Promise.all([config.refreshUserQuota(), config.refreshAvailableCredits()]);

    const accountManager = new UserAccountManager();
    const email = accountManager.getCachedGoogleAccount() ?? null;
    const tier = config.getUserTierName() ?? null;
    const googleAiCredits = getG1CreditBalance(config.getUserPaidTier()) ?? null;
    const projectId = getCodeAssistServer(config)?.projectId ?? null;
    const models = dedupeBuckets(config.getLastRetrievedQuota()?.buckets ?? []);
    const targetBucket = pickTargetBucket(models, effectiveModel, configuredModel);
    const { decision, reason } = decideUsage({
      email,
      tier,
      projectId,
      targetBucket,
      googleAiCredits,
    });

    const result = {
      status: "ok",
      decision,
      reason,
      cwd: args.cwd,
      authMethod: settings.merged.security?.auth?.selectedType ?? null,
      email,
      tier,
      googleAiCredits,
      projectId,
      configuredModel: normalizeModelId(configuredModel),
      targetModel: normalizeModelId(effectiveModel),
      targetBucket,
      models,
    };

    Object.assign(console, originalConsole);
    printResult(result, args.output);
    process.exit(exitCodeForDecision(decision));
  } catch (error) {
    Object.assign(console, originalConsole);
    const result = {
      status: "error",
      decision: "skip",
      reason: "internal_error",
      error: error instanceof Error ? error.message : String(error),
    };
    printResult(result, args.output);
    process.exit(EXIT_ERROR);
  }
}

await main();
