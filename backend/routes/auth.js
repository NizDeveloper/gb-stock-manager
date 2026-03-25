const express = require('express');
const router = express.Router();

// TODO: login
router.post('/login', (req, res) => {
  res.json({ message: 'Login endpoint' });
});

module.exports = router;