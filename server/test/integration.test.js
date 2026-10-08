const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { fork } = require('node:child_process');
const mysql = require('mysql2/promise');

test('FarReach API with real MySQL and independent server processes', { timeout: 120000 }, async t => {
  // Only this generated database is created or dropped; never use the app database.
  const database = `farreach_test_${crypto.randomBytes(8).toString('hex')}`;
  const config = { host: process.env.TEST_DB_HOST || '127.0.0.1', port: Number(process.env.TEST_DB_PORT || 3308), user: process.env.TEST_DB_USER || 'root', password: process.env.TEST_DB_PASSWORD || 'farreach-root-local-only', multipleStatements: true };
  const admin = await mysql.createConnection(config);
  let worker;
  t.after(async () => {
    if (worker && worker.exitCode === null) { worker.kill(); await new Promise(resolve => worker.once('exit', resolve)); }
    await admin.query(`DROP DATABASE IF EXISTS \`${database}\``);
    await admin.end();
  });
  await admin.query(`CREATE DATABASE \`${database}\``);
  await admin.query(`USE \`${database}\``);
  await admin.query(fs.readFileSync(path.join(__dirname, '../database.sql'), 'utf8'));
  const env = { ...process.env, NODE_ENV: 'development', DB_HOST: config.host, DB_PORT: String(config.port), DB_USER: config.user, DB_PASSWORD: config.password, DB_NAME: database, PORT: '0', SMTP_HOST: '', SMTP_USER: '', SMTP_PASS: '' };
  let base;
  async function start() {
    worker = fork(path.join(__dirname, 'http-worker.cjs'), [], { env, stdio: ['ignore', 'pipe', 'pipe', 'ipc'] });
    let logs = '';
    worker.stdout.on('data', data => logs += data);
    worker.stderr.on('data', data => logs += data);
    const port = await new Promise((resolve, reject) => {
      const timer = setTimeout(() => reject(new Error(`Server startup timed out: ${logs}`)), 40000);
      worker.once('message', m => { clearTimeout(timer); resolve(m.port); });
      worker.once('exit', code => { clearTimeout(timer); reject(new Error(`Server exited ${code}: ${logs}`)); });
    });
    base = `http://127.0.0.1:${port}`;
  }
  await start();
  async function call(method, route, body, token, expected = 200) {
    const result = await fetch(base + route, { method, headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) }, ...(body === undefined ? {} : { body: JSON.stringify(body) }) });
    const payload = await result.json();
    assert.equal(result.status, expected, `${method} ${route}: ${JSON.stringify(payload)}`);
    return payload;
  }
  const password = 'FarReach-test-password-42';
  let alice, bob, staff, spot, booking, support;
  const future = days => new Date(Date.now() + days * 86400000).toISOString().slice(0, 10);
  async function signup(email, name) {
    const start = await call('POST', '/api/auth/signup/start', { email, name });
    const verify = await call('POST', '/api/auth/signup/verify-code', { email, code: start.previewCode });
    await call('POST', '/api/auth/signup/set-password', { email, name, password }, null, 403);
    return call('POST', '/api/auth/signup/set-password', { email, name, password, verificationToken: verify.verificationToken });
  }
  await t.test('OTP registration requires a session proof and does not leak password hashes', async () => {
    alice = await signup('alice@example.test', 'Alice');
    bob = await signup('bob@example.test', 'Bob');
    staff = await signup('staff@example.test', 'Support');
    await admin.query("UPDATE users SET role='admin' WHERE id=?", [staff.user.id]);
    assert.equal(alice.user.is_verified, true);
    assert.equal(alice.user.password_hash, undefined);
    const [[session]] = await admin.query('SELECT token_hash FROM auth_sessions WHERE user_id=?', [alice.user.id]);
    assert.notEqual(session.token_hash, alice.token);
    await call('GET', '/api/auth/me', undefined, null, 401);
    await call('POST', '/api/auth/login', { email: 'alice@example.test', password: 'wrong' }, null, 401);
    await call('POST', '/api/auth/login', { email: [], password: {} }, null, 400);
    await call('POST', '/api/auth/signup/start', { email: 'alice@example.test', name: 'Alice' }, null, 429);
  });
  await t.test('sessions survive an actual Node process restart and logout revokes them', async () => {
    worker.kill(); await new Promise(resolve => worker.once('exit', resolve));
    await start();
    const me = await call('GET', '/api/auth/me', undefined, alice.token);
    assert.equal(me.user.id, alice.user.id);
    const login = await call('POST', '/api/auth/login', { email: 'alice@example.test', password });
    await call('POST', '/api/auth/logout', {}, login.token);
    await call('GET', '/api/auth/me', undefined, login.token, 401);
  });
  await t.test('budget pricing covers day trips, shared guides, validation and server package quotes', async () => {
    const spots = await call('GET', '/api/spots');
    spot = spots.spots.find(s => s.district_name === 'Dhaka');
    assert.ok(spot);
    const { estimate } = await call('POST', '/api/budget/estimate', { spot_id: spot.id, origin: 'Dhaka', persons: 2, days: 1, guide_tier: 'local' });
    assert.equal(estimate.nights, 0);
    assert.equal(estimate.breakdown.accommodation, 0);
    assert.equal(estimate.breakdown.guide, 600);
    assert.equal(estimate.breakdown.round_trip_transport, 0);
    assert.equal(estimate.total, Object.values(estimate.breakdown).reduce((a,b) => a+b, 0));
    await call('POST', '/api/budget/estimate', { spot_id: spot.id, days: 0 }, null, 400);
    await call('POST', '/api/budget/estimate', { spot_id: spot.id, persons: null }, null, 400);
    await call('POST', '/api/budget/estimate', { spot_id: spot.id, origin: 'Unknown' }, null, 400);
    await call('POST', '/api/budget/estimate', { spot_id: spot.id, hotel_tier: '__proto__' }, null, 400);
    const result = await call('POST', '/api/bookings/quote', { spot_id: spot.id, persons: 2, booking_date: future(10) });
    assert.equal(result.quote.total, estimate.package_total);
    await call('POST', '/api/bookings/quote', { spot_id: spot.id, persons: 2, booking_date: '2027-02-30' }, null, 400);
  });
  await t.test('stays expose unknown inventory and truthful date and room estimates', async () => {
    const result = await call('POST', '/api/hotels/search', { city: 'Dhaka', persons: 3, checkin: future(10), checkout: future(12) });
    assert.equal(result.live_availability, false);
    assert.equal(result.rooms, 2);
    assert.equal(result.nights, 2);
    assert.ok(result.hotels.every(h => h.availability === 'unknown' && h.total_estimate === h.price * 4));
    await call('POST', '/api/hotels/search', { city: 'Dhaka', checkin: '2027-02-30', checkout: '2027-03-02' }, null, 400);
    await call('POST', '/api/hotels/search', { city: 'Dhaka', checkin: future(10), checkout: future(9) }, null, 400);
    const cheap = await call('POST', '/api/hotels/search', { city: 'Dhaka', max_price: 1 });
    assert.deepEqual(cheap.hotels, []);
  });
  await t.test('concurrent bookings cannot bypass duplicate detection or submit their own price', async () => {
    const body = { spot_id: spot.id, booking_date: future(10), persons: 2, price: 1 };
    const results = await Promise.all(Array.from({length: 4}, () => fetch(base + '/api/bookings', { method: 'POST', headers: { 'Content-Type':'application/json', Authorization: `Bearer ${alice.token}` }, body: JSON.stringify(body) })));
    assert.deepEqual(results.map(r => r.status).sort(), [201,409,409,409]);
    booking = (await results.find(r => r.status === 201).json()).booking;
    assert.notEqual(booking.price, 1);
    assert.ok(booking.reference.startsWith('FR-'));
    await call('POST', '/api/bookings', { ...body, persons: 21 }, alice.token, 400);
    await call('GET', `/api/user/bookings/${booking.id}/ticket`, undefined, bob.token, 404);
  });
  await t.test('booking changes reprice and cancellation invalidates the receipt', async () => {
    const changed = await call('PUT', `/api/user/bookings/${booking.id}`, { booking_date: future(12), persons: 3 }, alice.token);
    assert.equal(changed.booking.price, booking.price / 2 * 3);
    // More concurrent writers than pool slots must not wait for a second connection inside a transaction.
    const changes = await Promise.all(Array.from({length:12}, () => call('PUT', `/api/user/bookings/${booking.id}`, { booking_date: future(12), persons: 3 }, alice.token)));
    assert.equal(changes.length, 12);
    await call('PUT', `/api/user/bookings/${booking.id}`, { booking_date: future(12), persons: 3 }, bob.token, 404);
    const receipt = await call('GET', `/api/user/bookings/${booking.id}/ticket`, undefined, alice.token);
    assert.equal(receipt.ticket.valid, true);
    assert.equal(receipt.ticket.traveler_name, 'Alice');
    await call('DELETE', `/api/user/bookings/${booking.id}`, undefined, alice.token);
    assert.equal((await call('GET', `/api/user/bookings/${booking.id}/ticket`, undefined, alice.token)).ticket.valid, false);
    await call('DELETE', `/api/user/bookings/${booking.id}`, undefined, alice.token, 409);
    const another = await call('POST', '/api/bookings', {spot_id:spot.id, booking_date:future(15), persons:1}, alice.token, 201);
    await admin.query('UPDATE bookings SET booking_date=? WHERE id=?', [future(0), another.id]);
    await call('DELETE', `/api/user/bookings/${another.id}`, undefined, alice.token, 409);
  });
  await t.test('saved spots are idempotent and isolated to each account', async () => {
    await call('POST','/api/user/saved-spots',{spot_id:spot.id},alice.token,201);
    const repeat = await call('POST','/api/user/saved-spots',{spot_id:spot.id},alice.token);
    assert.equal(repeat.created,false);
    assert.equal((await call('GET','/api/user/saved-spots',undefined,bob.token)).spots.length,0);
    await call('DELETE',`/api/user/saved-spots/${spot.id}`,undefined,bob.token);
    assert.equal((await call('GET','/api/user/saved-spots',undefined,alice.token)).spots.length,1);
    await call('DELETE',`/api/user/saved-spots/${spot.id}`,undefined,alice.token);
  });
  await t.test('custom tickets, account ownership and admin reply/status workflow', async () => {
    support = (await call('POST','/api/user/tickets',{category:'custom_trip',subject:'Sylhet trip',description:'Three travelers, two days, budget 15000 BDT'},alice.token,201)).ticket;
    await call('GET',`/api/user/tickets/${support.id}`,undefined,bob.token,404);
    await call('GET','/api/admin/tickets',undefined,alice.token,403);
    await call('POST','/api/user/tickets',{category:'booking',subject:'Help',description:'Booking help'},alice.token,400);
    await call('POST',`/api/admin/tickets/${support.id}/messages`,{message:'Please provide your preferred dates.'},staff.token,201);
    await call('PUT',`/api/admin/tickets/${support.id}/status`,{status:'in_progress'},staff.token);
    await call('POST',`/api/user/tickets/${support.id}/messages`,{message:'November 20–21.'},alice.token,201);
    const detail = await call('GET',`/api/user/tickets/${support.id}`,undefined,alice.token);
    assert.equal(detail.messages.length,2);
    await call('PUT',`/api/user/tickets/${support.id}/status`,{status:'resolved'},alice.token,400);
    await call('PUT',`/api/admin/tickets/${support.id}/status`,{status:'resolved'},staff.token);
    await call('POST',`/api/user/tickets/${support.id}/messages`,{message:'More info'},alice.token,409);
    await call('PUT',`/api/user/tickets/${support.id}/status`,{status:'open'},alice.token);
    await call('PUT',`/api/user/tickets/${support.id}/status`,{status:'closed'},alice.token);
    assert.equal((await call('GET','/api/user/tickets',undefined,bob.token)).tickets.length,0);
  });
  await t.test('chat responses are grounded, persisted and scoped to the signed in account', async () => {
    const chat = await call('POST','/api/chatbot/messages',{message:'I need a custom trip ticket'},alice.token);
    assert.equal(chat.action,'create_ticket');
    assert.equal((await call('GET','/api/chatbot/messages',undefined,alice.token)).messages.length,2);
    assert.equal((await call('GET','/api/chatbot/messages',undefined,bob.token)).messages.length,0);
    assert.equal((await call('GET','/api/user/tickets',undefined,alice.token)).tickets.length,1);
    await call('POST','/api/chatbot/messages',{message:[]},alice.token,400);
    const search = await call('POST','/api/chatbot/messages',{message:'Dhaka'},alice.token);
    assert.match(search.reply,/Destinations matching/);
    await call('DELETE','/api/chatbot/messages',undefined,alice.token);
    assert.equal((await call('GET','/api/chatbot/messages',undefined,alice.token)).messages.length,0);
  });
  await t.test('profile validation and password changes revoke other sessions', async () => {
    const second = await call('POST','/api/auth/login',{email:'alice@example.test',password});
    await call('PUT','/api/auth/profile',{name:'  '},alice.token,400);
    const profile = await call('PUT','/api/auth/profile',{name:'Alice Updated',phone:'+880 1700000000',address:'Dhaka'},alice.token);
    assert.equal(profile.user.name,'Alice Updated');
    await call('PUT','/api/auth/profile',{password:'Replacement-Password-43',current_password:'wrong'},alice.token,403);
    await call('PUT','/api/auth/profile',{password:'Replacement-Password-43',current_password:password},alice.token);
    await call('GET','/api/auth/me',undefined,second.token,401);
    await call('GET','/api/auth/me',undefined,alice.token);
  });
  await t.test('password reset codes are limited, consumed once and revoke all sessions', async () => {
    const result = await call('POST','/api/auth/password-reset/start',{email:'alice@example.test'});
    const code = result.previewCode;
    assert.match(code,/^\d{6}$/);
    const wrong = code === '111111' ? '222222' : '111111';
    await call('POST','/api/auth/password-reset/complete',{email:'alice@example.test',code:wrong,password:'Reset-password-44'},null,400);
    const [[row]] = await admin.query('SELECT failed_attempts,code_hash FROM password_resets WHERE email=?',['alice@example.test']);
    assert.equal(row.failed_attempts,1);
    assert.notEqual(row.code_hash,code);
    await call('POST','/api/auth/password-reset/complete',{email:'alice@example.test',code,password:'Reset-password-44'});
    await call('GET','/api/auth/me',undefined,alice.token,401);
    await call('POST','/api/auth/password-reset/complete',{email:'alice@example.test',code,password:'Reset-password-44'},null,400);
    await call('POST','/api/auth/login',{email:'alice@example.test',password:'Reset-password-44'});
    const unknown = await call('POST','/api/auth/password-reset/start',{email:'missing@example.test'});
    assert.equal(unknown.previewCode,undefined);
  });
  await t.test('invalid JSON is handled without terminating the process', async () => {
    const r = await fetch(base+'/api/auth/login',{method:'POST',headers:{'Content-Type':'application/json'},body:'{bad'});
    assert.equal(r.status,400);
    assert.match((await r.json()).error,/Invalid JSON/);
    assert.equal((await call('GET','/api/health')).ok,true);
  });
  await t.test('reset guess limits and session expiration fail closed', async () => {
    const result = await call('POST','/api/auth/password-reset/start',{email:'bob@example.test'});
    const wrong = result.previewCode === '111111' ? '222222' : '111111';
    for (let i=0; i<5; i++) await call('POST','/api/auth/password-reset/complete',{email:'bob@example.test',code:wrong,password:'Reset-test-password'},null,400);
    await call('POST','/api/auth/password-reset/complete',{email:'bob@example.test',code:result.previewCode,password:'Reset-test-password'},null,429);
    await admin.query('UPDATE password_resets SET expires_at=DATE_SUB(UTC_TIMESTAMP(),INTERVAL 1 MINUTE) WHERE email=?',['bob@example.test']);
    await call('POST','/api/auth/password-reset/complete',{email:'bob@example.test',code:result.previewCode,password:'Reset-test-password'},null,400);
    const expired = await call('POST','/api/auth/login',{email:'bob@example.test',password});
    await admin.query('UPDATE auth_sessions SET expires_at=DATE_SUB(UTC_TIMESTAMP(),INTERVAL 1 DAY) WHERE token_hash=?', [crypto.createHash('sha256').update(expired.token).digest('hex')]);
    await call('GET','/api/auth/me',undefined,expired.token,401);
  });
  await t.test('production never falls back to development OTP previews', async () => {
    worker.kill(); await new Promise(resolve => worker.once('exit',resolve));
    env.NODE_ENV = 'production';
    await start();
    const signup = await call('POST','/api/auth/signup/start',{email:'production@example.test',name:'Production'},null,503);
    assert.equal(signup.previewCode,undefined);
    const reset = await call('POST','/api/auth/password-reset/start',{email:'staff@example.test'},null,503);
    assert.equal(reset.previewCode,undefined);
    const [[count]] = await admin.query('SELECT COUNT(*) AS count FROM otp_verifications WHERE email=?',['production@example.test']);
    assert.equal(count.count,0);
  });
});
