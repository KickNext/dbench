const fs = require('fs');
const path = require('path');

function loadPlaywright() {
  try {
    return require('playwright');
  } catch (error) {
    try {
      return require(path.resolve(
        __dirname,
        '..',
        'dbench_records',
        'playwright',
        'node_modules',
        'playwright',
      ));
    } catch (_) {
      // Fall through to NODE_PATH entries.
    }
    const nodePath = process.env.NODE_PATH;
    if (!nodePath) {
      throw error;
    }
    for (const entry of nodePath.split(path.delimiter)) {
      try {
        return require(path.join(entry, 'playwright'));
      } catch (_) {
        // Try the next NODE_PATH entry.
      }
    }
    throw error;
  }
}

const { chromium } = loadPlaywright();

const url = process.argv[2] || 'http://127.0.0.1:18080';
const output = process.argv[3] || 'results/web.json';
const executablePath = process.env.CHROME_EXECUTABLE || undefined;

(async () => {
  let browser;
  try {
    browser = await chromium.launch({
      executablePath,
      headless: true,
    });
    const page = await browser.newPage();
    const result = await new Promise((resolve, reject) => {
      let done = false;
      const timeout = setTimeout(() => {
        done = true;
        reject(new Error('Timed out waiting for DBENCH_RESULT_JSON'));
      }, 180000);
      const finish = (value) => {
        if (done) {
          return;
        }
        done = true;
        clearTimeout(timeout);
        resolve(value);
      };
      const fail = (error) => {
        if (done) {
          return;
        }
        done = true;
        clearTimeout(timeout);
        reject(error);
      };

      page.on('console', (message) => {
        const text = message.text();
        if (text.includes('DBENCH_RESULT_JSON=')) {
          finish(text.replace(/^.*DBENCH_RESULT_JSON=/, ''));
        }
      });
      page.on('pageerror', (error) => {
        console.error(`PAGEERROR ${error.message}`);
      });

      page.goto(url, { waitUntil: 'networkidle' }).catch(fail);
    });

    const parsed = JSON.parse(result);
    const failed = parsed.results.filter((entry) => entry.status === 'failed');
    if (failed.length > 0) {
      throw new Error(
        `Benchmark reported failed adapters: ${failed
          .map((entry) => `${entry.database}/${entry.scenario}`)
          .join(', ')}`,
      );
    }
    const completedNonMemory = parsed.results.some(
      (entry) =>
        entry.status === 'completed' && entry.database !== 'memory_baseline',
    );
    if (!completedNonMemory) {
      throw new Error('Benchmark did not complete any persistent adapter.');
    }

    fs.mkdirSync(output.substring(0, output.lastIndexOf('/')) || '.', {
      recursive: true,
    });
    fs.writeFileSync(output, result);
    console.log(
      `Wrote ${output}: ${parsed.environment}, ${parsed.results.length} result rows`,
    );
  } finally {
    await browser?.close();
  }
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
