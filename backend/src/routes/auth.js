const express  = require('express');
const bcrypt   = require('bcryptjs');
const jwt      = require('jsonwebtoken');
const User     = require('../models/User');
const Project  = require('../models/Project');
const { JWT_SECRET, authenticate } = require('../middleware/authMiddleware');

const router = express.Router();

// ─── POST /api/auth/register ─────────────────────────────────────────────────
router.post('/register', async (req, res, next) => {
  try {
    const { email, password, name = '' } = req.body;
    if (!email || !password)
      return res.status(400).json({ error: 'Email and password are required' });
    if (password.length < 6)
      return res.status(400).json({ error: 'Password must be at least 6 characters' });

    const existing = await User.findOne({ email: email.toLowerCase() });
    if (existing)
      return res.status(409).json({ error: 'An account with this email already exists' });

    const hashed = await bcrypt.hash(password, 12);
    const user   = await User.create({ email: email.toLowerCase(), password: hashed, name });

    const token = jwt.sign(
      { userId: user._id, email: user.email, name: user.name },
      JWT_SECRET,
      { expiresIn: '30d' }
    );
    res.status(201).json({ token, user: { id: user._id, email: user.email, name: user.name } });
  } catch (err) { next(err); }
});

// ─── POST /api/auth/login ─────────────────────────────────────────────────────
router.post('/login', async (req, res, next) => {
  try {
    const { email, password } = req.body;
    if (!email || !password)
      return res.status(400).json({ error: 'Email and password are required' });

    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user) return res.status(401).json({ error: 'Invalid email or password' });

    const valid = await bcrypt.compare(password, user.password);
    if (!valid) return res.status(401).json({ error: 'Invalid email or password' });

    const token = jwt.sign(
      { userId: user._id, email: user.email, name: user.name },
      JWT_SECRET,
      { expiresIn: '30d' }
    );
    res.json({ token, user: { id: user._id, email: user.email, name: user.name } });
  } catch (err) { next(err); }
});

// ─── GET /api/auth/me ─────────────────────────────────────────────────────────
router.get('/me', authenticate, async (req, res, next) => {
  try {
    const user = await User.findById(req.user.userId).select('-password');
    res.json({ user });
  } catch (err) { next(err); }
});

// ─── PATCH /api/auth/me ───────────────────────────────────────────────────────
router.patch('/me', authenticate, async (req, res, next) => {
  try {
    const { name, socialLinks } = req.body;
    const updateData = {};
    if (name !== undefined) updateData.name = name;
    if (socialLinks !== undefined) updateData.socialLinks = socialLinks;

    const user = await User.findByIdAndUpdate(
      req.user.userId,
      { $set: updateData },
      { new: true }
    ).select('-password');
    
    res.json({ user });
  } catch (err) { next(err); }
});

// ─── GET /api/auth/profile/:userId ───────────────────────────────────────────
// Public — returns user display info + their projects for portfolio sharing
router.get('/profile/:userId', async (req, res, next) => {
  try {
    const user = await User.findById(req.params.userId)
      .select('name email createdAt socialLinks');
    if (!user) return res.status(404).json({ error: 'User not found' });

    const projects = await Project.find({
      userId: req.params.userId,
      isDemo: false,
    })
      .sort({ createdAt: -1 })
      .select('-fileTree -readmeContent');

    res.json({
      user: {
        id: user._id,
        name: user.name || user.email.split('@')[0],
        email: user.email,
        memberSince: user.createdAt,
        socialLinks: user.socialLinks || {},
      },
      projects,
      stats: {
        totalRepos: projects.length,
        totalStars: projects.reduce((s, p) => s + p.stars, 0),
        totalForks: projects.reduce((s, p) => s + p.forks, 0),
        liveDeployments: projects.filter(p => p.liveUrl).length,
        aiAnalyzed: projects.filter(p => p.aiStatus === 'done').length,
      },
    });
  } catch (err) { next(err); }
});

module.exports = router;
