const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'codespotlight-dev-secret-change-in-prod';

/** Requires a valid JWT. Sets req.user or responds 401. */
const authenticate = (req, res, next) => {
  const auth = req.headers['authorization'];
  if (!auth?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Authentication required' });
  }
  try {
    req.user = jwt.verify(auth.slice(7), JWT_SECRET);
    next();
  } catch {
    res.status(401).json({ error: 'Invalid or expired token' });
  }
};

/**
 * Soft auth — attaches user from JWT if present.
 * Also reads X-Demo-Session header for demo mode.
 * Never blocks the request.
 */
const optionalAuth = (req, res, next) => {
  const auth = req.headers['authorization'];
  const demo = req.headers['x-demo-session'];
  if (auth?.startsWith('Bearer ')) {
    try { req.user = jwt.verify(auth.slice(7), JWT_SECRET); } catch {}
  }
  if (demo) req.demoSessionId = demo;
  next();
};

module.exports = { authenticate, optionalAuth, JWT_SECRET };
