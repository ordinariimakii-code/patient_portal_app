const sql = require('mssql');
require('dotenv').config();

const dbConfig = {
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    server: process.env.DB_SERVER,
    database: process.env.DB_NAME,
    options: {
        encrypt: true,
        trustServerCertificate: true,
        enableArithAbort: true
    }
};

async function testDatabase() {
    try {
        console.log('📋 Testing database connection...');
        console.log('Server:', dbConfig.server);
        console.log('Database:', dbConfig.database);
        console.log('User:', dbConfig.user || 'Windows Auth');
        
        const pool = await sql.connect(dbConfig);
        console.log('✅ Connected to SQL Server!');
        
        // Check if table exists
        const tableCheck = await pool.request().query(`
            SELECT COUNT(*) as count 
            FROM INFORMATION_SCHEMA.TABLES 
            WHERE TABLE_NAME = 'Users'
        `);
        
        if (tableCheck.recordset[0].count > 0) {
            console.log('✅ Users table exists');
        } else {
            console.log('❌ Users table does not exist!');
            console.log('Please run the CREATE TABLE script in SSMS');
        }
        
        await pool.close();
        console.log('✅ Test complete');
    } catch (err) {
        console.error('❌ Database test failed:', err.message);
        console.error('📝 Full error:', err);
    }
}

testDatabase();