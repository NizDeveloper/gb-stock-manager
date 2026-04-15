const express = require('express');
const router  = express.Router();
const { verifyToken } = require('../middleware/auth');
const db = require('../config/db');

// ─── Movimientos por día (últimos 7 días) ───
router.get('/weekly-movements', verifyToken, (req, res) => {
  db.query(`
    SELECT
      DAYOFWEEK(created_at) as day_num,
      SUM(quantity) as total
    FROM stock_movements
    WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
    GROUP BY DAYOFWEEK(created_at)
    ORDER BY day_num ASC
  `, (err, results) => {
    if (err) return res.status(500).json({ message: 'Error en el servidor' });
    res.json(results);
  });
});

// ─── Resumen de movimientos ───
router.get('/movements-summary', verifyToken, (req, res) => {
  db.query(`
    SELECT
      type,
      COUNT(*) as total,
      SUM(quantity) as total_qty
    FROM stock_movements
    GROUP BY type
  `, (err, results) => {
    if (err) return res.status(500).json({ message: 'Error en el servidor' });
    res.json(results);
  });
});

// ─── Registrar movimiento ───
router.post('/movements', verifyToken, (req, res) => {
  const { product_id, type, quantity, notes } = req.body;
  if (!product_id || !type || !quantity) {
    return res.status(400).json({ message: 'Faltan campos requeridos' });
  }
  db.query(
    'INSERT INTO stock_movements (product_id, user_id, type, quantity, notes) VALUES (?, ?, ?, ?, ?)',
    [product_id, req.user.id, type, quantity, notes || null],
    (err, results) => {
      if (err) return res.status(500).json({ message: 'Error en el servidor' });
      res.status(201).json({ message: 'Movimiento registrado', id: results.insertId });
    }
  );
});

// ─── Historial de movimientos de un producto ───
router.get('/movements/:product_id', verifyToken, (req, res) => {
  const { product_id } = req.params;
  db.query(`
    SELECT
      sm.*,
      u.name as user_name
    FROM stock_movements sm
    LEFT JOIN users u ON sm.user_id = u.id
    WHERE sm.product_id = ?
    ORDER BY sm.created_at DESC
    LIMIT 20
  `, [product_id], (err, results) => {
    if (err) return res.status(500).json({ message: 'Error en el servidor' });
    res.json(results);
  });
});

module.exports = router;