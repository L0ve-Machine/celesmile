const http = require('http');
const https = require('https');
const crypto = require('crypto');

const PORT = 8080;
const DIDIT_API_KEY = 'wpTfm090BVbZCUyLTmRn1SiuA7F-ru5kZ0i5YCJGWGA';
const DIDIT_WEBHOOK_SECRET = 'apDce5rVy0Yu-PssUjuAZ9DXPXNCztAa84cgZzxf6YU';
const DIDIT_BASE_URL = 'verification.didit.me'; // スタンドアロンAPI用

// Firebase Realtime Database への状態保存（簡易実装）
const verificationStates = {};
const sessionProviderMapping = {}; // sessionId -> providerId のマッピング
const shortIdToFullIdMapping = {}; // 短縮ID -> 完全なセッションID のマッピング

// Webhook 署名検証関数
function verifyWebhookSignature(req, body) {
  const signature = req.headers['x-signature'];
  const timestamp = req.headers['x-timestamp'];

  if (!signature || !timestamp) {
    console.error('❌ Webhook: Missing signature or timestamp headers');
    return false;
  }

  // タイムスタンプ検証（5分以内）
  const now = Math.floor(Date.now() / 1000);
  const requestTime = parseInt(timestamp);
  if (Math.abs(now - requestTime) > 300) {
    console.error('❌ Webhook: Timestamp outside 5-minute window');
    return false;
  }

  // 署名検証: DIDIT は body のみ（timestamp は連結しない）を HMAC-SHA256 署名する
  const hmac = crypto.createHmac('sha256', DIDIT_WEBHOOK_SECRET);
  hmac.update(body);
  const expectedSignature = hmac.digest('hex');

  const sigBuf = Buffer.from(signature, 'hex');
  const expBuf = Buffer.from(expectedSignature, 'hex');
  if (sigBuf.length !== expBuf.length || !crypto.timingSafeEqual(sigBuf, expBuf)) {
    console.error('❌ Webhook: Invalid signature');
    return false;
  }

  return true;
}

const server = http.createServer((req, res) => {
  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, x-api-key, accept, x-signature, x-timestamp');

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  // Webhook エンドポイント
  if (req.url === '/webhook' && req.method === 'POST') {
    let body = '';

    req.on('data', chunk => {
      body += chunk.toString();
    });

    req.on('end', () => {
      console.log('🔔 Webhook received from DID-IT');
      console.log('📦 Body:', body);
      console.log('Headers:', {
        'x-signature': req.headers['x-signature'],
        'x-timestamp': req.headers['x-timestamp']
      });

      if (!verifyWebhookSignature(req, body)) {
        console.error('❌ Webhook signature verification failed');
        res.writeHead(401, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Invalid signature' }));
        return;
      }

      console.log('✅ Webhook signature verified');

      try {
        const data = JSON.parse(body);
        const sessionId = data.session_id;
        const status = data.status;
        const providerId = sessionProviderMapping[sessionId];

        console.log(`📊 Session: ${sessionId}, Status: ${status}, Provider: ${providerId}`);

        // session_url から短縮IDを抽出
        if (data.decision && data.decision.session_url) {
          const shortId = data.decision.session_url.split('/').pop();
          if (shortId) {
            shortIdToFullIdMapping[shortId] = sessionId;
            console.log(`🔗 Mapped short ID: ${shortId} -> ${sessionId}`);
          }
        }

        // ステータスを保存（簡易実装）
        verificationStates[sessionId] = {
          status: status,
          timestamp: new Date().toISOString(),
          data: data,
          providerId: providerId
        };

        // 承認または却下時にログ
        if (data.decision) {
          console.log('🎯 Decision received:', data.decision);
          verificationStates[sessionId].decision = data.decision;
        }

        // TODO: ここで Firebase や他のDB経由でユーザーの検証ステータスを更新
        // 例：
        // if (providerId) {
        //   await updateProviderVerificationStatus(providerId, status);
        //   console.log(`✅ Provider ${providerId} verification status updated to: ${status}`);
        // }

        // 200 OK で応答（DID-IT の再試行を防ぐ）
        res.writeHead(200);
        res.end(JSON.stringify({
          success: true,
          message: 'Webhook received',
          session_id: sessionId,
          status: status,
          provider_id: providerId
        }));

      } catch (e) {
        console.error('❌ Webhook parsing error:', e);
        res.writeHead(400);
        res.end(JSON.stringify({ error: 'Invalid JSON' }));
      }
    });

    return;
  }

  // sessionId と providerId を紐付けするエンドポイント
  if (req.url.startsWith('/register-session/') && req.method === 'POST') {
    const sessionId = req.url.split('/')[2];
    let body = '';

    req.on('data', chunk => {
      body += chunk.toString();
    });

    req.on('end', () => {
      try {
        const data = JSON.parse(body);
        const providerId = data.providerId;

        if (!providerId) {
          res.writeHead(400);
          res.end(JSON.stringify({ error: 'providerId is required' }));
          return;
        }

        // sessionId と providerId を紐付け
        sessionProviderMapping[sessionId] = providerId;
        console.log(`✅ Registered session: ${sessionId} -> Provider: ${providerId}`);

        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          success: true,
          sessionId: sessionId,
          providerId: providerId
        }));
      } catch (e) {
        console.error('❌ Error parsing JSON:', e);
        res.writeHead(400);
        res.end(JSON.stringify({ error: 'Invalid JSON' }));
      }
    });
    return;
  }

  // 検証状態確認エンドポイント
  if (req.url.startsWith('/verification-status/') && req.method === 'GET') {
    let sessionId = req.url.split('/')[2];

    // 短縮IDの場合は完全なIDに変換
    if (shortIdToFullIdMapping[sessionId]) {
      console.log(`🔄 Converting short ID ${sessionId} to full ID ${shortIdToFullIdMapping[sessionId]}`);
      sessionId = shortIdToFullIdMapping[sessionId];
    }

    const state = verificationStates[sessionId];

    if (state) {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(state));
    } else {
      res.writeHead(404);
      res.end(JSON.stringify({ error: 'Session not found', requested_id: sessionId }));
    }
    return;
  }

  // 従来の DID-IT API プロキシ
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
