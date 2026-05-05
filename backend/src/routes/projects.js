const express = require('express');
const axios   = require('axios');
const Project = require('../models/Project');
const { validateGitHubUrl, extractAllRepoData } = require('../services/githubService');
const { generateProjectAnalysis, generateReadme } = require('../services/geminiService');
const { optionalAuth, authenticate }            = require('../middleware/authMiddleware');

const router = express.Router();

// ─── Helpers ─────────────────────────────────────────────────────────────────

/** Builds the MongoDB filter for scoping projects to user OR demo session. */
function scopeFilter(req) {
  if (req.user)          return { userId: req.user.userId };
  if (req.demoSessionId) return { demoSessionId: req.demoSessionId };
  return null; // no scope → caller decides what to do
}

// ─── POST /api/projects ───────────────────────────────────────────────────────
// Requires either JWT auth or X-Demo-Session header
router.post('/', optionalAuth, async (req, res, next) => {
  try {
    if (!req.user && !req.demoSessionId)
      return res.status(401).json({ error: 'Login or start demo mode to add projects' });

    const { githubUrl, liveUrl = '', videoUrl = '' } = req.body;
    if (!githubUrl) return res.status(400).json({ error: 'githubUrl is required' });

    const { owner, repo } = validateGitHubUrl(githubUrl);
    const fullName = `${owner}/${repo}`;

    // Check for duplicate within same user / demo session
    const filter = scopeFilter(req);
    const existing = await Project.findOne({ fullName, ...filter });
    if (existing) {
      // Refresh stale metadata in the background, return quickly
      res.status(200).json({ message: 'Project already added — refreshing metadata.', project: existing });
      // Async refresh of description/stars/languages
      extractAllRepoData(owner, repo).then(async (repoData) => {
        await Project.findByIdAndUpdate(existing._id, {
          description:     repoData.description,
          stars:           repoData.stars,
          forks:           repoData.forks,
          primaryLanguage: repoData.primaryLanguage,
          languages:       repoData.languages,
          topics:          repoData.topics,
          techStack:       repoData.techStack,
          ...(liveUrl  && { liveUrl }),
          ...(videoUrl && { videoUrl }),
        });
        console.log(`🔄 Refreshed metadata for ${fullName}`);
      }).catch(err => console.warn(`⚠️  Metadata refresh failed for ${fullName}:`, err.message));
      return;
    }

    // Fetch GitHub data
    const repoData = await extractAllRepoData(owner, repo);

    // Build project doc
    const isDemo  = Boolean(req.demoSessionId);
    const docData = {
      owner, repo, fullName,
      description:     repoData.description,
      stars:           repoData.stars,
      forks:           repoData.forks,
      primaryLanguage: repoData.primaryLanguage,
      languages:       repoData.languages,
      topics:          repoData.topics,
      techStack:       repoData.techStack,
      fileTree:        repoData.fileTree,
      liveUrl, videoUrl,
      aiStatus: 'pending',
      // Auth scoping
      userId:        req.user ? req.user.userId   : '',
      userEmail:     req.user ? req.user.email    : '',
      isDemo,
      demoSessionId: req.demoSessionId || '',
      // TTL: demo projects expire in 2 hours
      demoExpiresAt: isDemo ? new Date(Date.now() + 2 * 60 * 60 * 1000) : null,
    };

    const project = await Project.create(docData);
    res.status(202).json({ message: 'Repository submitted. AI analysis running in background.', project });

    // Async Gemini analysis
    try {
      const { summary, mermaid } = await generateProjectAnalysis(repoData);
      await Project.findByIdAndUpdate(project._id, {
        aiSummary: summary, mermaidDiagram: mermaid, aiStatus: 'done',
      });
      console.log(`✅ AI complete: ${fullName}`);
    } catch (aiErr) {
      await Project.findByIdAndUpdate(project._id, { aiStatus: 'failed' });
      console.error(`❌ AI failed: ${fullName}:`, aiErr.message);
    }
  } catch (err) { next(err); }
});

// ─── GET /api/projects ────────────────────────────────────────────────────────
// Returns projects scoped to the authenticated user or demo session.
// No scope header → returns empty array (not a public gallery).
router.get('/', optionalAuth, async (req, res, next) => {
  try {
    const filter = scopeFilter(req);
    if (!filter) return res.json({ count: 0, projects: [] });

    const { stack, language, search } = req.query;
    if (stack)    filter.techStack        = { $in: [stack] };
    if (language) filter.primaryLanguage  = { $regex: language, $options: 'i' };
    if (search) {
      filter.$or = [
        { repo:        { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } },
        { owner:       { $regex: search, $options: 'i' } },
      ];
    }

    const projects = await Project.find(filter)
      .sort({ createdAt: -1 })
      .select('-fileTree -readmeContent');
    res.json({ count: projects.length, projects });
  } catch (err) { next(err); }
});

