const express = require('express');
const axios = require('axios');
const Project = require('../models/Project');
const { validateGitHubUrl, extractAllRepoData } = require('../services/githubService');
const { generateProjectAnalysis } = require('../services/geminiService');

const router = express.Router();

// ─── POST /api/projects ─────────────────────────────────────────────────────
// Submit a new GitHub repo for analysis
router.post('/', async (req, res, next) => {
  try {
    const { githubUrl, liveUrl = '', videoUrl = '' } = req.body;

    if (!githubUrl) return res.status(400).json({ error: 'githubUrl is required' });

    const { owner, repo } = validateGitHubUrl(githubUrl);
    const fullName = `${owner}/${repo}`;

    // Return cached project if it already exists
    const existing = await Project.findOne({ fullName });
    if (existing) {
      return res.status(200).json({ message: 'Project already analyzed', project: existing });
    }

    // Step 1 — Fetch all GitHub data
    const repoData = await extractAllRepoData(owner, repo);

    // Step 2 — Save to DB immediately with aiStatus: pending
    const project = await Project.create({
      owner,
      repo,
      fullName,
      description: repoData.description,
      stars: repoData.stars,
      forks: repoData.forks,
      primaryLanguage: repoData.primaryLanguage,
      languages: repoData.languages,
      topics: repoData.topics,
      techStack: repoData.techStack,
      fileTree: repoData.fileTree,
      liveUrl,
      videoUrl,
      aiStatus: 'pending',
    });

    // Step 3 — Respond immediately so the client doesn't wait for Gemini
    res.status(202).json({ message: 'Repository submitted. AI analysis running in background.', project });

    // Step 4 — Run Gemini analysis asynchronously
    try {
      const { summary, mermaid } = await generateProjectAnalysis(repoData);
      await Project.findByIdAndUpdate(project._id, {
        aiSummary: summary,
        mermaidDiagram: mermaid,
        aiStatus: 'done',
      });
      console.log(`✅ AI analysis complete for ${fullName}`);
    } catch (aiErr) {
      await Project.findByIdAndUpdate(project._id, { aiStatus: 'failed' });
      console.error(`❌ AI analysis failed for ${fullName}:`, aiErr.message);
    }
  } catch (err) {
    next(err);
  }
});

// ─── GET /api/projects ──────────────────────────────────────────────────────
// Get all projects with optional filters: ?stack=MERN&language=Python&search=chatbot
router.get('/', async (req, res, next) => {
  try {
    const { stack, language, search } = req.query;
    const query = {};

    if (stack) query.techStack = { $in: [stack] };
    if (language) query.primaryLanguage = { $regex: language, $options: 'i' };
    if (search) {
      query.$or = [
        { repo: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } },
        { owner: { $regex: search, $options: 'i' } },
      ];
    }

    const projects = await Project.find(query)
      .sort({ createdAt: -1 })
      .select('-fileTree -readmeContent'); // exclude large fields from list view

    res.json({ count: projects.length, projects });
  } catch (err) {
    next(err);
  }
});

// ─── GET /api/projects/:id ──────────────────────────────────────────────────
// Get full project details (including AI summary and mermaid diagram)
router.get('/:id', async (req, res, next) => {
  try {
    const project = await Project.findById(req.params.id);
    if (!project) return res.status(404).json({ error: 'Project not found' });
    res.json({ project });
  } catch (err) {
    next(err);
  }
});

// ─── POST /api/projects/:id/heartbeat ───────────────────────────────────────
// Ping the live deployment URL and update heartbeat status
router.post('/:id/heartbeat', async (req, res, next) => {
  try {
    const { liveUrl } = req.body;
    if (!liveUrl) return res.status(400).json({ error: 'liveUrl is required' });

    let status = 'down';
    try {
      const response = await axios.get(liveUrl, { timeout: 8000 });
      if (response.status >= 200 && response.status < 400) status = 'live';
    } catch {
      status = 'down';
    }

    const project = await Project.findByIdAndUpdate(
      req.params.id,
      { heartbeatStatus: status, lastHeartbeatCheck: new Date(), liveUrl },
      { new: true }
    );

    if (!project) return res.status(404).json({ error: 'Project not found' });
    res.json({ status, project });
  } catch (err) {
    next(err);
  }
});

