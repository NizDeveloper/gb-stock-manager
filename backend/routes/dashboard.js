const express = require('express');
const router  = express.Router();
const { verifyToken } = require('../middleware/auth');
const { getDashboardStats, getLowStockProducts, getRecentProducts } = require('../controllers/dashboardController');

router.get('/stats', verifyToken, getDashboardStats);

router.get('/stats',           verifyToken, getDashboardStats);
router.get('/low-stock',       verifyToken, getLowStockProducts);
router.get('/recent-products', verifyToken, getRecentProducts);

module.exports = router;