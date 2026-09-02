const sql = require('mssql');

// Main Database - PatientPortalDB
const config = {
    user: process.env.DB_USER || 'sa',
    password: process.env.DB_PASSWORD || 'da',
    server: process.env.DB_HOST || '192.168.200.206',
    database: 'PatientPortalDB',
    port: 1433,
    options: {
        encrypt: false,
        trustServerCertificate: true,
        enableArithAbort: true,
    },
    pool: {
        max: 10,
        min: 0,
        idleTimeoutMillis: 30000,
        acquireTimeoutMillis: 30000,
    },
    connectionTimeout: 30000,
    requestTimeout: 30000,
};

// Patient Database - Patient_Data
const patientConfig = {
    user: process.env.DB_USER || 'sa',
    password: process.env.DB_PASSWORD || 'da',
    server: process.env.DB_HOST || '192.168.200.206',
    database: 'Patient_Data',
    port: 1433,
    options: {
        encrypt: false,
        trustServerCertificate: true,
        enableArithAbort: true,
    },
    pool: {
        max: 10,
        min: 0,
        idleTimeoutMillis: 30000,
        acquireTimeoutMillis: 30000,
    },
    connectionTimeout: 30000,
    requestTimeout: 30000,
};

let pool = null;
let patientPool = null;

// Connect to PatientPortalDB - Always re-connect to ensure fresh connection
async function getPool() {
    try {
        // Always close existing connection and create new one
        if (pool) {
            try {
                await pool.close();
            } catch (e) {
                // Ignore close errors
            }
            pool = null;
        }
        
        console.log('🔄 Connecting to PatientPortalDB...');
        console.log(`  Database: ${config.database}`);
        console.log(`  User: ${config.user}`);
        
        pool = await sql.connect(config);
        console.log('✅ Connected to PatientPortalDB');
        
        // Force database context
        await pool.request().query('USE [PatientPortalDB]');
        
        return pool;
    } catch (error) {
        console.error('❌ Database connection error:', error.message);
        pool = null;
        throw error;
    }
}

// Connect to Patient_Data - Always re-connect to ensure fresh connection
async function getPatientPool() {
    try {
        // Always close existing connection and create new one
        if (patientPool) {
            try {
                await patientPool.close();
            } catch (e) {
                // Ignore close errors
            }
            patientPool = null;
        }
        
        console.log('🔄 Connecting to Patient_Data...');
        console.log(`  Database: ${patientConfig.database}`);
        console.log(`  User: ${patientConfig.user}`);
        
        patientPool = await sql.connect(patientConfig);
        console.log('✅ Connected to Patient_Data');
        
        // Force database context
        await patientPool.request().query('USE [Patient_Data]');
        
        // Test if tbmaster exists
        try {
            const test = await patientPool.request().query('SELECT TOP 1 * FROM tbmaster');
            console.log('✅ tbmaster table accessible');
        } catch (err) {
            console.error('❌ tbmaster table error:', err.message);
            // Try alternative table names
            try {
                const test2 = await patientPool.request().query('SELECT TOP 1 * FROM tbMaster');
                console.log('✅ tbMaster table found (alternative name)');
            } catch (err2) {
                console.error('❌ No master table found');
            }
        }
        
        return patientPool;
    } catch (error) {
        console.error('❌ Patient database connection error:', error.message);
        patientPool = null;
        throw error;
    }
}

// Close all connections
async function closeConnections() {
    try {
        if (pool) {
            await pool.close();
            pool = null;
            console.log('🔒 Main pool closed');
        }
        if (patientPool) {
            await patientPool.close();
            patientPool = null;
            console.log('🔒 Patient pool closed');
        }
    } catch (error) {
        console.error('Error closing connections:', error);
    }
}

module.exports = {
    getPool,
    getPatientPool,
    closeConnections,
    sql,
};