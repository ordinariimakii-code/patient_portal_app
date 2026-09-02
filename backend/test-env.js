require('dotenv').config();

console.log('=================================');
console.log('🔍 ENVIRONMENT VARIABLES TEST');
console.log('=================================');

console.log('📋 .env Variables:');
console.log(`  PORT: ${process.env.PORT || '❌ NOT SET'}`);
console.log(`  JWT_SECRET: ${process.env.JWT_SECRET ? '✅ SET' : '❌ NOT SET'}`);
console.log(`  DB_HOST: ${process.env.DB_HOST || '❌ NOT SET'}`);
console.log(`  DB_USER: ${process.env.DB_USER || '❌ NOT SET'}`);
console.log(`  DB_PASSWORD: ${process.env.DB_PASSWORD ? '✅ SET' : '❌ NOT SET'}`);
console.log(`  DB_DATABASE: ${process.env.DB_DATABASE || '❌ NOT SET'}`);
console.log(`  DB_PATIENT_DATABASE: ${process.env.DB_PATIENT_DATABASE || '❌ NOT SET'}`);
console.log(`  DB_PORT: ${process.env.DB_PORT || '❌ NOT SET'}`);
console.log('=================================');

// Test SQL Server Connection
const sql = require('mssql');

async function testSQL() {
    const config = {
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
        server: process.env.DB_HOST,
        database: process.env.DB_DATABASE,
        port: parseInt(process.env.DB_PORT) || 1433,
        options: {
            encrypt: false,
            trustServerCertificate: true,
            enableArithAbort: true,
        },
    };

    console.log('🔄 Testing SQL Server connection...');
    console.log(`  Server: ${config.server}`);
    console.log(`  Database: ${config.database}`);
    console.log(`  User: ${config.user}`);
    console.log(`  Port: ${config.port}`);

    try {
        const pool = await sql.connect(config);
        console.log('✅ Connected successfully!');

        const result = await pool.request().query('SELECT @@VERSION AS Version');
        console.log('📊 SQL Server:', result.recordset[0].Version.substring(0, 60) + '...');

        // Test Patient_Data
        console.log('\n🔄 Testing Patient_Data connection...');
        const patientConfig = {
            ...config,
            database: process.env.DB_PATIENT_DATABASE || 'Patient_Data',
        };
        const patientPool = await sql.connect(patientConfig);
        console.log('✅ Connected to Patient_Data!');

        const masterResult = await patientPool.request().query('SELECT COUNT(*) AS Count FROM tbmaster');
        console.log(`📊 tbmaster has ${masterResult.recordset[0].Count} records`);

        await patientPool.close();
        await pool.close();
        console.log('\n✅ All tests passed!');
    } catch (error) {
        console.error('❌ Connection failed:', error.message);
    }
}

testSQL();