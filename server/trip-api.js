const crypto = require('crypto');
const express = require('express');
const p = require('./pricing');
const { transaction, wrap } = require('./travel-api');

const services = { package: 1, hotel: 1, flight: 1, transport: 1 };
const providers = {
  farreach: { id: 'farreach', name: 'FarReach travel team', mode: 'operator_request', request_enabled: true, live_booking: false },
  trip_com: { id: 'trip_com', name: 'Trip.com', mode: 'external_website', request_enabled: true, live_booking: false, website: 'https://www.trip.com/', documentation: 'https://developer.trip.com/' },
  gozayaan: { id: 'gozayaan', name: 'GoZayaan', mode: 'external_website', request_enabled: true, live_booking: false, website: 'https://www.gozayaan.com/' },
};
const MAX_MONEY = 1000000000;
function input(body) {
  const service = p.choice(body?.service, 'service', services, 'package');
  const provider = p.choice(body?.provider, 'provider', providers, 'farreach');
  const origin = p.text(body?.origin, 'origin', 150);
  const destination = p.text(body?.destination, 'destination', 150);
  const start_date = p.dateOnly(body?.start_date, 'start_date');
  const end_date = p.dateOnly(body?.end_date, 'end_date');
  const days = (Date.parse(end_date) - Date.parse(start_date)) / 86400000;
  if (days < 0 || days > 30 || (service === 'hotel' && days === 0)) throw new p.ApiError(400, 'Choose ordered travel dates, up to 30 nights; hotels need at least one night');
  const adults = p.integer(body?.adults, 'adults', 1, 20);
  const children = p.integer(body?.children === undefined ? 0 : body.children, 'children', 0, 19);
  if (adults + children > 20) throw new p.ApiError(400, 'A trip can have at most 20 travelers');
  const budget_paisa = body?.budget_paisa == null ? null : p.integer(body.budget_paisa, 'budget_paisa', 100, MAX_MONEY);
  const contact_name = p.text(body?.contact_name, 'contact_name', 100);
  const contact_phone = p.text(body?.contact_phone, 'contact_phone', 30);
  if (!/^\+?[0-9 ()-]{7,30}$/.test(contact_phone) || contact_phone.replace(/\D/g, '').length < 7) throw new p.ApiError(400, 'Enter a valid contact phone');
  const requirements = body?.requirements === undefined ? '' : p.text(body.requirements, 'requirements', 5000, false);
  return { service, provider, origin, destination, start_date, end_date, adults, children, budget_paisa, contact_name, contact_phone, requirements };
}
function quoteInput(body, trip) {
  if (!Array.isArray(body?.line_items) || body.line_items.length < 1 || body.line_items.length > 20) throw new p.ApiError(400, 'Supply 1–20 quote line items');
  const line_items = body.line_items.map(item => ({
    label: p.text(item?.label, 'line item label', 150),
    quantity: p.integer(item?.quantity, 'quantity', 1, 100),
    unit_paisa: p.integer(item?.unit_paisa, 'unit_paisa', 1, MAX_MONEY),
  }));
  const total_paisa = line_items.reduce((sum, item) => sum + item.quantity * item.unit_paisa, 0);
  if (total_paisa > MAX_MONEY) throw new p.ApiError(400, 'Quote total exceeds the supported amount');
  const itinerary = p.text(body?.itinerary, 'itinerary', 10000);
  const cancellation_policy = p.text(body?.cancellation_policy, 'cancellation_policy', 5000);
  const hours = p.integer(body?.valid_hours === undefined ? 24 : body.valid_hours, 'valid_hours', 1, 168);
  const expires_at = new Date(Math.min(Date.now() + hours * 3600000, Date.parse(`${trip.start_date}T00:00:00+06:00`)));
  if (expires_at.getTime() <= Date.now()) throw new p.ApiError(409, 'Travel has already started; this request cannot be quoted');
  return { line_items, total_paisa, itinerary, cancellation_policy, expires_at };
}
function tripJson(row) {
  const { request_key, payload_hash, user_id, ...trip } = row;
  return { ...trip, currency: 'BDT', fulfillment: 'operator_managed', payment_status: 'not_collected', live_supplier_booking: false };
}
function quoteJson(row) {
  const { operator_id, ...quote } = row;
  return { ...quote, currency: 'BDT', line_items: typeof row.line_items === 'string' ? JSON.parse(row.line_items) : row.line_items,
    expired: new Date(row.expires_at).getTime() <= Date.now(), inventory_held: false };
}

