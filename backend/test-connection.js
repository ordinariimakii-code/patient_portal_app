require('dotenv').config();
const sql = require('mssql');

async function testConnection() {
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

    try {
        console.log('=================================');
        console.log('🔍 Database Connection Test');
        console.log('=================================');
        console.log(`Server: ${config.server}`);
        console.log(`Database: ${config.database}`);
        console.log(`User: ${config.user}`);
        console.log('=================================');
        
        const pool = await sql.connect(config);
        console.log('✅ Connected successfully!');
        
        // Get current database
        const dbResult = await pool.request().query('SELECT DB_NAME() AS CurrentDB');
        console.log(`\n📊 Current Database: ${dbResult.recordset[0].CurrentDB}`);
        
        // Check if Users table exists in current database (FIXED - removed 'Exists')
        const tableCheck = await pool.request().query(`
            SELECT COUNT(*) AS TableCount
            FROM sys.tables 
            WHERE name = 'Users'
        `);
        
        if (tableCheck.recordset[0].TableCount > 0) {
            console.log('\n✅ Users table found in current database!');
            
            // Get table structure
            const columns = await pool.request().query(`
                SELECT COLUMN_NAME, DATA_TYPE 
                FROM INFORMATION_SCHEMA.COLUMNS 
                WHERE TABLE_NAME = 'Users'
            `);
            console.log('\n📊 Users table columns:');
            columns.recordset.forEach(col => {
                console.log(`  - ${col.COLUMN_NAME} (${col.DATA_TYPE})`);
            });
            
            // Count users
            const count = await pool.request().query('SELECT COUNT(*) AS UserCount FROM Users');
            console.log(`\n📊 Total users: ${count.recordset[0].UserCount}`);
            
        } else {
            console.log('\n❌ Users table NOT found in current database');
            console.log(`   Current database: ${dbResult.recordset[0].CurrentDB}`);
            
            // List all tables in current database
            const tables = await pool.request().query(`
                SELECT name FROM sys.tables ORDER BY name
            `);
            console.log('\n📋 Tables in current database:');
            tables.recordset.forEach(t => {
                console.log(`  - ${t.name}`);
            });
            
            console.log('\n💡 Tip: The Users table might be in a different database.');
            console.log('   Please check in SSMS which database contains the Users table.');
        }
        
        await pool.close();
        console.log('\n✅ Test complete');
        
    } catch (error) {
        console.error('❌ Connection failed:', error.message);
        console.error('❌ Full error:', error);
    }
}

testConnection();