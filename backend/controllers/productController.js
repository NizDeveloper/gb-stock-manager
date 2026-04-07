const db = require('../config/db');

// ─── Obtener todos los productos ───
const getProducts = (req, res) => {
  db.query(`
    SELECT p.*, c.name as category_name 
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.id
  `, (err, results) => {
    if (err) {
      console.log('❌ Error:', err);
      return res.status(500).json({ message: 'Error en el servidor' });
    }
    res.json(results);
  });
};

// ─── Obtener un producto por id ───
const getProductById = (req, res) => {
  const { id } = req.params;
  db.query('SELECT * FROM products WHERE id = ?', [id], (err, results) => {
    if (err) return res.status(500).json({ message: 'Error en el servidor' });
    if (results.length === 0) return res.status(404).json({ message: 'Producto no encontrado' });
    res.json(results[0]);
  });
};

// ─── Crear producto ───
const createProduct = (req, res) => {
  const { name, code, price, quantity_in_stock, category_id } = req.body;

  if (!name || !code || !price || !category_id) {
    return res.status(400).json({ message: 'Faltan campos requeridos' });
  }

  db.query(
    'INSERT INTO products (name, code, price, quantity_in_stock, category_id, created_by) VALUES (?, ?, ?, ?, ?, ?)',
    [name, code, price, quantity_in_stock || 0, category_id, req.user.id],
    (err, results) => {
      if (err) return res.status(500).json({ message: 'Error en el servidor' });
      res.status(201).json({ message: 'Producto creado', id: results.insertId });
    }
  );
};

// ─── Actualizar producto ───
const updateProduct = (req, res) => {
  const { id } = req.params;
  const { name, code, price, quantity_in_stock, category_id } = req.body;

  db.query(
    'UPDATE products SET name=?, code=?, price=?, quantity_in_stock=?, category_id=? WHERE id=?',
    [name, code, price, quantity_in_stock, category_id, id],
    (err) => {
      if (err) return res.status(500).json({ message: 'Error en el servidor' });
      res.json({ message: 'Producto actualizado' });
    }
  );
};

// ─── Eliminar producto ───
const deleteProduct = (req, res) => {
  const { id } = req.params;
  db.query('DELETE FROM products WHERE id = ?', [id], (err) => {
    if (err) return res.status(500).json({ message: 'Error en el servidor' });
    res.json({ message: 'Producto eliminado' });
  });
};

module.exports = { getProducts, getProductById, createProduct, updateProduct, deleteProduct };