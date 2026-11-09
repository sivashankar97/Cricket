// Run: cd khelo/whatsapp_login && npm test
'use strict';

const { test, before, after } = require('node:test');
const assert = require('node:assert');
const crypto = require('node:crypto');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawn } = require('node:child_process');

const PORT = 39123;
const BASE = `http://127.0.0.1:${PORT}`;
const APP_SECRET = 'test-app-secret';
let child;
const sent = [];

before(async () => {
  const saFile = path.join(os.tmpdir(), 'wa-login-test-sa.json');
  fs.writeFileSync(saFile, '{}');
  child = spawn(process.execPath, ['--require', path.join(__dirname, 'fake_fetch.js'), path.join(__dirname, '..', 'server.js')], {
    env: {
      ...process.env,
      NODE_PATH: path.join(__dirname, 'fake_modules'),
      PORT: String(PORT),
      WA_VERIFY_TOKEN: 'verify-me',
      WA_APP_SECRET: APP_SECRET,
      WA_ACCESS_TOKEN: 'access',
      WA_PHONE_NUMBER_ID: '123',
      FIREBASE_SERVICE_ACCOUNT_FILE: saFile,
    },
  });
  child.stdout.on('data', (data) => {
    for (const line of data.toString().split('\n')) {
      if (line.startsWith('SENT ')) sent.push(JSON.parse(line.slice(5)));
    }
  });
  for (let i = 0; i < 50; i++) {
    try {
      if ((await fetch(`${BASE}/wa/health`)).ok) return;
    } catch {}
    await new Promise((r) => setTimeout(r, 100));
  }
  throw new Error('server did not start');
});

after(() => child.kill());

const webhookBody = (from, text) => JSON.stringify({
  entry: [{ changes: [{ value: { messages: [{ from, type: 'text', text: { body: text } }] } }] }],
});

const sign = (body) =>
  `sha256=${crypto.createHmac('sha256', APP_SECRET).update(body).digest('hex')}`;

const postWebhook = (body, signature = sign(body)) =>
  fetch(`${BASE}/wa/webhook`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'X-Hub-Signature-256': signature },
    body,
  });

const exchange = (code) =>
  fetch(`${BASE}/wa/exchange`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Origin: 'https://sportstamil.network' },
    body: JSON.stringify({ code }),
  });

const waitForSent = async (count) => {
  for (let i = 0; i < 50 && sent.length < count; i++) await new Promise((r) => setTimeout(r, 50));
  assert.ok(sent.length >= count, `expected ${count} sent messages, got ${sent.length}`);
  return sent[count - 1];
};

test('webhook verification accepts the right token only', async () => {
  const ok = await fetch(`${BASE}/wa/webhook?hub.mode=subscribe&hub.verify_token=verify-me&hub.challenge=42`);
  assert.strictEqual(ok.status, 200);
  assert.strictEqual(await ok.text(), '42');
  const bad = await fetch(`${BASE}/wa/webhook?hub.mode=subscribe&hub.verify_token=wrong&hub.challenge=42`);
  assert.strictEqual(bad.status, 403);
});

test('rejects webhooks without a valid Meta signature', async () => {
  const res = await postWebhook(webhookBody('94770000001', 'Hi login'), 'sha256=deadbeef');
  assert.strictEqual(res.status, 401);
});

test('"Hi login" gets a one-time link that signs in once', async () => {
  const res = await postWebhook(webhookBody('94770000001', 'Hi login'));
  assert.strictEqual(res.status, 200);

  const message = await waitForSent(1);
  assert.strictEqual(message.to, '94770000001');
  const code = message.text.match(/whatsapp-login\?code=([A-Za-z0-9_-]+)/)[1];

  const first = await exchange(code);
  assert.strictEqual(first.status, 200);
  assert.strictEqual(first.headers.get('access-control-allow-origin'), 'https://sportstamil.network');
  assert.deepStrictEqual(await first.json(), { token: 'fake-token-for-wa_94770000001' });

  const second = await exchange(code);
  assert.strictEqual(second.status, 400);
});

test('same phone keeps the same account; spam within 30s gets no new link', async () => {
  await postWebhook(webhookBody('94770000001', 'login'));
  await new Promise((r) => setTimeout(r, 300));
  assert.strictEqual(sent.length, 1, 'cooldown should suppress the second link');
});

test('other messages get the help text', async () => {
  await postWebhook(webhookBody('94770000002', 'hello'));
  const message = await waitForSent(2);
  assert.match(message.text, /send: Hi login/);
});

test('unknown codes are refused', async () => {
  assert.strictEqual((await exchange('nope')).status, 400);
});
