// Minimal zero-dependency static file server for the demo.
// Run with:  node server.js   then open http://localhost:8000
const http = require('http');
const fs = require('fs');
const path = require('path');

const os = require('os');

const PORT = process.env.PORT || 8000;
// Serve from the directory passed as the first CLI arg, the SERVE_ROOT env
// var, or the folder this script lives in — in that order.
const ROOT = path.resolve(process.argv[2] || process.env.SERVE_ROOT || __dirname);

const TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.svg': 'image/svg+xml',
};

const server = http.createServer((req, res) => {
  let urlPath = decodeURIComponent(req.url.split('?')[0]);
  if (urlPath === '/') urlPath = '/index.html';

  // Prevent path traversal.
  const filePath = path.join(ROOT, path.normalize(urlPath));
  if (!filePath.startsWith(ROOT)) {
    res.writeHead(403); res.end('Forbidden'); return;
  }

  fs.readFile(filePath, (err, data) => {
    if (err) {
      // Fall back to index.html so the app always loads (SPA-style).
      fs.readFile(path.join(ROOT, 'index.html'), (e2, indexData) => {
        if (e2) { res.writeHead(404); res.end('Not found'); return; }
        res.writeHead(200, {
          'Content-Type': 'text/html; charset=utf-8',
          'Cache-Control': 'no-cache',
        });
        res.end(indexData);
      });
      return;
    }
    const ext = path.extname(filePath).toLowerCase();
    res.writeHead(200, {
      'Content-Type': TYPES[ext] || 'application/octet-stream',
      // Avoid stale builds after a rebuild.
      'Cache-Control': 'no-cache',
    });
    res.end(data);
  });
});

// Collect this machine's LAN IPv4 addresses to print reachable URLs.
function lanAddresses() {
  const out = [];
  const ifaces = os.networkInterfaces();
  for (const name of Object.keys(ifaces)) {
    for (const net of ifaces[name] || []) {
      if (net.family === 'IPv4' && !net.internal) out.push(net.address);
    }
  }
  return out;
}

// Bind to 0.0.0.0 so it answers on localhost AND the machine's network IP.
server.listen(PORT, '0.0.0.0', () => {
  console.log(`Serving ${ROOT}`);
  console.log(`  Local:   http://localhost:${PORT}`);
  for (const ip of lanAddresses()) {
    console.log(`  Network: http://${ip}:${PORT}`);
  }
});
