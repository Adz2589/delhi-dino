// Tiny static server + frame sink used to record the GIF.
// Open http://localhost:8765/?capture=1 and the page POSTs its demo frames here.
const http = require('http'), fs = require('fs'), path = require('path');
const root = path.join(__dirname, '..');
const out = process.argv[2] || path.join(__dirname, 'frames');
http.createServer((req, res) => {
  if (req.method === 'POST' && req.url === '/frames') {
    let body = '';
    req.on('data', d => body += d);
    req.on('end', () => {
      const frames = JSON.parse(body);
      fs.rmSync(out, { recursive: true, force: true });
      fs.mkdirSync(out, { recursive: true });
      frames.forEach((f, i) => fs.writeFileSync(path.join(out, String(i).padStart(4, '0') + '.png'), Buffer.from(f.split(',')[1], 'base64')));
      console.log('wrote', frames.length, 'frames to', out);
      res.end('ok ' + frames.length);
    });
    return;
  }
  const p = req.url.split('?')[0];
  const f = path.join(root, p === '/' ? 'index.html' : p);
  fs.readFile(f, (e, d) => {
    if (e) { res.statusCode = 404; res.end('not found'); return; }
    const types = { html: 'text/html', svg: 'image/svg+xml', png: 'image/png', gif: 'image/gif', xml: 'application/xml', txt: 'text/plain', js: 'text/javascript', json: 'application/json' };
    res.setHeader('Content-Type', types[f.split('.').pop()] || 'application/octet-stream');
    res.end(d);
  });
}).listen(8765, () => console.log('http://localhost:8765'));
