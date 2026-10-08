const crypto = require('crypto');
const express = require('express');
const { ApiError, text } = require('./pricing');
const { wrap, transaction } = require('./travel-api');
const digest = value => crypto.createHash('sha256').update(value).digest('hex');
function mountAccountApi(app, { db, requireAuth, currentUserFromRequest, publicUser, upload, isValidPassword, hashPassword, verifyPassword, getAuthToken, sendVerificationMail, reserveOtpRequest, sendRateLimitResponse, isDevelopmentMode }) {
  const router = express.Router();
  router.put('/auth/profile', requireAuth, upload.single('profile_pic'), wrap(async (req, res) => {
    const account = await currentUserFromRequest(req);
    const body = req.body || {};
    const name = body.name === undefined ? account.name : text(body.name, 'name', 100);
    const phone = body.phone === undefined ? account.phone || '' : text(body.phone, 'phone', 20, false);
    const address = body.address === undefined ? account.address || '' : text(body.address, 'address', 1000, false);
    if (phone && !/^[+\d() .-]{5,20}$/.test(phone)) throw new ApiError(400, 'Enter a valid phone number');
    const passwordChange = body.password !== undefined && body.password !== '';
    if (passwordChange && !isValidPassword(body.password)) throw new ApiError(400, 'Password must be at least 8 characters and at most 72 UTF-8 bytes');
    const passwordHash = passwordChange ? await hashPassword(body.password) : null;
    await transaction(db, async conn => {
      const [[latest]] = await conn.query('SELECT * FROM users WHERE id=? FOR UPDATE', [account.id]);
      if (passwordChange && (typeof body.current_password !== 'string' || !await verifyPassword(body.current_password, latest))) throw new ApiError(403, 'Current password is incorrect');
      await conn.query('UPDATE users SET name=?,phone=?,address=?,profile_pic=?,password_hash=? WHERE id=?', [name, phone, address, req.file?.filename ?? latest.profile_pic, passwordHash ?? latest.password_hash, account.id]);
      if (passwordChange) await conn.query('DELETE FROM auth_sessions WHERE user_id=? AND token_hash!=?', [account.id, digest(getAuthToken(req))]);
    });
    const [[updated]] = await db.query('SELECT * FROM users WHERE id=?', [account.id]);
    res.json({ ok: true, user: publicUser(updated) });
  }));
  router.post('/auth/password-reset/start', wrap(async (req, res) => {
    const email = typeof req.body?.email === 'string' ? req.body.email.trim().toLowerCase() : '';
    if (email.length > 254 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) throw new ApiError(400, 'Valid email is required');
    const limit = reserveOtpRequest(req, email);
    if (!limit.allowed) return sendRateLimitResponse(res, limit);
    const code = String(crypto.randomInt(100000, 1000000));
    const [[account]] = await db.query('SELECT id,name FROM users WHERE email=?', [email]);
    const response = { ok: true, message: 'If this account exists, a password reset code has been sent.', resendAfterSeconds: 60 };
    if (account) {
      const [[existing]] = await db.query('SELECT created_at FROM password_resets WHERE email=?', [email]);
      if (existing && Date.now() - new Date(existing.created_at).getTime() < 60000) throw new ApiError(429, 'Please wait 60 seconds before requesting another code');
      const delivery = await sendVerificationMail({ email, name: account.name, code });
      await db.query('INSERT INTO password_resets (email,code_hash,expires_at,created_at,failed_attempts) VALUES (?,?,?,?,0) ON DUPLICATE KEY UPDATE code_hash=VALUES(code_hash),expires_at=VALUES(expires_at),created_at=VALUES(created_at),failed_attempts=0', [email, digest(code), new Date(Date.now() + 600000), new Date()]);
      if (isDevelopmentMode() && delivery.delivery === 'mock') response.previewCode = code;
    }
    res.json(response);
  }));
  router.post('/auth/password-reset/complete', wrap(async (req, res) => {
    const email = typeof req.body?.email === 'string' ? req.body.email.trim().toLowerCase() : '';
    const code = req.body?.code;
    if (email.length > 254 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || typeof code !== 'string' || !/^\d{6}$/.test(code)) throw new ApiError(400, 'Valid email and six-digit code are required');
    if (!isValidPassword(req.body?.password)) throw new ApiError(400, 'Password must be at least 8 characters and at most 72 UTF-8 bytes');
    // Commit failed attempts before returning an error so guesses cannot roll back the counter.
    const error = await transaction(db, async conn => {
      const [[reset]] = await conn.query('SELECT *, expires_at>UTC_TIMESTAMP(3) AS valid FROM password_resets WHERE email=? FOR UPDATE', [email]);
      if (!reset || !reset.valid) return new ApiError(400, 'Reset code is invalid or expired');
      if (reset.failed_attempts >= 5) return new ApiError(429, 'Too many attempts; request a new code');
      if (reset.code_hash !== digest(code)) {
        await conn.query('UPDATE password_resets SET failed_attempts=failed_attempts+1 WHERE email=?', [email]);
        return new ApiError(400, 'Reset code is invalid or expired');
      }
      const [[account]] = await conn.query('SELECT id FROM users WHERE email=? FOR UPDATE', [email]);
      if (!account) return new ApiError(400, 'Reset code is invalid or expired');
      const passwordHash = await hashPassword(req.body.password);
      await conn.query('UPDATE users SET password_hash=? WHERE id=?', [passwordHash, account.id]);
      await conn.query('DELETE FROM auth_sessions WHERE user_id=?', [account.id]);
      await conn.query('DELETE FROM password_resets WHERE email=?', [email]);
      return null;
    });
    if (error) throw error;
    res.json({ ok: true, message: 'Password updated. Sign in again.' });
  }));
  router.use((err, req, res, next) => {
    if (err instanceof require('multer').MulterError || err.code === 'INVALID_IMAGE_TYPE') return next(err);
    if (!err.status) console.error('[account-api]', err.message);
    res.status(err.status || (err.isPublic ? err.statusCode : 500)).json({ error: err.status || err.isPublic ? err.message : 'Unable to complete account request' });
  });
  app.use('/api', router);
}
module.exports = { mountAccountApi, digest };
