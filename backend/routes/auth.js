const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { getPool, sql } = require('../database/db');
const auth = require('../middleware/auth');

// Register user
router.post('/register', async (req, res) => {
    let pool = null;
    
    try {
        const {
            username,
            email,
            password,
            fullName,
            phoneNumber,
            hospNum,
        } = req.body;
        
        console.log('📝 Registration attempt:', { username, email, fullName, hospNum });
        
        if (!username || !email || !password || !fullName || !phoneNumber) {
            return res.status(400).json({
                error: 'All required fields must be provided',
            });
        }
        
        // Get connection
        pool = await getPool();
        console.log('✅ Connected to PatientPortalDB');
        
        // Check if username or email exists
        const checkResult = await pool.request()
            .input('username', sql.NVarChar, username)
            .input('email', sql.NVarChar, email)
            .query(`
                SELECT Username, Email 
                FROM PortalUsers 
                WHERE Username = @username OR Email = @email
            `);
        
        if (checkResult.recordset.length > 0) {
            const existing = checkResult.recordset[0];
            if (existing.Username === username) {
                return res.status(400).json({ error: 'Username already exists' });
            }
            if (existing.Email === email) {
                return res.status(400).json({ error: 'Email already exists' });
            }
        }
        
        const salt = await bcrypt.genSalt(10);
        const passwordHash = await bcrypt.hash(password, salt);
        
        // Insert user
        const insertResult = await pool.request()
            .input('username', sql.NVarChar, username)
            .input('email', sql.NVarChar, email)
            .input('passwordHash', sql.NVarChar, passwordHash)
            .input('fullName', sql.NVarChar, fullName)
            .input('phoneNumber', sql.NVarChar, phoneNumber)
            .input('hospNum', sql.NVarChar, hospNum || null)
            .input('isActive', sql.Bit, true)
            .query(`
                INSERT INTO PortalUsers (
                    Username, 
                    Email, 
                    PasswordHash, 
                    FullName, 
                    PhoneNumber, 
                    HospNum, 
                    IsActive,
                    CreatedAt,
                    UpdatedAt
                )
                OUTPUT INSERTED.UserID, INSERTED.CreatedAt
                VALUES (
                    @username,
                    @email,
                    @passwordHash,
                    @fullName,
                    @phoneNumber,
                    @hospNum,
                    @isActive,
                    GETDATE(),
                    GETDATE()
                )
            `);
        
        console.log('✅ User inserted successfully');
        
        const userId = insertResult.recordset[0].UserID;
        const createdAt = insertResult.recordset[0].CreatedAt;
        
        const token = jwt.sign(
            { userId: userId, username: username },
            process.env.JWT_SECRET,
            { expiresIn: '7d' }
        );
        
        // Don't close the pool here - it's managed globally
        
        res.status(201).json({
            message: 'User registered successfully',
            token,
            user: {
                id: userId,
                username: username,
                email: email,
                fullName: fullName,
                phoneNumber: phoneNumber,
                hospNum: hospNum || null,
                isActive: true,
                createdAt: createdAt,
            },
        });
        
    } catch (error) {
        console.error('❌ Registration error:', error.message);
        console.error('❌ Full error:', error);
        res.status(500).json({
            error: 'Registration failed: ' + error.message,
        });
    }
    // Don't close pool here - let it be reused
});

// Login user
router.post('/login', async (req, res) => {
    let pool = null;
    
    try {
        const { usernameOrEmail, password } = req.body;
        
        if (!usernameOrEmail || !password) {
            return res.status(400).json({
                error: 'Username/Email and password are required',
            });
        }
        
        pool = await getPool();
        console.log('✅ Connected to PatientPortalDB for login');
        
        const result = await pool.request()
            .input('usernameOrEmail', sql.NVarChar, usernameOrEmail)
            .query(`
                SELECT 
                    UserID,
                    Username,
                    Email,
                    PasswordHash,
                    FullName,
                    PhoneNumber,
                    HospNum,
                    IsActive,
                    CreatedAt,
                    LastLogin
                FROM PortalUsers 
                WHERE Username = @usernameOrEmail OR Email = @usernameOrEmail
            `);
        
        if (result.recordset.length === 0) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }
        
        const user = result.recordset[0];
        
        if (!user.IsActive) {
            return res.status(403).json({ error: 'Account is deactivated' });
        }
        
        const isValidPassword = await bcrypt.compare(password, user.PasswordHash);
        
        if (!isValidPassword) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }
        
        await pool.request()
            .input('userId', sql.Int, user.UserID)
            .query(`UPDATE PortalUsers SET LastLogin = GETDATE() WHERE UserID = @userId`);
        
        const token = jwt.sign(
            { userId: user.UserID, username: user.Username },
            process.env.JWT_SECRET,
            { expiresIn: '7d' }
        );
        
        res.json({
            message: 'Login successful',
            token,
            user: {
                id: user.UserID,
                username: user.Username,
                email: user.Email,
                fullName: user.FullName,
                phoneNumber: user.PhoneNumber,
                hospNum: user.HospNum,
                isActive: user.IsActive,
                createdAt: user.CreatedAt,
                lastLogin: new Date(),
            },
        });
        
    } catch (error) {
        console.error('❌ Login error:', error.message);
        console.error('❌ Full error:', error);
        res.status(500).json({ error: 'Login failed: ' + error.message });
    }
});

