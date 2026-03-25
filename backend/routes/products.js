const express = require('express');
const router = express.Router();

// TODO: CRUD productos
router.get('/', (req, res) => {
  res.json({ message: 'Products' });
});

module.exports = router;