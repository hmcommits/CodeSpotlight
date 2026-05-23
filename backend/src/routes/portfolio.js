const express = require('express');
const controller = require('../controllers/portfolioController');
const { authenticate } = require('../middleware/authMiddleware');

const router = express.Router();

router.get('/:slug', controller.getPortfolioBySlug);
router.patch('/me/portfolio', authenticate, controller.updatePortfolio);
router.post('/me/slug', authenticate, controller.claimSlug);

module.exports = router;
