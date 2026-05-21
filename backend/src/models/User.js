const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  email:       { type: String, required: true, unique: true, lowercase: true, trim: true },
  password:    { type: String, required: true },
  name:        { type: String, default: '', trim: true },
  socialLinks: {
    github:    { type: String, default: '' },
    linkedin:  { type: String, default: '' },
    twitter:   { type: String, default: '' },
    portfolio: { type: String, default: '' },
  },

  // ── Portfolio Builder fields ───────────────────────────────────────────────
  bio:                 { type: String, default: '', maxlength: 500 },
  avatarUrl:           { type: String, default: '' },
  portfolioTemplate:   {
    type: String,
    enum: ['minimal', 'grid', 'terminal', 'glassmorphic'],
    default: 'minimal',
  },
  portfolioPublished:  { type: Boolean, default: false },
  // Human-readable slug for portfolio URL: /p/harshm
  portfolioSlug:       {
    type: String,
    unique: true,
    sparse: true,   // sparse = allows multiple documents with no slug (null)
    lowercase: true,
    trim: true,
    match: [/^[a-z0-9_-]{3,30}$/, 'Slug must be 3-30 chars: letters, digits, - or _'],
  },

  createdAt: { type: Date, default: Date.now },
}, {
  // Ensure toJSON strips the password by default
  toJSON: {
    transform(doc, ret) {
      delete ret.password;
      return ret;
    },
  },
});

module.exports = mongoose.model('User', userSchema);
