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
    userId:        { type: String, default: '' },   // set for logged-in users
    userEmail:     { type: String, default: '' },   // display name
    isDemo:        { type: Boolean, default: false },
    demoSessionId: { type: String, default: '' },   // UUID per demo session
    // TTL: demo projects auto-delete 2 hours after creation
    demoExpiresAt: { type: Date, default: null, index: { expireAfterSeconds: 0 } },
  },
  { timestamps: true }
);

// Compound index — each user/demo session can only add a repo once
projectSchema.index({ fullName: 1, userId: 1, demoSessionId: 1 });

module.exports = mongoose.model('Project', projectSchema);
