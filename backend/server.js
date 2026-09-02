require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { closeConnections } = require('./database/db');

const app = express();

// Middleware
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

app.use(express.json());

app.use((req, res, next) => {
    // Set a timeout to prevent hanging connections
    res.setTimeout(30000, () => {
        console.log('⚠️ Request timeout, closing connection');
        res.status(408).json({ error: 'Request timeout' });
    });
    next();
});

// Routes
const authRoutes = require('./routes/auth');
const patientRoutes = require('./routes/patient');

app.use('/api', authRoutes);
app.use('/api', patientRoutes);

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    message: 'Server is running'
  });
});

// Add this after the health check endpoint
app.get('/api/test-tables', async (req, res) => {
    try {
        const { getPatientPool } = require('./database/db');
        const pool = await getPatientPool();
        
        // Test tbmaster
        const result = await pool.request().query('SELECT TOP 1 * FROM tbmaster');
        
        res.json({
            success: true,
            message: 'tbmaster table found',
            columns: Object.keys(result.recordset[0] || {})
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});
// Add this endpoint to reset connections
app.post('/api/reset-connections', async (req, res) => {
    try {
        const { closeConnections } = require('./database/db');
        await closeConnections();
        res.json({
            success: true,
            message: 'Connections reset successfully'
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});
// Error handling
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({
    error: 'Internal Server Error',
    message: err.message,
  });
});

// Start server
const PORT = process.env.PORT || 3000;
const server = app.listen(PORT, () => {
  console.log('=================================');
  console.log('🚀 Patient Portal Backend Started');
  console.log('=================================');
  console.log(`📍 Server running on: http://localhost:${PORT}`);
  console.log(`📋 API Endpoints:`);
  console.log(`   POST   /api/register`);
  console.log(`   POST   /api/login`);
  console.log(`   POST   /api/check-patient`);
  console.log(`   GET    /api/profile`);
  console.log(`   PUT    /api/profile`);
  console.log(`   POST   /api/change-password`);
  console.log(`   POST   /api/logout`);
  console.log(`   GET    /health`);
  console.log('=================================');
});

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('\n🛑 Shutting down gracefully...');
  await closeConnections();
  server.close(() => {
    console.log('✅ Server closed');
    process.exit(0);
  });
});

module.exports = app;