// ─── GET /api/projects/public ─────────────────────────────────────────────────
// Public discovery feed — no auth required
router.get('/public', async (req, res, next) => {
  try {
    const { stack, language, sort = 'newest', limit = 30, page = 1 } = req.query;
    const filter = { isDemo: false };
    if (stack)    filter.techStack       = { $in: [stack] };
    if (language) filter.primaryLanguage = { $regex: language, $options: 'i' };

    const sortMap = {
      newest: { createdAt: -1 },
      stars:  { stars: -1 },
      forks:  { forks: -1 },
    };
    const sortQuery = sortMap[sort] || sortMap.newest;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const [projects, total] = await Promise.all([
      Project.find(filter)
        .sort(sortQuery)
        .skip(skip)
        .limit(parseInt(limit))
        .select('-fileTree -readmeContent -aiSummary'),
      Project.countDocuments(filter),
    ]);

    res.json({ total, page: parseInt(page), projects });
  } catch (err) { next(err); }
});

// ─── GET /api/projects/:id ────────────────────────────────────────────────────
// Public — used for deep links / sharing
router.get('/:id', async (req, res, next) => {
  try {
    const project = await Project.findById(req.params.id);
    if (!project) return res.status(404).json({ error: 'Project not found' });
    res.json(project);
  } catch (err) { next(err); }
});

// ─── GET /api/projects/:id/poll ───────────────────────────────────────────────
router.get('/:id/poll', async (req, res, next) => {
  try {
    const p = await Project.findById(req.params.id)
      .select('aiStatus aiSummary mermaidDiagram');
    if (!p) return res.status(404).json({ error: 'Not found' });
    res.json({ aiStatus: p.aiStatus, aiSummary: p.aiSummary, mermaidDiagram: p.mermaidDiagram });
  } catch (err) { next(err); }
});

// ─── POST /api/projects/:id/heartbeat ────────────────────────────────────────
router.post('/:id/heartbeat', optionalAuth, async (req, res, next) => {
  try {
    const project = await Project.findById(req.params.id);
    if (!project) return res.status(404).json({ error: 'Project not found' });

    const url = req.body.liveUrl || project.liveUrl;
    if (!url) return res.status(400).json({ error: 'No liveUrl provided' });

    let status = 'down';
    try {
      await axios.get(url, { timeout: 8000, maxRedirects: 3 });
      status = 'live';
    } catch {}

    await Project.findByIdAndUpdate(req.params.id, {
      heartbeatStatus: status,
      lastHeartbeatCheck: new Date(),
      ...(url !== project.liveUrl ? { liveUrl: url } : {}),
    });
    res.json({ status });
  } catch (err) { next(err); }
});

// ─── POST /api/projects/:id/reanalyze ────────────────────────────────────────
router.post('/:id/reanalyze', optionalAuth, async (req, res, next) => {
  try {
    if (!req.user && !req.demoSessionId)
      return res.status(401).json({ error: 'Not authenticated' });

    const project = await Project.findById(req.params.id);
    if (!project) return res.status(404).json({ error: 'Project not found' });

    await Project.findByIdAndUpdate(req.params.id, { aiStatus: 'pending' });
    res.json({ message: 'Re-analysis started' });

    const repoContext = {
      fullName: project.fullName, owner: project.owner, repo: project.repo,
      description: project.description, primaryLanguage: project.primaryLanguage,
      languages: project.languages || {}, fileTree: project.fileTree || [],
      keyFilesContent: '', techStack: project.techStack || [], topics: project.topics || [],
    };

    try {
      const { summary, mermaid } = await generateProjectAnalysis(repoContext);
      await Project.findByIdAndUpdate(project._id, {
        aiSummary: summary, mermaidDiagram: mermaid, aiStatus: 'done',
      });
    } catch (err) {
      await Project.findByIdAndUpdate(project._id, { aiStatus: 'failed' });
    }
  } catch (err) { next(err); }
});

