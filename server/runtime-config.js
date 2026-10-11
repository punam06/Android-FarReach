// Validate deployment settings before opening the HTTP listener.
function runtimeConfig(env = process.env) {
  const production = env.NODE_ENV === 'production';
  const proxyHops = Number(env.TRUST_PROXY_HOPS || 0);
  if (!Number.isInteger(proxyHops) || proxyHops < 0 || proxyHops > 3) throw new Error('TRUST_PROXY_HOPS must be an integer from 0 to 3');
  const origins = (env.CORS_ORIGINS || '').split(',').map(s => s.trim()).filter(Boolean);
  if (production) {
    for (const name of ['DB_HOST', 'DB_NAME', 'DB_USER', 'DB_PASSWORD', 'APP_API_BASE_URL', 'CORS_ORIGINS', 'SMTP_HOST', 'SMTP_USER', 'SMTP_PASS', 'SMTP_FROM']) {
      if (!env[name] || /YOUR_.*_HERE/.test(env[name])) throw new Error(`Production requires configured ${name}`);
    }
    if (env.DB_USER === 'root' || env.DB_PASSWORD.length < 16 || /local-only/.test(env.DB_PASSWORD)) throw new Error('Production requires a dedicated database user and a non-development password of at least 16 characters');
    const api = new URL(env.APP_API_BASE_URL);
    if (api.protocol !== 'https:' || api.username || api.password || api.search || api.hash) throw new Error('Production APP_API_BASE_URL must be an HTTPS URL without credentials, query or fragment');
    for (const origin of origins) {
      const url = new URL(origin);
      if (url.protocol !== 'https:' || url.origin !== origin) throw new Error('Production CORS_ORIGINS must contain exact HTTPS origins without paths');
    }
  }
  return { production, proxyHops, origins };
}
function securityMiddleware(config) {
  return (req, res, next) => {
    const origin = req.get('Origin');
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('X-Frame-Options', 'DENY');
    res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
    res.setHeader('X-Request-Id', require('crypto').randomUUID());
    if (config.production) res.setHeader('Strict-Transport-Security', 'max-age=31536000');
    if (req.path.startsWith('/api/')) res.setHeader('Cache-Control', 'no-store');
    if (origin && config.production && !config.origins.includes(origin)) return res.status(403).json({ error: 'Origin is not allowed' });
    if (!config.production) res.setHeader('Access-Control-Allow-Origin', '*');
    else if (origin) { res.setHeader('Access-Control-Allow-Origin', origin); res.vary('Origin'); }
    res.setHeader('Access-Control-Allow-Methods', 'GET,POST,PUT,DELETE,OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Session-Token, Idempotency-Key');
    res.setHeader('Access-Control-Expose-Headers', 'X-Request-Id, Retry-After');
    if (req.method === 'OPTIONS') return res.sendStatus(204);
    next();
  };
}
module.exports = { runtimeConfig, securityMiddleware };
