require('dotenv').config();
const sql = require('mssql');

async function testSearch() {
    const config = {
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
    };

    try {
        console.log('🔍 Testing patient search...');
        const pool = await sql.connect(config);
        console.log('✅ Connected to Patient_Data');
        
        const searchPattern = 'LastName%';
        const result = await pool.request()
            .input('searchPattern', sql.NVarChar, searchPattern)
            .query(`
                SELECT TOP 5
                    HospNum,
                    LastName + ', ' + FirstName + ISNULL(' ' + MiddleName, '') AS FullName,
                    Cellnum AS PhoneNumber
                FROM tbmaster
                WHERE LastName + ', ' + FirstName + ISNULL(' ' + MiddleName, '') LIKE @searchPattern
            `);
        
        console.log(`📊 Found ${result.recordset.length} records`);
        console.log(result.recordset);
        await pool.close();
    } catch (error) {
        console.error('❌ Error:', error.message);
    }
}

testSearch();