// ─── GET /api/projects/:id/commit-activity ────────────────────────────────────
router.get('/:id/commit-activity', async (req, res, next) => {
  try {
    const project = await Project.findById(req.params.id).select('owner repo');
    if (!project) return res.status(404).json({ error: 'Not found' });

    const { data } = await axios.get(
      `https://api.github.com/repos/${project.owner}/${project.repo}/stats/commit_activity`,
      {
        headers: {
          Authorization: `Bearer ${process.env.GITHUB_PAT}`,
          Accept: 'application/vnd.github.v3+json',
        },
        timeout: 15000,
      }
    );
    res.json(Array.isArray(data) ? data : []);
  } catch (err) { next(err); }
});

// ─── DELETE /api/projects/demo/:sessionId ────────────────────────────────────
// Called when user exits demo mode — wipes all their demo projects instantly
router.delete('/demo/:sessionId', async (req, res, next) => {
  try {
    const result = await Project.deleteMany({ demoSessionId: req.params.sessionId, isDemo: true });
    res.json({ deleted: result.deletedCount });
  } catch (err) { next(err); }
});

// ─── DELETE /api/projects/:id ─────────────────────────────────────────────────
router.delete('/:id', optionalAuth, async (req, res, next) => {
  try {
    if (!req.user && !req.demoSessionId)
      return res.status(401).json({ error: 'Not authenticated' });

    const filter = scopeFilter(req);
    const project = await Project.findOne({ _id: req.params.id, ...filter });
    if (!project) return res.status(404).json({ error: 'Project not found or access denied' });

    await Project.findByIdAndDelete(req.params.id);
    res.json({ deleted: true, id: req.params.id });
  } catch (err) { next(err); }
});

// ─── PATCH /api/projects/:id ──────────────────────────────────────────────────
// Edit liveUrl and/or videoUrl of an owned project
router.patch('/:id', optionalAuth, async (req, res, next) => {
  try {
    if (!req.user && !req.demoSessionId)
      return res.status(401).json({ error: 'Not authenticated' });

    const filter = scopeFilter(req);
    const project = await Project.findOne({ _id: req.params.id, ...filter });
    if (!project) return res.status(404).json({ error: 'Project not found or access denied' });

    const allowed = ['liveUrl', 'videoUrl'];
    const updates = {};
    for (const key of allowed) {
      if (req.body[key] !== undefined) updates[key] = req.body[key];
    }

    const updated = await Project.findByIdAndUpdate(
      req.params.id,
      updates,
      { new: true, select: '-fileTree -readmeContent' }
    );
    res.json({ project: updated });
  } catch (err) { next(err); }
});

// ─── POST /api/projects/:id/readme ───────────────────────────────────────────
// Generate a professional README using Gemini from stored project context
router.post('/:id/readme', optionalAuth, async (req, res, next) => {
  try {
    const project = await Project.findById(req.params.id);
    if (!project) return res.status(404).json({ error: 'Project not found' });

    const readme = await generateReadme({
      fullName:        project.fullName,
      description:     project.description,
      primaryLanguage: project.primaryLanguage,
      languages:       project.languages || {},
      techStack:       project.techStack || [],
      topics:          project.topics || [],
      liveUrl:         project.liveUrl || '',
      aiSummary:       project.aiSummary || '',
    });

    res.json({ readme });
  } catch (err) { next(err); }
});

// ─── POST /api/projects/admin/reanalyze-all ──────────────────────────────────
router.post('/admin/reanalyze-all', async (req, res, next) => {
  try {
    const projects = await Project.find({ isDemo: false }).select('_id fullName fileTree');
    res.json({ message: `Queued ${projects.length} projects for re-analysis` });

    (async () => {
      for (const p of projects) {
        if (!p.fileTree?.length) continue;
        try {
          await Project.findByIdAndUpdate(p._id, { aiStatus: 'pending' });
          const full = await Project.findById(p._id);
          const { summary, mermaid } = await generateProjectAnalysis({
            fullName: full.fullName, owner: full.owner, repo: full.repo,
            description: full.description, primaryLanguage: full.primaryLanguage,
            languages: full.languages || {}, fileTree: full.fileTree || [],
            keyFilesContent: '', techStack: full.techStack || [], topics: full.topics || [],
          });
          await Project.findByIdAndUpdate(p._id, {
            aiSummary: summary, mermaidDiagram: mermaid, aiStatus: 'done',
          });
          console.log(`✅ Re-analyzed: ${p.fullName}`);
        } catch (err) {
          await Project.findByIdAndUpdate(p._id, { aiStatus: 'failed' });
        }
        await new Promise(r => setTimeout(r, 3000));
      }
    })();
  } catch (err) { next(err); }
});

module.exports = router;
