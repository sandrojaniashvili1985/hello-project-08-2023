import type { RunOptions } from "memlab";
import type { IScenario } from "@memlab/core";

import { BrowserInteractionResultReader, testInBrowser } from "memlab";
import { MemLabConfig } from "@memlab/core";
import { TestPlanner } from "@memlab/e2e";
import { findLeaks } from "@memlab/api";

import axios from "axios";

require("dotenv").config();

const API = process.env.API_URL || "http://localhost:4000";
axios.defaults.headers.common["api-key"] = process.env.API_TOKEN;

async function getScenarios() {
  const { data: scenarios } = await axios.get(`${API}/api/scenarios`);
  console.info(
    `fetched scenarios: ${JSON.stringify(scenarios.map((s) => s._id))}`
  );
  return scenarios;
}

async function getSettings() {
  const { data: settings } = await axios.get(`${API}/api/settings`);
  console.info(`fetched settings: ${JSON.stringify(settings)}`);
  return settings;
}

/**
 *
 */
async function getGlobalConfig() {
  const { prodUrl } = await getSettings();
  const scenarios = await getScenarios();
  return { prodURL: prodUrl, scenarios };
}

function getConfigFromRunOptions(options: RunOptions): MemLabConfig {
  let config = MemLabConfig.getInstance();
  // if (options.workDir) {
  //   fileManager.initDirs(config, {workDir: options.workDir});
  // } else {
  config = MemLabConfig.resetConfigWithTransientDir();
  // }
  config.isFullRun = !!options.snapshotForEachStep;
  config.oversizeObjectAsLeak = true;
  config.oversizeThreshold = 50000;
  return config;
}

/**
 *
 */
async function takeSnapshotsLocal(
  options: RunOptions = {}
): Promise<BrowserInteractionResultReader> {
  const config = getConfigFromRunOptions(options);
  config.externalCookiesFile = options.cookiesFile;
  config.scenario = options.scenario;
  const testPlanner = new TestPlanner();
  const { evalInBrowserAfterInitLoad } = options;
  await testInBrowser({ testPlanner, config, evalInBrowserAfterInitLoad });
  return BrowserInteractionResultReader.from(config.workDir);
}

async function runMemChecker() {
  const conf = await getGlobalConfig();

  const scenarios = conf.scenarios.map(({ _id, link, action, back }) => {
    return async () => {
      const scenario: IScenario = {
        url: () => conf.prodURL + link,
        action: async (page) => {
          await page.click(action);
        },
        back: async (page) => {
          await page.click(back);
        },
        leakFilter: (node, _snapshot, _leakedNodeIds) => {
          if (node.retainedSize < 100000) {
            return false;
          }
          if (
            node.pathEdge?.type === "internal" ||
            node.pathEdge?.type === "hidden"
          ) {
            return false;
          }
          if (
            (!node.name && node.type === "object") ||
            node.name === "Object" ||
            node.type === "hidden" ||
            node.type.includes("system ") ||
            node.name.includes("system ")
          ) {
            return false;
          }
          return true;
        },
      };
      console.log("Running scenario", scenario.url());
      const leaks = await findLeaks(await takeSnapshotsLocal({ scenario }));
      return { scenarioId: _id, leaks };
    };
  });

  const promiseExecution = async () => {
    for (const promise of scenarios) {
      try {
        let passed: boolean = true;

        const { scenarioId, leaks } = await promise();
        console.info(`executed scenario (ID: ${scenarioId})`);

        if (leaks.length > 0) {
          passed = false;
        }

        await axios.post(`${API}/api/scenarios/${scenarioId}/result`, {
          fullReport: leaks[0],
          passed: passed,
        });

        console.info(`saved report of scenario (ID: ${scenarioId}) to results`);
      } catch (err) {
        console.error(err.message);
      }
    }
  };

  await promiseExecution();
}
runMemChecker();
// setInterval(runMemChecker, 600000);
