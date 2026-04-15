const express = require('express');
const router  = express.Router();
const { verifyToken } = require('../middleware/auth');
const db = require('../config/db');

// ─── Obtener todas ───
router.get('/', verifyToken, (req, res) => {
  db.query('SELECT * FROM categories ORDER BY name', (err, results) => {
    if (err) return res.status(500).json({ message: 'Error en el servidor' });
    res.json(results);
  });
});

// ─── Crear categoría ───
router.post('/', verifyToken, (req, res) => {
  const { name, description } = req.body;
  if (!name) return res.status(400).json({ message: 'El nombre es requerido' });
  db.query(
    'INSERT INTO categories (name, description) VALUES (?, ?)',
    [name, description || null],
    (err, results) => {
      if (err) return res.status(500).json({ message: 'Error en el servidor' });
      res.status(201).json({ message: 'Categoría creada', id: results.insertId });
    }
  );
});

// ─── Actualizar categoría ───
router.put('/:id', verifyToken, (req, res) => {
  const { id } = req.params;
  const { name, description } = req.body;
  if (!name) return res.status(400).json({ message: 'El nombre es requerido' });
  db.query(
    'UPDATE categories SET name=?, description=? WHERE id=?',
    [name, description || null, id],
    (err) => {
      if (err) return res.status(500).json({ message: 'Error en el servidor' });
      res.json({ message: 'Categoría actualizada' });
    }
  );
});

// ─── Eliminar categoría ───
router.delete('/:id', verifyToken, (req, res) => {
  const { id } = req.params;
  db.query('DELETE FROM categories WHERE id=?', [id], (err) => {
    if (err) return res.status(500).json({ message: 'Error en el servidor' });
    res.json({ message: 'Categoría eliminada' });
  });
});

module.exports = router;