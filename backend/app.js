const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });

const express = require('express');
const cors = require('cors');
const authRoutes = require('./routes/auth');
const productRoutes = require('./routes/products');
const dashboardRoutes = require('./routes/dashboard');
const categoryRoutes = require('./routes/categories');
const reportRoutes = require('./routes/reports');

const app = express();
// Middlewares
app.use(cors());
app.use(express.json());

// Rutas
app.use('/api/auth',      authRoutes);
app.use('/api/products',  productRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/reports', reportRoutes);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Servidor corriendo en http://localhost:${PORT}`);
});