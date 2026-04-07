const db = require('../config/db');

// ─── Stats generales ───
const getDashboardStats = (req, res) => {
  const queries = {
    totalProducts: 'SELECT COUNT(*) as total FROM products',
    totalValue:    'SELECT SUM(price * quantity_in_stock) as value FROM products',
    lowStock:      'SELECT COUNT(*) as total FROM products WHERE quantity_in_stock > 0 AND quantity_in_stock <= 10',
    outOfStock:    'SELECT COUNT(*) as total FROM products WHERE quantity_in_stock = 0',
  };

  const results = {};

  db.query(queries.totalProducts, (err, rows) => {
    if (err) return res.status(500).json({ message: 'Error en el servidor' });
    results.totalProducts = rows[0].total;

    db.query(queries.totalValue, (err, rows) => {
      if (err) return res.status(500).json({ message: 'Error en el servidor' });
      results.totalValue = rows[0].value || 0;

      db.query(queries.lowStock, (err, rows) => {
        if (err) return res.status(500).json({ message: 'Error en el servidor' });
        results.lowStock = rows[0].total;

        db.query(queries.outOfStock, (err, rows) => {
          if (err) return res.status(500).json({ message: 'Error en el servidor' });
          results.outOfStock = rows[0].total;

          res.json(results);
        });
      });
    });
  });
};

// ─── Productos con stock bajo ───
const getLowStockProducts = (req, res) => {
  db.query(`
    SELECT p.*, c.name as category_name 
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.id
    WHERE p.quantity_in_stock <= 10
    ORDER BY p.quantity_in_stock ASC
    LIMIT 5
  `, (err, results) => {
    if (err) return res.status(500).json({ message: 'Error en el servidor' });
    res.json(results);
  });
};

// ─── Productos recientes ───
const getRecentProducts = (req, res) => {
  db.query(`
    SELECT p.*, c.name as category_name 
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.id
    ORDER BY p.created_at DESC
    LIMIT 5
  `, (err, results) => {
    if (err) return res.status(500).json({ message: 'Error en el servidor' });
    res.json(results);
  });
};

module.exports = { getDashboardStats, getLowStockProducts, getRecentProducts };