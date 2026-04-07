const express = require('express');
const router  = express.Router();
const { verifyToken } = require('../middleware/auth');
const {
  getProducts,
  getProductById,
  createProduct,
  updateProduct,
  deleteProduct
} = require('../controllers/productController');

// ─── Todas las rutas protegidas ───
router.get('/',      verifyToken, getProducts);
router.get('/:id',   verifyToken, getProductById);
router.post('/',     verifyToken, createProduct);
router.put('/:id',   verifyToken, updateProduct);
router.delete('/:id',verifyToken, deleteProduct);

module.exports = router;