// WhatsApp login service for Sports Tamil.
//
// 1. A user sends "Hi login" to the WhatsApp Business number.
// 2. Meta calls POST /wa/webhook; the sender's phone is verified by WhatsApp.
// 3. We reply with https://<app>/#/whatsapp-login?code=<one-time code>.
// 4. The app POSTs the code to /wa/exchange and gets a Firebase custom token.
//
// Codes are single use, expire after CODE_TTL_MS and live only in memory, so a
// restart just means "send Hi login again". Link-preview crawlers can't use a
// code: opening the link alone doesn't consume it.
'use strict';

const crypto = require('node:crypto');
const http = require('node:http');
const admin = require('firebase-admin');

const env = (name, fallback) => {
  const value = process.env[name] ?? fallback;
  if (value === undefined || value === '') throw new Error(`Missing env ${name}`);
  return value;
};

const PORT = Number(process.env.PORT || 3000);
const VERIFY_TOKEN = env('WA_VERIFY_TOKEN');
const APP_SECRET = env('WA_APP_SECRET');
const ACCESS_TOKEN = env('WA_ACCESS_TOKEN');
const PHONE_NUMBER_ID = env('WA_PHONE_NUMBER_ID');
const GRAPH_VERSION = env('WA_GRAPH_VERSION', 'v23.0');
const APP_URL = env('APP_URL', 'https://sportstamil.network');
const ALLOWED_ORIGINS = env(
  'ALLOWED_ORIGINS',
  'https://sportstamil.network,https://www.sportstamil.network,https://khelo-hexshankar.web.app,http://127.0.0.1:8090',
).split(',').map((o) => o.trim());

const CODE_TTL_MS = 5 * 60 * 1000;
const LINK_COOLDOWN_MS = 30 * 1000;
const MAX_BODY_BYTES = 256 * 1024;

admin.initializeApp({
  credential: admin.credential.cert(
    JSON.parse(require('node:fs').readFileSync(env('FIREBASE_SERVICE_ACCOUNT_FILE'), 'utf8')),
  ),
});

/** code -> { uid, expiresAt } */
const codes = new Map();
/** phone -> last link time, to stop "login" spam from burning messages */
const lastLinkAt = new Map();

const log = (...args) => console.log(new Date().toISOString(), ...args);
const maskPhone = (phone) => `${phone.slice(0, 4)}…${phone.slice(-2)}`;

setInterval(() => {
  const now = Date.now();
  for (const [code, entry] of codes) if (entry.expiresAt < now) codes.delete(code);
  for (const [phone, at] of lastLinkAt) if (now - at > LINK_COOLDOWN_MS) lastLinkAt.delete(phone);
}, 60 * 1000).unref();

function readBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    let size = 0;
    req.on('data', (chunk) => {
      size += chunk.length;
      if (size > MAX_BODY_BYTES) {
        reject(new Error('Body too large'));
        req.destroy();
        return;
      }
      chunks.push(chunk);
    });
    req.on('end', () => resolve(Buffer.concat(chunks)));
    req.on('error', reject);
  });
}

function send(res, status, body, headers = {}) {
  const isJson = typeof body === 'object';
  res.writeHead(status, {
    'Content-Type': isJson ? 'application/json' : 'text/plain',
    ...headers,
  });
  res.end(isJson ? JSON.stringify(body) : String(body ?? ''));
}

function validSignature(raw, header) {
  if (!header || !header.startsWith('sha256=')) return false;
  const expected = crypto.createHmac('sha256', APP_SECRET).update(raw).digest('hex');
  const given = header.slice('sha256='.length);
  return given.length === expected.length &&
    crypto.timingSafeEqual(Buffer.from(given), Buffer.from(expected));
}

/** Same phone always maps to the same Firebase account. */
async function uidForPhone(phone) {
  const e164 = `+${phone}`;
  try {
    return (await admin.auth().getUserByPhoneNumber(e164)).uid;
  } catch (error) {
    if (error.code !== 'auth/user-not-found') throw error;
  }
  const created = await admin.auth().createUser({ uid: `wa_${phone}`, phoneNumber: e164 });
  return created.uid;
}

