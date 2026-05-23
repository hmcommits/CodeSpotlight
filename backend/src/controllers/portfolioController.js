const User = require('../models/User');
const Project = require('../models/Project');

// PATCH /api/auth/me/portfolio
exports.updatePortfolio = async (req, res, next) => {
  try {
    const { bio, avatarUrl, portfolioTemplate, portfolioPublished } = req.body;
    const updateData = {};

    if (bio !== undefined) {
      if (typeof bio !== 'string' || bio.length > 500) {
        return res.status(400).json({ error: 'Bio must be a string of up to 500 characters' });
      }
      updateData.bio = bio;
    }

    if (avatarUrl !== undefined) {
      if (avatarUrl !== '') {
        try {
          const parsed = new URL(avatarUrl);
          if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:') {
            return res.status(400).json({ error: 'Avatar URL must be http or https' });
          }
        } catch {
          return res.status(400).json({ error: 'Invalid Avatar URL' });
        }
      }
      updateData.avatarUrl = avatarUrl;
    }

    if (portfolioTemplate !== undefined) {
      const allowedTemplates = ['minimal', 'grid', 'terminal', 'glassmorphic'];
      if (!allowedTemplates.includes(portfolioTemplate)) {
        return res.status(400).json({ error: 'Invalid template' });
      }
      updateData.portfolioTemplate = portfolioTemplate;
    }

    if (portfolioPublished !== undefined) {
      updateData.portfolioPublished = Boolean(portfolioPublished);
    }

    const user = await User.findByIdAndUpdate(
      req.user.userId,
      { $set: updateData },
      { new: true }
    ).select('-password');

    res.json({ user });
  } catch (err) {
    next(err);
  }
};

// POST /api/auth/me/slug
exports.claimSlug = async (req, res, next) => {
  try {
    const { slug } = req.body;
    if (!slug || typeof slug !== 'string') {
      return res.status(400).json({ error: 'Slug is required' });
    }

    const normalizedSlug = slug.toLowerCase().trim();
    if (!/^[a-z0-9_-]{3,30}$/.test(normalizedSlug)) {
      return res.status(400).json({ error: 'Slug must be 3-30 chars: letters, digits, - or _' });
    }

    // Check if taken by another user
    const existing = await User.findOne({ portfolioSlug: normalizedSlug });
    if (existing && existing._id.toString() !== req.user.userId) {
      return res.status(409).json({ error: 'Slug is already taken' });
    }

    const user = await User.findByIdAndUpdate(
      req.user.userId,
      { $set: { portfolioSlug: normalizedSlug } },
      { new: true }
    ).select('-password');

    res.json({ user });
  } catch (err) {
    next(err);
  }
};

// GET /api/portfolio/:slug
exports.getPortfolioBySlug = async (req, res, next) => {
  try {
    const { slug } = req.params;
    if (!slug) return res.status(400).json({ error: 'Slug is required' });

    const user = await User.findOne({
      portfolioSlug: slug.toLowerCase().trim(),
    }).select('-password');

    if (!user || !user.portfolioPublished) {
      return res.status(404).json({ error: 'Portfolio not found' });
    }

    const projects = await Project.find({
      userId: user._id,
      isDemo: false,
      isPublicOnPortfolio: true,
    })
      .sort({ displayOrder: 1, createdAt: -1 })
      .select('-fileTree -readmeContent');

    res.json({
      user: {
        id: user._id,
        name: user.name || 'Anonymous Developer',
        bio: user.bio,
        avatarUrl: user.avatarUrl,
        portfolioTemplate: user.portfolioTemplate,
        portfolioSlug: user.portfolioSlug,
        socialLinks: user.socialLinks || {},
        memberSince: user.createdAt,
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
  } catch (err) {
    next(err);
  }
};
