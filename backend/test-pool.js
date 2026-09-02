const { getPool, getPatientPool, closeConnections } = require('./database/db');

async function testPool() {
    console.log('🔍 Testing connection pool...');
    
    try {
        // Get connections
        const pool1 = await getPool();
        console.log('✅ Main pool connected');
        
        const pool2 = await getPatientPool();
        console.log('✅ Patient pool connected');
        
        console.log('✅ Both pools working!');
        
        // Don't close - let pools stay open
    } catch (error) {
        console.error('❌ Pool test failed:', error.message);
    }
}

testPool();

// After 5 seconds, test again
setTimeout(async () => {
    console.log('\n🔄 Testing again after 5 seconds...');
    try {
        const pool1 = await getPool();
        console.log('✅ Main pool still working');
        
        const pool2 = await getPatientPool();
        console.log('✅ Patient pool still working');
    } catch (error) {
        console.error('❌ Second test failed:', error.message);
    }
}, 5000);