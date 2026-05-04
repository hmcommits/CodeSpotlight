/**
 * Central error handler middleware.
 * Returns consistent { error, code } JSON responses.
 */
function errorHandler(err, req, res, next) {
  console.error(`[ERROR] ${req.method} ${req.path}:`, err.message);

  const statusMap = {
    'Repository not found': 404,
    'Repository is private': 403,
    'Invalid GitHub URL': 400,
    'already exists': 409,
  };

  let status = 500;
  for (const [key, code] of Object.entries(statusMap)) {
    if (err.message?.includes(key)) {
      status = code;
      break;
    }
  }

  res.status(status).json({
    error: err.message || 'An unexpected error occurred.',
    code: status,
  });
}

module.exports = errorHandler;
