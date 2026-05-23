/**
 * AnalysisQueue — in-memory job queue for Gemini AI analysis.
 *
 * Why not just a floating promise?
 *  - Server restarts leave jobs permanently stuck in "pending" with no recovery.
 *  - Concurrent submissions create unbounded parallel Gemini calls.
 *  - No visibility into queue depth or job state.
 *
 * This implementation:
 *  - Processes one job at a time (concurrency=1) to stay within Gemini rate limits.
 *  - On server startup, recovers all projects stuck in "pending" from the DB.
 *  - Emits lightweight console logs for observability.
 */

const { generateProjectAnalysis } = require('./geminiService');

class AnalysisQueue {
  constructor() {
    /** @type {Array<{projectId: string, repoContext: object}>} */
    this._queue = [];
    this._running = false;
  }

  /**
   * Add a project analysis job to the end of the queue.
   * @param {string} projectId - MongoDB _id as string
   * @param {object} repoContext - full repo context for Gemini
   */
  enqueue(projectId, repoContext) {
    this._queue.push({ projectId, repoContext });
    console.log(`📋 Queued analysis for ${repoContext.fullName} (queue depth: ${this._queue.length})`);
    this._tick();
  }

  /** Internal: start processing if not already running. */
  _tick() {
    if (this._running) return;
    this._processNext();
  }

  async _processNext() {
    if (this._queue.length === 0) {
      this._running = false;
      return;
    }

    this._running = true;
    const { projectId, repoContext } = this._queue.shift();

    // Lazy-require Project here to avoid circular deps at module load time
    const Project = require('../models/Project');

    try {
      console.log(`🤖 Processing analysis for ${repoContext.fullName}...`);
      await Project.findByIdAndUpdate(projectId, { aiStatus: 'pending' });

      const { summary, mermaid } = await generateProjectAnalysis(repoContext);

      await Project.findByIdAndUpdate(projectId, {
        aiSummary: summary,
        mermaidDiagram: mermaid,
        aiStatus: 'done',
      });
      console.log(`✅ Analysis complete: ${repoContext.fullName}`);
    } catch (err) {
      console.error(`❌ Analysis failed for ${repoContext.fullName}:`, err.message);
      try {
        const Project = require('../models/Project');
        await Project.findByIdAndUpdate(projectId, { aiStatus: 'failed' });
      } catch (dbErr) {
        console.error('❌ Failed to update aiStatus to "failed":', dbErr.message);
      }
    }

    // Pace requests: small delay between jobs to respect Gemini rate limits
    await new Promise((r) => setTimeout(r, 1500));

    // Continue processing
    this._processNext();
  }

  /**
   * Startup recovery — called once after DB connects.
   * Finds all non-demo projects stuck in "pending" and re-queues them.
   * This handles the case where the server crashed mid-analysis.
   */
  async recoverStuckJobs() {
    const Project = require('../models/Project');
    const stuck = await Project.find({ aiStatus: 'pending', isDemo: false })
      .select('_id fullName owner repo description primaryLanguage languages fileTree techStack topics');

    if (stuck.length === 0) {
      console.log('✅ No stuck pending jobs found on startup.');
      return;
    }

    console.log(`🔄 Recovering ${stuck.length} stuck "pending" project(s) from previous session...`);
    for (const p of stuck) {
      this.enqueue(p._id.toString(), {
        fullName: p.fullName,
        owner: p.owner,
        repo: p.repo,
        description: p.description,
        primaryLanguage: p.primaryLanguage,
        languages: p.languages || {},
        fileTree: p.fileTree || [],
        keyFilesContent: '',
        techStack: p.techStack || [],
        topics: p.topics || [],
      });
    }
  }

  get depth() {
    return this._queue.length;
  }
}

// Export a singleton so all routes share the same queue
const analysisQueue = new AnalysisQueue();
module.exports = analysisQueue;
