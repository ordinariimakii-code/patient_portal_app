require('dotenv').config();
const sql = require('mssql');

async function testUsersAccess() {
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
        console.log('🔍 Testing Users Table Access');
        console.log('=================================');
        console.log(`Server: ${config.server}`);
        console.log(`Database: ${config.database}`);
        console.log(`User: ${config.user}`);
        console.log('=================================');
        
        const pool = await sql.connect(config);
        console.log('✅ Connected to database');
        
        // Test 1: Check if Users table exists
        console.log('\n📋 Checking if Users table exists...');
        const tableCheck = await pool.request().query(`
            SELECT COUNT(*) AS TableExists 
            FROM sys.tables 
            WHERE name = 'Users'
        `);
        
        if (tableCheck.recordset[0].TableExists === 0) {
            console.log('❌ Users table does NOT exist in this database');
            console.log('   Current database:', config.database);
            
            // Check what tables exist
            const tables = await pool.request().query(`
                SELECT name FROM sys.tables ORDER BY name
            `);
            console.log('\n📊 Tables in this database:');
            tables.recordset.forEach(t => console.log(`  - ${t.name}`));
            
            await pool.close();
            return;
        }
        
        console.log('✅ Users table exists');
        
        // Test 2: Get table structure
        console.log('\n📊 Users Table Structure:');
        const columns = await pool.request().query(`
            SELECT 
                COLUMN_NAME,
                DATA_TYPE,
                CHARACTER_MAXIMUM_LENGTH,
                IS_NULLABLE
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_NAME = 'Users'
            ORDER BY ORDINAL_POSITION
        `);
        
        columns.recordset.forEach(col => {
            console.log(`  - ${col.COLUMN_NAME} (${col.DATA_TYPE}) ${col.IS_NULLABLE === 'YES' ? 'NULL' : 'NOT NULL'}`);
        });
        
        // Test 3: Count users
        const count = await pool.request().query('SELECT COUNT(*) AS UserCount FROM Users');
        console.log(`\n📊 Total users: ${count.recordset[0].UserCount}`);
        
        // Test 4: Try to insert a test user (will be rolled back)
        console.log('\n🔄 Testing INSERT...');
        const testUser = {
            username: 'test_insert_' + Date.now(),
            email: 'test_' + Date.now() + '@test.com',
            passwordHash: 'test_hash',
            fullName: 'Test User',
            phoneNumber: '09123456789',
            hospNum: 'TEST123'
        };
        
        try {
            const insertResult = await pool.request()
                .input('username', sql.NVarChar, testUser.username)
                .input('email', sql.NVarChar, testUser.email)
                .input('passwordHash', sql.NVarChar, testUser.passwordHash)
                .input('fullName', sql.NVarChar, testUser.fullName)
                .input('phoneNumber', sql.NVarChar, testUser.phoneNumber)
                .input('hospNum', sql.NVarChar, testUser.hospNum)
                .input('isActive', sql.Bit, 1)
                .query(`
                    INSERT INTO Users (
                        Username, Email, PasswordHash, FullName, 
                        PhoneNumber, HospNum, IsActive, CreatedAt, UpdatedAt
                    )
                    OUTPUT INSERTED.UserID
                    VALUES (
                        @username, @email, @passwordHash, @fullName,
                        @phoneNumber, @hospNum, @isActive, GETDATE(), GETDATE()
                    )
                `);
            
            const userId = insertResult.recordset[0]?.UserID;
            console.log(`✅ INSERT successful! New UserID: ${userId}`);
            
            // Clean up - delete the test user
            await pool.request()
                .input('userId', sql.Int, userId)
                .query('DELETE FROM Users WHERE UserID = @userId');
            console.log('🧹 Test user deleted');
            
        } catch (insertError) {
            console.error('❌ INSERT failed:', insertError.message);
        }
        
        await pool.close();
        console.log('\n✅ Test complete');
        
    } catch (error) {
        console.error('❌ Error:', error.message);
        console.error('❌ Full error:', error);
    }
}

testUsersAccess();