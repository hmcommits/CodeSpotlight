const mongoose = require('mongoose');

const projectSchema = new mongoose.Schema(
  {
    owner:           { type: String, required: true },
    repo:            { type: String, required: true },
    fullName:        { type: String, required: true },
    description:     { type: String, default: '' },
    stars:           { type: Number, default: 0 },
    forks:           { type: Number, default: 0 },
    primaryLanguage: { type: String, default: 'Unknown' },
    languages:       { type: Object, default: {} },
    topics:          [String],
    techStack:       [String],
    readmeContent:   { type: String, default: '' },
    fileTree:        [String],
    aiSummary:       { type: String, default: '' },
    mermaidDiagram:  { type: String, default: '' },
    aiStatus: {
      type: String,
      enum: ['pending', 'done', 'failed'],
      default: 'pending',
    },
    liveUrl:         { type: String, default: '' },
    videoUrl:        { type: String, default: '' },
    heartbeatStatus: {
      type: String,
      enum: ['live', 'down', 'unknown'],
      default: 'unknown',
    },
    lastHeartbeatCheck: { type: Date, default: null },

    // ── Auth / Demo scoping ────────────────────────────────────────────────
    // CHANGED from String → ObjectId ref so Mongoose .populate() works correctly.
    // MIGRATION REQUIRED for existing production data (one-time):
    //   db.projects.find({ userId: { $type: 'string', $ne: '' } }).forEach(doc => {
    //     db.projects.updateOne({ _id: doc._id }, {
    //       $set: { userId: ObjectId(doc.userId) }
    //     });
    //   });
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
      index: true,    // Fast lookups by user
    },
    userEmail:     { type: String, default: '' },  // kept for display convenience
    isDemo:        { type: Boolean, default: false },
    demoSessionId: { type: String, default: '' },   // UUID per demo session
    // TTL: demo projects auto-delete 2 hours after creation
    demoExpiresAt: { type: Date, default: null, index: { expireAfterSeconds: 0 } },

    // ── Portfolio Builder fields ───────────────────────────────────────────
    featured:            { type: Boolean, default: false },
    displayOrder:        { type: Number, default: 0 },
    isPublicOnPortfolio: { type: Boolean, default: true },
    customDescription:   { type: String, default: '' }, // user-overridable blurb
  },
  { timestamps: true }
);

// ── Indexes ───────────────────────────────────────────────────────────────────
// Compound index — each user/demo session can only add a repo once
projectSchema.index({ fullName: 1, userId: 1, demoSessionId: 1 });
// Public feed queries: filter by isDemo, sort by createdAt / stars / forks
projectSchema.index({ isDemo: 1, createdAt: -1 });
projectSchema.index({ isDemo: 1, stars: -1 });
projectSchema.index({ isDemo: 1, forks: -1 });
// Portfolio builder: fetch all projects for a user quickly
projectSchema.index({ userId: 1, isDemo: 1, displayOrder: 1 });

module.exports = mongoose.model('Project', projectSchema);
