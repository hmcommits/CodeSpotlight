require('dotenv').config();
const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');

const projectRoutes   = require('./src/routes/projects');
const authRoutes      = require('./src/routes/auth');
const portfolioRoutes = require('./src/routes/portfolio');
const errorHandler    = require('./src/middleware/errorHandler');
const analysisQueue   = require('./src/services/analysisQueue');

const app = express();
const PORT = process.env.PORT || 3000;

// ─── CORS configuration ─────────────────────────────────────────────────────────
const isProd = process.env.NODE_ENV === 'production';
const allowedOrigin = process.env.CLIENT_URL;
if (isProd && !allowedOrigin) {
  throw new Error(
    'FATAL: CLIENT_URL environment variable is not set. ' +
    'Set it to your frontend URL (e.g. https://codespotlight-hm.web.app) in production.'
  );
}

app.use(express.json());
app.use(
  cors({
    origin: allowedOrigin || '*', // '*' only reachable in non-production
    methods: ['GET', 'POST', 'PATCH', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Demo-Session'],
  })
);

// ─── Health Check ────────────────────────────────────────────────────────────
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: Date.now(), env: process.env.NODE_ENV || 'development' });
});

// ─── Routes ─────────────────────────────────────────────────────────────────
app.use('/api/auth',      authRoutes);
app.use('/api/projects',  projectRoutes);
app.use('/api/portfolio', portfolioRoutes);

// ─── 404 handler ────────────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ error: `Route ${req.method} ${req.path} not found` });
});

// ─── Error handler ───────────────────────────────────────────────────────────
app.use(errorHandler);

// ─── Database + Server Start ─────────────────────────────────────────────────
mongoose
  .connect(process.env.MONGODB_URI)
  .then(async () => {
    console.log('✅ Connected to MongoDB Atlas');
    app.listen(PORT, () => {
      console.log(`🚀 CodeSpotlight backend running on port ${PORT}`);
    });
    // Recover any projects that were stuck in 'pending' before the last restart
    await analysisQueue.recoverStuckJobs();
  })
  .catch((err) => {
    console.error('❌ MongoDB connection failed:', err.message);
    process.exit(1);
  });
