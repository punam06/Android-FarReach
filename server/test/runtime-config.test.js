const { test } = require('node:test');
const assert = require('node:assert/strict');
const { runtimeConfig, securityMiddleware } = require('../runtime-config');
const production = { NODE_ENV: 'production', DB_HOST: 'db', DB_NAME: 'farreach', DB_USER: 'farreach', DB_PASSWORD: 'a-long-test-password-only', APP_API_BASE_URL: 'https://api.example.test', CORS_ORIGINS: 'https://app.example.test', SMTP_HOST: 'smtp.example.test', SMTP_USER: 'test', SMTP_PASS: 'test', SMTP_FROM: 'FarReach <test@example.test>' };
test('production configuration rejects missing secrets, development credentials and wildcard CORS', () => {
  assert.throws(() => runtimeConfig({ NODE_ENV: 'production' }));
  assert.throws(() => runtimeConfig({ ...production, DB_USER: 'root' }));
  assert.throws(() => runtimeConfig({ ...production, DB_PASSWORD: 'farreach-local-only' }));
  assert.throws(() => runtimeConfig({ ...production, CORS_ORIGINS: '*' }));
  assert.throws(() => runtimeConfig({ ...production, APP_API_BASE_URL: 'http://api.example.test' }));
  assert.equal(runtimeConfig(production).production, true);
});
test('production CORS blocks unknown web origins and permits native clients without an Origin', () => {
  const middleware = securityMiddleware(runtimeConfig(production));
  function run(origin) {
    const headers = {}; let status = 200, next = false;
    const res = { setHeader: (k,v) => headers[k] = v, vary: () => {}, status: s => { status = s; return res; }, json: () => res };
    middleware({ get: () => origin, path: '/api/trip-requests', method: 'POST' }, res, () => next = true);
    return { headers, status, next };
  }
  assert.equal(run('https://evil.example.test').status, 403);
  assert.equal(run(undefined).next, true);
  const allowed = run('https://app.example.test');
  assert.equal(allowed.headers['Access-Control-Allow-Origin'], 'https://app.example.test');
  assert.equal(allowed.headers['Cache-Control'], 'no-store');
  assert.equal(allowed.next, true);
});
