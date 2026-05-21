const bcrypt   = require('bcryptjs');
const jwt      = require('jsonwebtoken');
const User     = require('../models/User');
const Project  = require('../models/Project');
const { JWT_SECRET } = require('../middleware/authMiddleware');

// ─── Register ─────────────────────────────────────────────────────────────────
exports.register = async (req, res, next) => {
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
};

// ─── Login ────────────────────────────────────────────────────────────────────
exports.login = async (req, res, next) => {
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
};

// ─── Get Current User ─────────────────────────────────────────────────────────
exports.getMe = async (req, res, next) => {
  try {
    const user = await User.findById(req.user.userId).select('-password');
    res.json({ user });
  } catch (err) { next(err); }
};

// ─── Update Current User ──────────────────────────────────────────────────────
exports.updateMe = async (req, res, next) => {
  try {
    const { name, socialLinks } = req.body;
    const updateData = {};
    if (name !== undefined) updateData.name = name;

    if (socialLinks !== undefined) {
      // Validate all provided URLs — only http/https allowed.
      // This prevents javascript:, data:, and other XSS-enabling URI schemes
      // from being stored and rendered as clickable links on portfolio pages.
      const ALLOWED_KEYS = ['github', 'linkedin', 'twitter', 'portfolio'];
      const sanitized = {};
      for (const key of ALLOWED_KEYS) {
        const val = socialLinks[key];
        if (val === undefined || val === '') {
          sanitized[key] = '';
          continue;
        }
        try {
          const parsed = new URL(val);
          if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:') {
            return res.status(400).json({
              error: `Invalid URL for "${key}": only http:// and https:// links are allowed.`,
            });
          }
          sanitized[key] = val;
        } catch {
          return res.status(400).json({
            error: `Invalid URL format for "${key}". Please provide a full URL (e.g. https://linkedin.com/in/you).`,
          });
        }
      }
      updateData.socialLinks = sanitized;
    }

    const user = await User.findByIdAndUpdate(
      req.user.userId,
      { $set: updateData },
      { new: true }
    ).select('-password');

    res.json({ user });
  } catch (err) { next(err); }
};

// ─── Public Profile ───────────────────────────────────────────────────────────
exports.getPublicProfile = async (req, res, next) => {
  try {
    const user = await User.findById(req.params.userId)
      .select('name createdAt socialLinks'); // email deliberately omitted
    if (!user) return res.status(404).json({ error: 'User not found' });

    const projects = await Project.find({
      userId: req.params.userId,
      isDemo: false,
    })
      .sort({ displayOrder: 1, createdAt: -1 })
      .select('-fileTree -readmeContent');

    res.json({
      user: {
        id: user._id,
        name: user.name || 'Anonymous Developer',
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
};
