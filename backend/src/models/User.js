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
  createdAt:   { type: Date, default: Date.now },
});

module.exports = mongoose.model('User', userSchema);