// ─── GET /api/projects/:id/commit-activity ──────────────────────────────────
// Proxy GitHub commit activity data (Phase 2 — Proof-of-Effort)
router.get('/:id/commit-activity', async (req, res, next) => {
  try {
    const project = await Project.findById(req.params.id).select('owner repo');
    if (!project) return res.status(404).json({ error: 'Project not found' });

    const { data } = await axios.get(
      `https://api.github.com/repos/${project.owner}/${project.repo}/stats/commit_activity`,
      {
        headers: {
          Authorization: `Bearer ${process.env.GITHUB_PAT}`,
          Accept: 'application/vnd.github+json',
        },
        timeout: 10000,
      }
    );
    res.json({ commitActivity: data });
  } catch (err) {
    next(err);
  }
});

// ─── GET /api/projects/:id/ai-status ────────────────────────────────────────
// Lightweight poll endpoint — Flutter calls this every 5s to check AI progress
router.get('/:id/ai-status', async (req, res, next) => {
  try {
    const project = await Project.findById(req.params.id)
      .select('aiStatus aiSummary mermaidDiagram');
    if (!project) return res.status(404).json({ error: 'Project not found' });
    res.json({
      aiStatus: project.aiStatus,
      aiSummary: project.aiSummary,
      mermaidDiagram: project.mermaidDiagram,
    });
  } catch (err) {
    next(err);
  }
});

// ─── POST /api/projects/:id/reanalyze ───────────────────────────────────────
// Re-trigger Gemini for a failed project (without re-fetching from GitHub)
router.post('/:id/reanalyze', async (req, res, next) => {
  try {
    const project = await Project.findById(req.params.id);
    if (!project) return res.status(404).json({ error: 'Project not found' });

    // Reset status
    await Project.findByIdAndUpdate(project._id, { aiStatus: 'pending' });
    res.json({ message: 'Re-analysis queued' });

    // Fire off async re-analysis using stored file tree and metadata
    const repoContext = {
      fullName: project.fullName,
      owner: project.owner,
      repo: project.repo,
      description: project.description,
      primaryLanguage: project.primaryLanguage,
      languages: project.languages || {},
      fileTree: project.fileTree || [],
      keyFilesContent: '',
      techStack: project.techStack || [],
      topics: project.topics || [],
    };

    try {
      const { summary, mermaid } = await generateProjectAnalysis(repoContext);
      await Project.findByIdAndUpdate(project._id, {
        aiSummary: summary,
        mermaidDiagram: mermaid,
        aiStatus: 'done',
      });
      console.log(`✅ Re-analysis complete for ${project.fullName}`);
    } catch (aiErr) {
      await Project.findByIdAndUpdate(project._id, { aiStatus: 'failed' });
      console.error(`❌ Re-analysis failed for ${project.fullName}:`, aiErr.message);
    }
  } catch (err) {
    next(err);
  }
});

// ─── POST /api/admin/reanalyze-all ──────────────────────────────────────────
// Re-runs Gemini analysis on ALL projects sequentially (rate-limit friendly).
// Use this after updating the prompt to regenerate diagrams for existing data.
// Returns immediately; progress is logged server-side.
router.post('/admin/reanalyze-all', async (req, res, next) => {
  try {
    const projects = await Project.find({}).select('_id fullName fileTree');
    res.json({ message: `Queued ${projects.length} projects for re-analysis` });

    // Fire-and-forget: run sequentially with 3s gap to respect Gemini rate limits
    (async () => {
      for (const p of projects) {
        if (!p.fileTree || p.fileTree.length === 0) {
          console.log(`⏭  Skipping ${p.fullName} — no cached file tree`);
          continue;
        }
        console.log(`🔄 Re-analyzing ${p.fullName}...`);
        try {
          await Project.findByIdAndUpdate(p._id, { aiStatus: 'pending' });
          const full = await Project.findById(p._id);
          const repoContext = {
            fullName: full.fullName,
            owner: full.owner,
            repo: full.repo,
            description: full.description,
            primaryLanguage: full.primaryLanguage,
            languages: full.languages || {},
            fileTree: full.fileTree || [],
            keyFilesContent: '',
            techStack: full.techStack || [],
            topics: full.topics || [],
          };
          const { summary, mermaid } = await generateProjectAnalysis(repoContext);
          await Project.findByIdAndUpdate(p._id, {
            aiSummary: summary,
            mermaidDiagram: mermaid,
            aiStatus: 'done',
          });
          console.log(`✅ Re-analysis done: ${p.fullName}`);
        } catch (err) {
          await Project.findByIdAndUpdate(p._id, { aiStatus: 'failed' });
          console.error(`❌ Re-analysis failed: ${p.fullName} — ${err.message}`);
        }
        // 3s pause between projects to avoid Gemini rate limits
        await new Promise(r => setTimeout(r, 3000));
      }
      console.log('🎉 Bulk re-analysis complete');
    })();
  } catch (err) {
    next(err);
  }
});

module.exports = router;