// Get profile - protected route
router.get('/profile', auth, async (req, res) => {
    let pool = null;
    
    try {
        pool = await getPool();
        console.log('✅ Connected to PatientPortalDB for profile');
        
        const result = await pool.request()
            .input('userId', sql.Int, req.userId)
            .query(`
                SELECT 
                    UserID,
                    Username,
                    Email,
                    FullName,
                    PhoneNumber,
                    HospNum,
                    IsActive,
                    CreatedAt,
                    LastLogin
                FROM PortalUsers 
                WHERE UserID = @userId
            `);
        
        if (result.recordset.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }
        
        const user = result.recordset[0];
        
        res.json({
            user: {
                id: user.UserID,
                username: user.Username,
                email: user.Email,
                fullName: user.FullName,
                phoneNumber: user.PhoneNumber,
                hospNum: user.HospNum,
                isActive: user.IsActive,
                createdAt: user.CreatedAt,
                lastLogin: user.LastLogin,
            },
        });
        
    } catch (error) {
        console.error('Profile error:', error.message);
        res.status(500).json({ error: 'Failed to get profile' });
    }
});

// Update profile - protected route
router.put('/profile', auth, async (req, res) => {
    let pool = null;
    
    try {
        const { fullName, phoneNumber } = req.body;
        
        const updates = [];
        const inputs = {};
        
        if (fullName) {
            updates.push('FullName = @fullName');
            inputs.fullName = fullName;
        }
        if (phoneNumber) {
            updates.push('PhoneNumber = @phoneNumber');
            inputs.phoneNumber = phoneNumber;
        }
        
        if (updates.length === 0) {
            return res.status(400).json({ error: 'No fields to update' });
        }
        
        updates.push('UpdatedAt = GETDATE()');
        
        pool = await getPool();
        console.log('✅ Connected to PatientPortalDB for profile update');
        
        const request = pool.request();
        request.input('userId', sql.Int, req.userId);
        
        for (const [key, value] of Object.entries(inputs)) {
            request.input(key, sql.NVarChar, value);
        }
        
        await request.query(`UPDATE PortalUsers SET ${updates.join(', ')} WHERE UserID = @userId`);
        
        const result = await pool.request()
            .input('userId', sql.Int, req.userId)
            .query(`
                SELECT 
                    UserID,
                    Username,
                    Email,
                    FullName,
                    PhoneNumber,
                    HospNum,
                    IsActive,
                    CreatedAt,
                    LastLogin
                FROM PortalUsers 
                WHERE UserID = @userId
            `);
        
        const user = result.recordset[0];
        
        res.json({
            message: 'Profile updated successfully',
            user: {
                id: user.UserID,
                username: user.Username,
                email: user.Email,
                fullName: user.FullName,
                phoneNumber: user.PhoneNumber,
                hospNum: user.HospNum,
                isActive: user.IsActive,
                createdAt: user.CreatedAt,
                lastLogin: user.LastLogin,
            },
        });
        
    } catch (error) {
        console.error('Update profile error:', error.message);
        res.status(500).json({ error: 'Failed to update profile' });
    }
});

// Change password - protected route
router.post('/change-password', auth, async (req, res) => {
    let pool = null;
    
    try {
        const { currentPassword, newPassword } = req.body;
        
        if (!currentPassword || !newPassword) {
            return res.status(400).json({ error: 'Current and new password are required' });
        }
        
        if (newPassword.length < 6) {
            return res.status(400).json({ error: 'New password must be at least 6 characters' });
        }
        
        pool = await getPool();
        console.log('✅ Connected to PatientPortalDB for password change');
        
        const result = await pool.request()
            .input('userId', sql.Int, req.userId)
            .query(`SELECT PasswordHash FROM PortalUsers WHERE UserID = @userId`);
        
        if (result.recordset.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }
        
        const user = result.recordset[0];
        const isValidPassword = await bcrypt.compare(currentPassword, user.PasswordHash);
        
        if (!isValidPassword) {
            return res.status(401).json({ error: 'Current password is incorrect' });
        }
        
        const salt = await bcrypt.genSalt(10);
        const passwordHash = await bcrypt.hash(newPassword, salt);
        
        await pool.request()
            .input('passwordHash', sql.NVarChar, passwordHash)
            .input('userId', sql.Int, req.userId)
            .query(`UPDATE PortalUsers SET PasswordHash = @passwordHash, UpdatedAt = GETDATE() WHERE UserID = @userId`);
        
        res.json({ message: 'Password changed successfully' });
        
    } catch (error) {
        console.error('Change password error:', error.message);
        res.status(500).json({ error: 'Failed to change password' });
    }
});

// Logout - protected route
router.post('/logout', auth, (req, res) => {
    res.json({ message: 'Logout successful' });
});

module.exports = router;