const crypto = require('crypto');
const express = require('express');
const p = require('./pricing');
const { generateTravelReply } = require('./gemini-chat');

const wrap = fn => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);
const reference = prefix => `${prefix}-${crypto.randomUUID().toUpperCase()}`;
const dateString = value => typeof value === 'string' ? value.slice(0, 10) : new Intl.DateTimeFormat('en-CA', { timeZone: 'UTC', year: 'numeric', month: '2-digit', day: '2-digit' }).format(value);
function canChange(booking) {
  if (booking.status === 'cancelled') throw new p.ApiError(409, 'This booking is already cancelled');
  if (Date.parse(`${dateString(booking.booking_date)}T00:00:00+06:00`) - Date.now() < 86400000) {
    throw new p.ApiError(409, 'Bookings can only be changed or cancelled at least 24 hours before travel (Asia/Dhaka)');
  }
}
async function transaction(db, fn) {
  const connection = await db.getConnection();
  try { await connection.beginTransaction(); const result = await fn(connection); await connection.commit(); return result; }
  catch (err) { await connection.rollback(); throw err; }
  finally { connection.release(); }
}

function mountTravelApi(app, { db, requireAuth, requireAdmin, currentUserFromRequest }) {
  const router = express.Router();
  async function spot(id, connection = db) {
    const spotId = p.integer(id, 'spot_id', 1, 2147483647);
    const [rows] = await connection.query('SELECT s.*, d.name AS district_name FROM spots s LEFT JOIN districts d ON d.id=s.district_id WHERE s.id=?', [spotId]);
    if (!rows.length) throw new p.ApiError(404, 'Spot not found');
    return rows[0];
  }
  async function user(req) { return req.authUser || await currentUserFromRequest(req); }
  async function ownedBooking(conn, id, userId) {
    const [rows] = await conn.query('SELECT * FROM bookings WHERE id=? AND user_id=? FOR UPDATE', [p.integer(id, 'booking id', 1, 2147483647), userId]);
    if (!rows.length) throw new p.ApiError(404, 'Booking not found');
    return rows[0];
  }
  function bookingJson(booking) {
    return { ...booking, booking_date: dateString(booking.booking_date), currency: 'BDT', can_modify: booking.status !== 'cancelled' && Date.parse(`${dateString(booking.booking_date)}T00:00:00+06:00`) - Date.now() >= 86400000 };
  }
  router.get('/pricing', (req, res) => res.json({ currency: 'BDT', pricing_version: '2026-10-v1', districts: Object.keys(p.districtCoords).sort(), hotel_tiers: p.hotelTiers, food_tiers: p.foodTiers, guide_tiers: p.guideTiers, transport_modes: Object.keys(p.transportModes) }));
  router.post('/budget/estimate', wrap(async (req, res) => res.json({ estimate: p.estimate(await spot(req.body?.spot_id), req.body) })));
  router.post('/bookings/quote', wrap(async (req, res) => {
    const destination = await spot(req.body?.spot_id);
    const persons = p.integer(req.body?.persons, 'persons');
    const date = p.dateOnly(req.body?.booking_date);
    res.json({ quote: { spot_id: destination.id, spot_name: destination.name, persons, booking_date: date, total: p.packagePrice(destination, persons), currency: 'BDT', pricing_version: '2026-10-v1', note: 'FarReach package reservation only. No supplier payment, accommodation or transport reservation is included.' } });
  }));
  router.post('/bookings', requireAuth, wrap(async (req, res) => {
    const account = await user(req);
    const destination = await spot(req.body?.spot_id);
    const persons = p.integer(req.body?.persons, 'persons');
    const date = p.dateOnly(req.body?.booking_date);
    const price = p.packagePrice(destination, persons);
    const ref = reference('FR');
    // Lock the account row to serialize duplicate checks across workers.
    const id = await transaction(db, async conn => {
      await conn.query('SELECT id FROM users WHERE id=? FOR UPDATE', [account.id]);
      const [duplicates] = await conn.query("SELECT id FROM bookings WHERE user_id=? AND spot_id=? AND booking_date=? AND status!='cancelled'", [account.id, destination.id, date]);
      if (duplicates.length) throw new p.ApiError(409, 'You already have an active booking for this spot on this date');
      const [result] = await conn.query("INSERT INTO bookings (user_id,spot_id,type,target_name,price,booking_date,persons,status,reference,pricing_version) VALUES (?,?,'package',?,?,?,?,'confirmed',?,'2026-10-v1')", [account.id, destination.id, destination.name, price, date, persons, ref]);
      return result.insertId;
    });
    res.status(201).json({ ok: true, id, booking: bookingJson({ id, reference: ref, spot_id: destination.id, spot_name: destination.name, price, booking_date: date, persons, status: 'confirmed', pricing_version: '2026-10-v1' }) });
  }));
  router.get('/user/bookings', requireAuth, wrap(async (req, res) => {
    const account = await user(req);
    const [rows] = await db.query('SELECT b.*, COALESCE(s.name,b.target_name) AS spot_name FROM bookings b LEFT JOIN spots s ON s.id=b.spot_id WHERE b.user_id=? ORDER BY b.created_at DESC,b.id DESC', [account.id]);
    res.json({ bookings: rows.map(bookingJson) });
  }));
  router.get('/user/bookings/:id/ticket', requireAuth, wrap(async (req, res) => {
    const account = await user(req);
    const [rows] = await db.query('SELECT b.*, COALESCE(s.name,b.target_name) AS spot_name FROM bookings b LEFT JOIN spots s ON s.id=b.spot_id WHERE b.id=? AND b.user_id=?', [p.integer(req.params.id, 'booking id', 1, 2147483647), account.id]);
    if (!rows.length) throw new p.ApiError(404, 'Booking not found');
    const b = rows[0];
    res.json({ ticket: { ...bookingJson(b), traveler_name: account.name, valid: b.status === 'confirmed', note: 'FarReach reservation receipt. This is not an airline, rail, hotel, or attraction admission ticket.' } });
  }));
  router.put('/user/bookings/:id', requireAuth, wrap(async (req, res) => {
    const account = await user(req);
    const persons = p.integer(req.body?.persons, 'persons');
    const date = p.dateOnly(req.body?.booking_date);
    const booking = await transaction(db, async conn => {
      await conn.query('SELECT id FROM users WHERE id=? FOR UPDATE', [account.id]);
      const b = await ownedBooking(conn, req.params.id, account.id);
      canChange(b);
      const destination = await spot(b.spot_id, conn);
      const [duplicates] = await conn.query("SELECT id FROM bookings WHERE user_id=? AND spot_id=? AND booking_date=? AND status!='cancelled' AND id!=?", [account.id, b.spot_id, date, b.id]);
      if (duplicates.length) throw new p.ApiError(409, 'Another booking exists for this spot and date');
      const price = p.packagePrice(destination, persons);
      await conn.query('UPDATE bookings SET booking_date=?,persons=?,price=?,pricing_version=? WHERE id=?', [date, persons, price, '2026-10-v1', b.id]);
      return bookingJson({ ...b, booking_date: date, persons, price, spot_name: destination.name, pricing_version: '2026-10-v1' });
    });
    res.json({ ok: true, booking });
  }));
  router.delete('/user/bookings/:id', requireAuth, wrap(async (req, res) => {
    const account = await user(req);
    await transaction(db, async conn => {
      const b = await ownedBooking(conn, req.params.id, account.id);
      canChange(b);
      await conn.query("UPDATE bookings SET status='cancelled' WHERE id=? AND user_id=?", [b.id, account.id]);
    });
    res.json({ ok: true, message: 'Booking cancelled' });
  }));
  router.put('/admin/bookings/:id/status', requireAdmin, wrap(async (req, res) => {
    const status = p.choice(req.body?.status, 'status', { pending: 1, confirmed: 1, cancelled: 1 });
    const [result] = await db.query('UPDATE bookings SET status=? WHERE id=?', [status, p.integer(req.params.id, 'booking id', 1, 2147483647)]);
    if (!result.affectedRows) throw new p.ApiError(404, 'Booking not found');
    res.json({ ok: true });
  }));

  const categories = { general: 1, booking: 1, custom_trip: 1, account: 1, payment: 1 };
  async function ticket(req, admin = false, conn = db, lock = false) {
    const account = await user(req);
    const [rows] = await conn.query(`SELECT * FROM tickets WHERE id=? ${admin ? '' : 'AND user_id=?'}${lock ? ' FOR UPDATE' : ''}`, [p.integer(req.params.id, 'ticket id', 1, 2147483647), ...(admin ? [] : [account.id])]);
    if (!rows.length) throw new p.ApiError(404, 'Ticket not found');
    return rows[0];
  }
  router.post('/user/tickets', requireAuth, wrap(async (req, res) => {
    const account = await user(req);
    const subject = p.text(req.body?.subject, 'subject', 150);
    const description = p.text(req.body?.description, 'description', 5000);
    const category = p.choice(req.body?.category, 'category', categories, 'general');
    const bookingId = req.body?.booking_id == null ? null : p.integer(req.body.booking_id, 'booking_id', 1, 2147483647);
    const ref = reference('SUP');
    const result = await transaction(db, async conn => {
      await conn.query('SELECT id FROM users WHERE id=? FOR UPDATE', [account.id]);
      const [recent] = await conn.query('SELECT COUNT(*) AS count FROM tickets WHERE user_id=? AND created_at>DATE_SUB(UTC_TIMESTAMP(),INTERVAL 1 HOUR)', [account.id]);
      if (recent[0].count >= 10) throw new p.ApiError(429, 'You can create up to 10 tickets per hour');
      if (bookingId) await ownedBooking(conn, bookingId, account.id);
      if (category === 'booking' && !bookingId) throw new p.ApiError(400, 'Choose your booking for a booking ticket');
      const [insert] = await conn.query('INSERT INTO tickets (reference,user_id,booking_id,category,subject,description) VALUES (?,?,?,?,?,?)', [ref, account.id, bookingId, category, subject, description]);
      const [rows] = await conn.query('SELECT * FROM tickets WHERE id=?', [insert.insertId]);
      return rows[0];
    });
    res.status(201).json({ ok: true, ticket: result });
  }));
  for (const admin of [false, true]) {
    const root = admin ? '/admin/tickets' : '/user/tickets';
    const guard = admin ? requireAdmin : requireAuth;
    router.get(root, guard, wrap(async (req, res) => {
      const account = await user(req);
      const page = p.integer(req.query.page ?? 1, 'page', 1, 100000);
      const limit = p.integer(req.query.limit ?? 50, 'limit', 1, 100);
      const where = admin ? '' : 'WHERE user_id=?';
      const params = admin ? [] : [account.id];
      const [rows] = await db.query(`SELECT * FROM tickets ${where} ORDER BY updated_at DESC,id DESC LIMIT ? OFFSET ?`, [...params, limit, (page - 1) * limit]);
      const [[count]] = await db.query(`SELECT COUNT(*) AS total FROM tickets ${where}`, params);
      res.json({ tickets: rows, pagination: { page, limit, total: count.total } });
    }));
    router.get(`${root}/:id`, guard, wrap(async (req, res) => {
      const item = await ticket(req, admin);
      const [messages] = await db.query('SELECT m.id,m.message,m.created_at,m.user_id,u.name AS author_name,u.role AS author_role FROM ticket_messages m JOIN users u ON u.id=m.user_id WHERE m.ticket_id=? ORDER BY m.id', [item.id]);
      res.json({ ticket: item, messages });
    }));
    router.post(`${root}/:id/messages`, guard, wrap(async (req, res) => {
      const message = p.text(req.body?.message, 'message', 5000);
      const account = await user(req);
      await transaction(db, async conn => {
        const item = await ticket(req, admin, conn, true);
        if (['resolved', 'closed'].includes(item.status)) throw new p.ApiError(409, 'Reopen the ticket before replying');
        await conn.query('INSERT INTO ticket_messages (ticket_id,user_id,message) VALUES (?,?,?)', [item.id, account.id, message]);
        await conn.query('UPDATE tickets SET updated_at=UTC_TIMESTAMP() WHERE id=?', [item.id]);
      });
      res.status(201).json({ ok: true });
    }));
    router.put(`${root}/:id/status`, guard, wrap(async (req, res) => {
      const status = p.choice(req.body?.status, 'status', admin ? { open: 1, in_progress: 1, resolved: 1, closed: 1 } : { open: 1, closed: 1 });
      await transaction(db, async conn => {
        const item = await ticket(req, admin, conn, true);
        await conn.query('UPDATE tickets SET status=?,updated_at=UTC_TIMESTAMP() WHERE id=?', [status, item.id]);
      });
      res.json({ ok: true });
    }));
  }

  router.get('/chatbot/messages', requireAuth, wrap(async (req, res) => {
    const account = await user(req);
    const [rows] = await db.query('SELECT id,role,message,created_at FROM chat_messages WHERE user_id=? ORDER BY id DESC LIMIT 100', [account.id]);
    res.json({ messages: rows.reverse(), mode: process.env.GEMINI_API_KEY ? 'gemini-travel-assistant' : 'local-travel-assistant' });
  }));
  router.delete('/chatbot/messages', requireAuth, wrap(async (req, res) => {
    await db.query('DELETE FROM chat_messages WHERE user_id=?', [(await user(req)).id]);
    res.json({ ok: true });
  }));
  router.post('/chatbot/messages', requireAuth, wrap(async (req, res) => {
    const account = await user(req);
    const message = p.text(req.body?.message, 'message', 1000);
    const [[recent]] = await db.query("SELECT COUNT(*) AS count FROM chat_messages WHERE user_id=? AND role='user' AND created_at>DATE_SUB(UTC_TIMESTAMP(),INTERVAL 1 MINUTE)", [account.id]);
    if (recent.count >= 20) throw new p.ApiError(429, 'Please wait a minute before sending more messages');
    const lower = message.toLowerCase();
    let reply; let action = null;
    if (/ticket|support|help|custom|refund|payment/.test(lower)) {
      reply = 'Create a support ticket with a subject and details. For a custom trip, include destination, dates, traveler count, and budget. Your tickets appear in Profile → Tickets. FarReach does not collect payments or automatically issue refunds.';
      action = 'create_ticket';
    } else if (/cancel|reschedul|change.*book/.test(lower)) {
      reply = 'Open Profile → My bookings to change dates or traveler count, or cancel. Changes and cancellation are allowed at least 24 hours before midnight on the travel date in Asia/Dhaka. For later requests, create a booking support ticket.';
    } else if (/my.*book|receipt|reservation/.test(lower)) {
      const [[counts]] = await db.query("SELECT COUNT(*) AS count FROM bookings WHERE user_id=? AND status!='cancelled'", [account.id]);
      reply = `You have ${counts.count} active reservation(s). Open Profile → My bookings to view your reservation receipts and manage travel.`;
    } else if (/budget|cost|pric/.test(lower)) {
      reply = 'Open a destination → Budget calculator for a BDT estimate covering days, travelers, accommodation, food, guide, and travel from your origin district. Day trips have zero lodging nights. Package reservation prices are shown separately before confirmation.';
    } else if (/hotel|stay|accommodation/.test(lower)) {
      reply = 'Open a destination → Suggested stays. Prices are catalog estimates; room availability must be checked on the property website. FarReach has no live hotel inventory connection.';
    } else if (/password|login|account|profile/.test(lower)) {
      reply = 'Edit your name, phone and address from Profile → Edit profile. Changing your password requires your current password. Use Forgot password on the sign in screen if you cannot access your account.';
    } else if (/weather|safe/.test(lower)) {
      reply = 'Check the destination weather panel and local advisories before travel. Weather forecasts and travel conditions can change.';
    } else {
      // Escape LIKE wildcards so the user text is a literal catalog search.
      const query = message.replace(/[\\%_]/g, '\\$&');
      const [spots] = await db.query('SELECT s.name,d.name AS district FROM spots s LEFT JOIN districts d ON d.id=s.district_id WHERE s.name LIKE ? OR d.name LIKE ? ORDER BY s.name LIMIT 5', [`%${query}%`, `%${query}%`]);
      reply = spots.length ? `Destinations matching your search: ${spots.map(s => `${s.name} (${s.district})`).join('; ')}. Open Explore for details, stays, and pricing.` : 'I can help with destination names, stays, budgets, bookings, account access, and custom trip tickets. Ask about one of these or enter a district or destination name.';
    }
    let mode = 'local-travel-assistant';
    if (process.env.GEMINI_API_KEY) {
      const [historyRows] = await db.query('SELECT role,message FROM chat_messages WHERE user_id=? ORDER BY id DESC LIMIT 10', [account.id]);
      const words = [...new Set(message.toLowerCase().match(/[a-z]{3,}/g) || [])].slice(0, 5);
      let catalog = [];
      if (words.length) {
        const conditions = words.map(() => '(LOWER(s.name) LIKE ? OR LOWER(d.name) LIKE ?)').join(' OR ');
        const values = words.flatMap(word => [`%${word}%`, `%${word}%`]);
        const [rows] = await db.query(`SELECT s.name,d.name AS district FROM spots s LEFT JOIN districts d ON d.id=s.district_id WHERE ${conditions} ORDER BY s.name LIMIT 8`, values);
        catalog = rows.map(item => `${item.name} (${item.district})`);
      }
      const context = [
        catalog.length ? `Matching catalog destinations: ${catalog.join('; ')}` : 'No matching catalog destinations were found.',
        /my.*book|receipt|reservation/.test(lower) ? `This account's active reservation count is available in the local answer: ${reply}` : '',
      ].filter(Boolean).join('\n');
      try {
        const generated = await generateTravelReply({ message, history: historyRows.reverse(), context });
        reply = generated.reply;
        if (!generated.inScope) action = null;
        mode = 'gemini-travel-assistant';
      } catch (err) {
        console.error('[chatbot] Gemini unavailable:', err.message);
        throw new p.ApiError(503, 'Travel assistant is temporarily unavailable. Please try again.');
      }
    }
    await transaction(db, async conn => {
      await conn.query('SELECT id FROM users WHERE id=? FOR UPDATE', [account.id]);
      const [[recent]] = await conn.query("SELECT COUNT(*) AS count FROM chat_messages WHERE user_id=? AND role='user' AND created_at>DATE_SUB(UTC_TIMESTAMP(),INTERVAL 1 MINUTE)", [account.id]);
      if (recent.count >= 20) throw new p.ApiError(429, 'Please wait a minute before sending more messages');
      await conn.query("INSERT INTO chat_messages (user_id,role,message) VALUES (?,'user',?),(?,'assistant',?)", [account.id, message, account.id, reply]);
    });
    res.json({ reply, action, mode });
  }));
  router.use((err, req, res, next) => {
    if (!err.status) console.error('[travel-api]', err.message);
    res.status(err.status || 500).json({ error: err.status ? err.message : 'Unable to complete request' });
  });
  app.use('/api', router);
}
module.exports = { mountTravelApi, transaction, wrap };
