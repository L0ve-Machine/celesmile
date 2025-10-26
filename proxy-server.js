const http = require('http');
const https = require('https');

const PORT = 8080;
const DIDIT_API_KEY = 'wpTfm090BVbZCUyLTmRn1SiuA7F-ru5kZ0i5YCJGWGAa';
const DIDIT_BASE_URL = 'verification.didit.me'; // スタンドアロンAPI用

const server = http.createServer((req, res) => {
  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, x-api-key, accept');

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  if (req.method === 'POST') {
    let body = '';

    req.on('data', chunk => {
      body += chunk.toString();
    });

    req.on('end', () => {
      console.log('📱 Request from Flutter:', req.url);
      console.log('📦 Body:', body);

      const options = {
        hostname: DIDIT_BASE_URL,
        port: 443,
        path: `/v2${req.url}`,
        method: 'POST',
        headers: {
          'content-type': 'application/json',
          'accept': 'application/json',
          'x-api-key': DIDIT_API_KEY,
          'Content-Length': Buffer.byteLength(body)
        }
      };

      const proxyReq = https.request(options, (proxyRes) => {
        console.log('📥 Response status:', proxyRes.statusCode);

        let responseBody = '';

        proxyRes.on('data', chunk => {
          responseBody += chunk;
        });

        proxyRes.on('end', () => {
          console.log('📥 Response body:', responseBody);
          res.writeHead(proxyRes.statusCode, proxyRes.headers);
          res.end(responseBody);
        });
      });

      proxyReq.on('error', (error) => {
        console.error('❌ Error:', error);
        res.writeHead(500);
        res.end(JSON.stringify({ error: error.message }));
      });

      proxyReq.write(body);
      proxyReq.end();
    });
  } else {
    res.writeHead(404);
    res.end('Not found');
  }
});

server.listen(PORT, () => {
  console.log(`🚀 Proxy server running on http://localhost:${PORT}`);
  console.log(`   Forward requests to DIDIT API at ${DIDIT_BASE_URL}`);
});
