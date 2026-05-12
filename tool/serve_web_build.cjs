const fs = require('fs');
const http = require('http');
const path = require('path');
const { pathToFileURL } = require('url');

const port = Number(process.argv[2] || 18080);
const root = path.resolve(process.argv[3] || 'build/web');

const mimeTypes = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.mjs': 'application/javascript; charset=utf-8',
  '.wasm': 'application/wasm',
  '.json': 'application/json; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.png': 'image/png',
  '.ico': 'image/x-icon',
  '.svg': 'image/svg+xml',
};

function resolveRequest(requestUrl) {
  const url = new URL(requestUrl, 'http://127.0.0.1');
  const relativePath = decodeURIComponent(url.pathname).replace(/^\/+/, '');
  const requested = path.resolve(root, relativePath || 'index.html');
  if (!requested.startsWith(root)) {
    return null;
  }
  if (fs.existsSync(requested) && fs.statSync(requested).isFile()) {
    return requested;
  }
  return path.join(root, 'index.html');
}

http
  .createServer((request, response) => {
    const filePath = resolveRequest(request.url || '/');
    if (!filePath || !fs.existsSync(filePath)) {
      response.writeHead(404);
      response.end('not found');
      return;
    }

    const extension = path.extname(filePath);
    response.writeHead(200, {
      'Content-Type': mimeTypes[extension] || 'application/octet-stream',
      'Cross-Origin-Opener-Policy': 'same-origin',
      'Cross-Origin-Embedder-Policy': 'require-corp',
    });
    fs.createReadStream(filePath).pipe(response);
  })
  .listen(port, '127.0.0.1', () => {
    console.log(
      `Serving ${pathToFileURL(root).href} at http://127.0.0.1:${port}`,
    );
  });