async function sendWhatsAppText(to, text) {
  const response = await fetch(
    `https://graph.facebook.com/${GRAPH_VERSION}/${PHONE_NUMBER_ID}/messages`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${ACCESS_TOKEN}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        messaging_product: 'whatsapp',
        to,
        type: 'text',
        text: { body: text, preview_url: false },
      }),
    },
  );
  if (!response.ok) {
    const detail = await response.text();
    throw new Error(`WhatsApp send failed ${response.status}: ${detail.slice(0, 300)}`);
  }
}

async function handleIncomingMessage(message) {
  if (message.type !== 'text') return;
  const phone = String(message.from || '').replace(/\D/g, '');
  if (!phone) return;
  const text = String(message.text?.body || '').toLowerCase();

  if (!text.includes('login')) {
    await sendWhatsAppText(phone, 'Hi! To sign in to Sports Tamil, send: Hi login');
    return;
  }

  const last = lastLinkAt.get(phone);
  if (last && Date.now() - last < LINK_COOLDOWN_MS) return;
  lastLinkAt.set(phone, Date.now());

  const uid = await uidForPhone(phone);
  const code = crypto.randomBytes(24).toString('base64url');
  codes.set(code, { uid, expiresAt: Date.now() + CODE_TTL_MS });

  await sendWhatsAppText(
    phone,
    `Tap to sign in to Sports Tamil:\n${APP_URL}/#/whatsapp-login?code=${code}\n\n` +
      'This link works once and expires in 5 minutes. If you didn\'t ask for it, ignore this message.',
  );
  log('login link sent to', maskPhone(phone));
}

async function handleWebhook(req, res) {
  const raw = await readBody(req);
  if (!validSignature(raw, req.headers['x-hub-signature-256'])) {
    log('webhook rejected: bad signature');
    return send(res, 401, 'bad signature');
  }
  // Acknowledge first; Meta retries slow or failed webhooks.
  send(res, 200, 'ok');

  let payload;
  try {
    payload = JSON.parse(raw.toString('utf8'));
  } catch {
    return;
  }
  for (const entry of payload.entry || []) {
    for (const change of entry.changes || []) {
      for (const message of change.value?.messages || []) {
        handleIncomingMessage(message).catch((error) => log('message error:', error.message));
      }
    }
  }
}

async function handleExchange(req, res, cors) {
  let code;
  try {
    code = JSON.parse((await readBody(req)).toString('utf8')).code;
  } catch {
    return send(res, 400, { error: 'invalid_request' }, cors);
  }
  const entry = typeof code === 'string' ? codes.get(code) : undefined;
  if (code) codes.delete(code);
  if (!entry || entry.expiresAt < Date.now()) {
    return send(res, 400, { error: 'invalid_or_expired' }, cors);
  }
  const token = await admin.auth().createCustomToken(entry.uid, { login: 'whatsapp' });
  return send(res, 200, { token }, cors);
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, 'http://localhost');
  const origin = req.headers.origin;
  const cors = origin && ALLOWED_ORIGINS.includes(origin)
    ? {
        'Access-Control-Allow-Origin': origin,
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
        Vary: 'Origin',
      }
    : {};

  try {
    if (url.pathname === '/wa/health') return send(res, 200, { ok: true });

    if (url.pathname === '/wa/webhook' && req.method === 'GET') {
      const ok = url.searchParams.get('hub.mode') === 'subscribe' &&
        url.searchParams.get('hub.verify_token') === VERIFY_TOKEN;
      log('webhook verification', ok ? 'ok' : 'rejected');
      return ok
        ? send(res, 200, url.searchParams.get('hub.challenge'))
        : send(res, 403, 'forbidden');
    }
    if (url.pathname === '/wa/webhook' && req.method === 'POST') return handleWebhook(req, res);

    if (url.pathname === '/wa/exchange' && req.method === 'OPTIONS') {
      return send(res, 204, '', cors);
    }
    if (url.pathname === '/wa/exchange' && req.method === 'POST') {
      return handleExchange(req, res, cors);
    }
    return send(res, 404, 'not found');
  } catch (error) {
    log('request error:', error.message);
    if (!res.headersSent) send(res, 500, { error: 'server_error' }, cors);
  }
});

server.listen(PORT, () => log(`whatsapp-login listening on ${PORT}`));
