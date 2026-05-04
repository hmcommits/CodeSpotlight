const mongoose = require('mongoose');

const projectSchema = new mongoose.Schema(
  {
    owner: { type: String, required: true },
    repo: { type: String, required: true },
    fullName: { type: String, required: true, unique: true },
    description: { type: String, default: '' },
    stars: { type: Number, default: 0 },
    forks: { type: Number, default: 0 },
    primaryLanguage: { type: String, default: 'Unknown' },
    languages: { type: Object, default: {} },
    topics: [String],
    techStack: [String],
    readmeContent: { type: String, default: '' },
    fileTree: [String],
    aiSummary: { type: String, default: '' },
    mermaidDiagram: { type: String, default: '' },
    aiStatus: {
      type: String,
      enum: ['pending', 'done', 'failed'],
      default: 'pending',
    },
    liveUrl: { type: String, default: '' },
    videoUrl: { type: String, default: '' },
    heartbeatStatus: {
      type: String,
      enum: ['live', 'down', 'unknown'],
      default: 'unknown',
    },
    lastHeartbeatCheck: { type: Date, default: null },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Project', projectSchema);