function mountTripApi(app, { db, requireAuth, requireAdmin, currentUserFromRequest }) {
  const router = express.Router();
  const account = req => req.authUser || currentUserFromRequest(req);
  async function getTrip(conn, req, admin = false, lock = false) {
    const user = await account(req);
    const id = p.integer(req.params.id, 'trip id', 1, 2147483647);
    const [[trip]] = await conn.query(`SELECT * FROM trip_requests WHERE id=?${admin ? '' : ' AND user_id=?'}${lock ? ' FOR UPDATE' : ''}`, [id, ...(admin ? [] : [user.id])]);
    if (!trip) throw new p.ApiError(404, 'Trip request not found');
    return trip;
  }
  function version(req, trip) {
    if (p.integer(req.body?.version, 'version', 1, 2147483647) !== trip.version) throw new p.ApiError(409, 'This trip was updated. Refresh and review it before continuing');
  }
  async function event(conn, trip, user, name, message, admin = false) {
    await conn.query('INSERT INTO trip_events (trip_id,actor_id,actor_role,event,message) VALUES (?,?,?,?,?)', [trip.id, user.id, admin ? 'operator' : 'traveler', name, message]);
  }
  async function update(conn, trip, status) {
    await conn.query('UPDATE trip_requests SET status=?,version=version+1 WHERE id=?', [status, trip.id]);
    const [[next]] = await conn.query('SELECT * FROM trip_requests WHERE id=?', [trip.id]);
    return tripJson(next);
  }
  async function mutate(req, admin, fn) {
    const user = await account(req);
    return transaction(db, async conn => {
      const trip = await getTrip(conn, req, admin, true);
      version(req, trip);
      return fn(conn, trip, user);
    });
  }
  router.get('/travel/providers', (req, res) => res.json({ providers: Object.values(providers), currency: 'BDT', note: 'Provider preference is sent to the FarReach team. External suppliers are not connected for API booking.' }));
  router.post('/trip-requests', requireAuth, wrap(async (req, res) => {
    const user = await account(req);
    const payload = input(req.body);
    const key = req.get('Idempotency-Key');
    if (typeof key !== 'string' || !/^[a-zA-Z0-9_-]{16,100}$/.test(key)) throw new p.ApiError(400, 'Supply an Idempotency-Key header of 16–100 letters, digits, underscores or hyphens');
    const hash = crypto.createHash('sha256').update(JSON.stringify(payload)).digest('hex');
    const result = await transaction(db, async conn => {
      // Serialize retries and the durable daily quota across all API processes.
      await conn.query('SELECT id FROM users WHERE id=? FOR UPDATE', [user.id]);
      const [[previous]] = await conn.query('SELECT * FROM trip_requests WHERE user_id=? AND request_key=?', [user.id, key]);
      if (previous) {
        if (previous.payload_hash !== hash) throw new p.ApiError(409, 'This request key was used with different trip details');
        return { trip: tripJson(previous), replayed: true };
      }
      const [[recent]] = await conn.query('SELECT COUNT(*) AS count FROM trip_requests WHERE user_id=? AND created_at>DATE_SUB(UTC_TIMESTAMP(3),INTERVAL 1 DAY)', [user.id]);
      if (recent.count >= 10) throw new p.ApiError(429, 'You can submit up to 10 trip requests per day');
      const ref = `TR-${crypto.randomUUID().toUpperCase()}`;
      const values = [ref, user.id, key, hash, ...Object.values(payload)];
      const [insert] = await conn.query(`INSERT INTO trip_requests (reference,user_id,request_key,payload_hash,service,provider,origin,destination,start_date,end_date,adults,children,budget_paisa,contact_name,contact_phone,requirements) VALUES (${values.map(() => '?').join(',')})`, values);
      const [[trip]] = await conn.query('SELECT * FROM trip_requests WHERE id=?', [insert.insertId]);
      await event(conn, trip, user, 'requested', 'Trip request submitted to the FarReach travel team. No supplier reservation or payment has been made.');
      return { trip: tripJson(trip), replayed: false };
    });
    res.status(result.replayed ? 200 : 201).json(result);
  }));

  for (const admin of [false, true]) {
    const root = admin ? '/admin/trip-requests' : '/user/trip-requests';
    const guard = admin ? requireAdmin : requireAuth;
    router.get(root, guard, wrap(async (req, res) => {
      const user = await account(req);
      const page = p.integer(req.query.page === undefined ? 1 : req.query.page, 'page', 1, 100000);
      const limit = p.integer(req.query.limit === undefined ? 25 : req.query.limit, 'limit', 1, 100);
      const status = req.query.status === undefined ? null : p.choice(req.query.status, 'status', { requested: 1, quoted: 1, awaiting_confirmation: 1, confirmed: 1, cancellation_requested: 1, cancelled: 1, rejected: 1 });
      const where = `${admin ? '1=1' : 'user_id=?'}${status ? ' AND status=?' : ''}`;
      const args = [...(admin ? [] : [user.id]), ...(status ? [status] : [])];
      const [rows] = await db.query(`SELECT * FROM trip_requests WHERE ${where} ORDER BY id DESC LIMIT ? OFFSET ?`, [...args, limit, (page - 1) * limit]);
      const [[count]] = await db.query(`SELECT COUNT(*) AS total FROM trip_requests WHERE ${where}`, args);
      res.json({ trips: rows.map(tripJson), pagination: { page, limit, total: count.total } });
    }));
    router.get(`${root}/:id`, guard, wrap(async (req, res) => {
      // A consistent snapshot prevents mixing a new quote with an old trip version.
      const detail = await transaction(db, async conn => {
        const trip = await getTrip(conn, req, admin);
        const [quotes] = await conn.query('SELECT * FROM trip_quotes WHERE trip_id=? ORDER BY id DESC LIMIT 100', [trip.id]);
        const [events] = await conn.query('SELECT id,actor_role,event,message,created_at FROM trip_events WHERE trip_id=? ORDER BY id DESC LIMIT 100', [trip.id]);
        return { trip: tripJson(trip), quotes: quotes.map(quoteJson), events: events.reverse() };
      });
      res.json(detail);
    }));
  }
  router.post('/admin/trip-requests/:id/quotes', requireAdmin, wrap(async (req, res) => {
    const result = await mutate(req, true, async (conn, trip, user) => {
      if (!['requested', 'quoted'].includes(trip.status)) throw new p.ApiError(409, 'Only requested or quoted trips can receive a new quote');
      const quote = quoteInput(req.body, trip);
      const [insert] = await conn.query('INSERT INTO trip_quotes (trip_id,operator_id,line_items,total_paisa,itinerary,cancellation_policy,expires_at) VALUES (?,?,?,?,?,?,?)', [trip.id, user.id, JSON.stringify(quote.line_items), quote.total_paisa, quote.itinerary, quote.cancellation_policy, quote.expires_at]);
      await conn.query('UPDATE trip_requests SET current_quote_id=? WHERE id=?', [insert.insertId, trip.id]);
      await event(conn, trip, user, 'quoted', 'A new itemized quote is available. Review the itinerary, terms and expiry before accepting.', true);
      const next = await update(conn, trip, 'quoted');
      const [[row]] = await conn.query('SELECT * FROM trip_quotes WHERE id=?', [insert.insertId]);
      return { trip: next, quote: quoteJson(row) };
    });
    res.status(201).json(result);
  }));
  router.post('/user/trip-requests/:id/accept', requireAuth, wrap(async (req, res) => {
    const trip = await mutate(req, false, async (conn, trip, user) => {
      if (trip.status !== 'quoted') throw new p.ApiError(409, 'This trip has no quote available for acceptance');
      if (req.body?.accept_terms !== true) throw new p.ApiError(400, 'Accept the quote and cancellation terms to continue');
      const quoteId = p.integer(req.body?.quote_id, 'quote_id', 1, 2147483647);
      if (quoteId !== trip.current_quote_id) throw new p.ApiError(409, 'The quote changed. Review the latest quote');
      const [[quote]] = await conn.query('SELECT * FROM trip_quotes WHERE id=? AND trip_id=? FOR UPDATE', [quoteId, trip.id]);
      if (!quote || new Date(quote.expires_at).getTime() <= Date.now() || trip.start_date <= p.today()) throw new p.ApiError(409, 'This quote expired; request a fresh quote from the team');
      await conn.query('UPDATE trip_quotes SET accepted_at=UTC_TIMESTAMP(3) WHERE id=?', [quoteId]);
      await event(conn, trip, user, 'quote_accepted', 'Quote and cancellation terms accepted. Awaiting supplier confirmation; no payment collected.');
      return update(conn, trip, 'awaiting_confirmation');
    });
    res.json({ trip });
  }));
  router.post('/admin/trip-requests/:id/confirm', requireAdmin, wrap(async (req, res) => {
    const trip = await mutate(req, true, async (conn, trip, user) => {
      if (trip.status !== 'awaiting_confirmation') throw new p.ApiError(409, 'Customer acceptance is required before confirmation');
      if (trip.start_date <= p.today()) throw new p.ApiError(409, 'Travel has already started');
      const supplier = p.text(req.body?.supplier_reference, 'supplier_reference', 100);
      const details = p.text(req.body?.confirmation_details, 'confirmation_details', 10000);
      await conn.query('UPDATE trip_requests SET supplier_reference=?,confirmation_details=? WHERE id=?', [supplier, details, trip.id]);
      await event(conn, trip, user, 'confirmed', 'The travel team recorded supplier confirmation. See the confirmation details and reference.', true);
      return update(conn, trip, 'confirmed');
    });
    res.json({ trip });
  }));
  router.post('/user/trip-requests/:id/cancel', requireAuth, wrap(async (req, res) => {
    const trip = await mutate(req, false, async (conn, trip, user) => {
      if (!['requested', 'quoted', 'awaiting_confirmation', 'confirmed'].includes(trip.status)) throw new p.ApiError(409, 'This trip cannot be cancelled in its current state');
      const reason = p.text(req.body?.reason, 'reason', 1000);
      const status = trip.status === 'confirmed' ? 'cancellation_requested' : 'cancelled';
      await event(conn, trip, user, status, reason);
      return update(conn, trip, status);
    });
    res.json({ trip });
  }));
  router.post('/admin/trip-requests/:id/close', requireAdmin, wrap(async (req, res) => {
    const trip = await mutate(req, true, async (conn, trip, user) => {
      const status = p.choice(req.body?.status, 'status', { rejected: 1, cancelled: 1 });
      const allowed = status === 'cancelled' ? ['cancellation_requested'] : ['requested', 'quoted', 'awaiting_confirmation'];
      if (!allowed.includes(trip.status)) throw new p.ApiError(409, 'This transition is not allowed');
      const reason = p.text(req.body?.reason, 'reason', 5000);
      await event(conn, trip, user, status, reason, true);
      return update(conn, trip, status);
    });
    res.json({ trip });
  }));
  router.use((err, req, res, next) => {
    if (!err.status) console.error('[trip-api]', err.message);
    res.status(err.status || 500).json({ error: err.status ? err.message : 'Unable to complete trip request', code: err.status === 409 ? 'TRIP_CONFLICT' : err.status ? 'TRIP_REQUEST_ERROR' : 'INTERNAL_ERROR' });
  });
  app.use('/api', router);
}
module.exports = { mountTripApi, input, quoteInput };
