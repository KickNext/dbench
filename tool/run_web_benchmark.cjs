const fs = require('fs');
const { chromium } = require('playwright');

const url = process.argv[2] || 'http://127.0.0.1:18080';
const output = process.argv[3] || 'results/web.json';
const executablePath = process.env.CHROME_EXECUTABLE || undefined;

(async () => {
  const browser = await chromium.launch({
    executablePath,
    headless: true,
  });
  const page = await browser.newPage();
  const result = await new Promise(async (resolve, reject) => {
    const timeout = setTimeout(() => {
      reject(new Error('Timed out waiting for DBENCH_RESULT_JSON'));
    }, 180000);

    page.on('console', (message) => {
      const text = message.text();
      if (text.includes('DBENCH_RESULT_JSON=')) {
        clearTimeout(timeout);
        resolve(text.replace(/^.*DBENCH_RESULT_JSON=/, ''));
      }
    });
    page.on('pageerror', (error) => {
      console.error(`PAGEERROR ${error.message}`);
    });

    await page.goto(url, { waitUntil: 'networkidle' });
  });

  fs.mkdirSync(output.substring(0, output.lastIndexOf('/')) || '.', {
    recursive: true,
  });
  fs.writeFileSync(output, result);
  await browser.close();
  console.log(result);
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
