require('dotenv').config();
const mongoose = require('mongoose');
const Project = require('../src/models/Project');

const OLD_USER_IDS = ['69f90d60306a4b98c0819df1', '69f98f30186749207a43c856'];

mongoose.connect(process.env.MONGODB_URI).then(async () => {
  const result = await Project.deleteMany({ userId: { $in: OLD_USER_IDS } });
  console.log('Deleted', result.deletedCount, 'orphan projects from old user IDs');
  await mongoose.disconnect();
  process.exit(0);
}).catch(e => {
  console.error(e.message);
  process.exit(1);
});
