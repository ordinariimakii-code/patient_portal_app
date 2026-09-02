const express = require('express');
const router = express.Router();
const authenticateToken = require('../middleware/auth');
const { getPatientPool, sql } = require('../database/db');

// Check patient in tbmaster
router.post('/check-patient', async (req, res) => {
    let pool = null;
    
    try {
        const { fullName } = req.body;
        
        console.log('🔍 Searching for patient:', fullName);
        
        if (!fullName || fullName.length < 3) {
            return res.status(400).json({
                success: false,
                error: 'Please enter at least 3 characters',
                patients: [],
            });
        }
        
        // Get a fresh connection
        pool = await getPatientPool();
        console.log('✅ Connected to Patient_Data for tbmaster');
        
        const searchPattern = `${fullName}%`;
        
        // Try with tbmaster (lowercase)
        let result;
        try {
            result = await pool.request()
                .input('searchPattern', sql.NVarChar, searchPattern)
                .query(`
                    SELECT TOP 20
                        HospNum,
                        LastName + ', ' + FirstName + ISNULL(' ' + MiddleName, '') AS FullName,
                        FirstName,
                        MiddleName,
                        LastName,
                        Cellnum AS PhoneNumber
                    FROM tbmaster
                    WHERE LastName + ', ' + FirstName + ISNULL(' ' + MiddleName, '') LIKE @searchPattern
                    ORDER BY LastName, FirstName
                `);
        } catch (tableError) {
            // If tbmaster fails, try tbMaster (capital M)
            console.log('⚠️ tbmaster not found, trying tbMaster...');
            try {
                result = await pool.request()
                    .input('searchPattern', sql.NVarChar, searchPattern)
                    .query(`
                        SELECT TOP 20
                            HospNum,
                            LastName + ', ' + FirstName + ISNULL(' ' + MiddleName, '') AS FullName,
                            FirstName,
                            MiddleName,
                            LastName,
                            Cellnum AS PhoneNumber
                        FROM tbMaster
                        WHERE LastName + ', ' + FirstName + ISNULL(' ' + MiddleName, '') LIKE @searchPattern
                        ORDER BY LastName, FirstName
                    `);
            } catch (tableError2) {
                // If both fail, try the original query without the full name concatenation
                console.log('⚠️ Full name search failed, trying simple search...');
                result = await pool.request()
                    .input('searchPattern', sql.NVarChar, searchPattern)
                    .query(`
                        SELECT TOP 20
                            HospNum,
                            LastName + ', ' + FirstName + ISNULL(' ' + MiddleName, '') AS FullName,
                            FirstName,
                            MiddleName,
                            LastName,
                            Cellnum AS PhoneNumber
                        FROM tbmaster
                        WHERE LastName LIKE @searchPattern 
                           OR FirstName LIKE @searchPattern
                        ORDER BY LastName, FirstName
                    `);
            }
        }
        
        console.log('📊 Found records:', result.recordset.length);
        
        res.json({
            success: true,
            patients: result.recordset,
            message: `${result.recordset.length} patient(s) found`,
        });
        
    } catch (error) {
        console.error('❌ Error checking patient:', error.message);
        console.error('❌ Full error:', error);
        res.status(500).json({
            success: false,
            error: 'Database error: ' + error.message,
            patients: [],
        });
    }
});
// Get patient by HospNum
router.get('/patient/:hospNum', async (req, res) => {
    let pool = null;
    
    try {
        const { hospNum } = req.params;
        
        console.log('🔍 Fetching patient by HospNum:', hospNum);
        
        if (!hospNum) {
            return res.status(400).json({
                success: false,
                error: 'HospNum is required',
            });
        }
        
        pool = await getPatientPool();
        console.log('✅ Connected to Patient_Data');
        
        const result = await pool.request()
            .input('hospNum', sql.NVarChar, hospNum)
            .query(`
                SELECT 
                    HospNum,
                    LastName + ', ' + FirstName + ISNULL(' ' + MiddleName, '') AS FullName,
                    FirstName,
                    MiddleName,
                    LastName,
                    Cellnum AS PhoneNumber,
                    BirthDate,
                    Age,
                    Sex,
                    BloodType,
                    CivilStatus,
                    Occupation,
                    HouseStreet,
                    Barangay,
                    CityMunicipalityPSGC,
                    Email
                FROM tbmaster
                WHERE HospNum = @hospNum
            `);
        
        if (result.recordset.length > 0) {
            res.json({
                success: true,
                patient: result.recordset[0],
            });
        } else {
            res.json({
                success: false,
                error: 'Patient not found',
            });
        }
        
    } catch (error) {
        console.error('❌ Error fetching patient:', error.message);
        res.status(500).json({
            success: false,
            error: 'Database error: ' + error.message,
        });
    }
});

// Get patient by HospNum
router.get('/patient/:hospnum', authenticateToken, async (req, res) => {
  try {
    const { hospnum } = req.params;
    
    const pool = await getPatientPool();
    
    const query = `
      SELECT 
        HospNum,
        LastName,
        FirstName,
        MiddleName,
        BirthDate,
        Sex,
        CivilStatus,
        Address,
        PhoneNumber
      FROM tbmaster
      WHERE HospNum = @Hospnum
    `;

    const result = await pool.request()
      .input('Hospnum', sql.VarChar, hospnum)
      .query(query);

    if (result.recordset.length === 0) {
      return res.status(404).json({ error: 'Patient not found' });
    }

    res.json({ patient: result.recordset[0] });
  } catch (error) {
    console.error('Error fetching patient:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});


// Get clinical summary for a patient
router.get('/clinical-summary/:hospnum', authenticateToken, async (req, res) => {
  try {
    const { hospnum } = req.params;
    
    console.log(`🔍 Fetching clinical summary for HospNum: ${hospnum}`);
    
    const pool = await getPatientPool();
    
    // First, check if patient exists in tbmaster
    const checkPatientQuery = `
      SELECT HospNum, LastName, FirstName 
      FROM tbmaster 
      WHERE HospNum = @Hospnum
    `;
    
    const patientCheck = await pool.request()
      .input('Hospnum', sql.VarChar, hospnum)
      .query(checkPatientQuery);
    
    if (patientCheck.recordset.length === 0) {
      console.log(`❌ Patient not found with HospNum: ${hospnum}`);
      return res.status(404).json({ 
        success: false,
        message: `Patient not found with HospNum: ${hospnum}`
      });
    }
    
    console.log(`✅ Patient found: ${patientCheck.recordset[0].FirstName} ${patientCheck.recordset[0].LastName}`);
    
    // Get the latest admission
    const latestAdmissionQuery = `
      WITH CombinedRecords AS (
        SELECT 
          IdNum AS AdmissionNo, 
          Admdate AS AdmissionDateTime,
          DcrDate AS DischargedDateTime,
          RoomID AS Room,
          'In-Patient' AS AdmissionType
        FROM tbpatient
        WHERE Hospnum = @Hospnum 
          AND Admdate IS NOT NULL

        UNION ALL

        SELECT 
          IdNum AS AdmissionNo, 
          Admdate AS AdmissionDateTime,
          DcrDate AS DischargedDateTime,
          'ER/OPD' AS Room,
          'Out-Patient' AS AdmissionType
        FROM tboutpatient
        WHERE Hospnum = @Hospnum 
          AND Admdate IS NOT NULL
      )
      SELECT TOP 1
        AdmissionNo,
        AdmissionDateTime,
        DischargedDateTime,
        Room,
        AdmissionType
      FROM CombinedRecords
      ORDER BY AdmissionDateTime DESC;
    `;

    console.log(`📋 Getting latest admission for patient...`);
    
    const latestAdmission = await pool.request()
      .input('Hospnum', sql.VarChar, hospnum)
      .query(latestAdmissionQuery);

    if (!latestAdmission.recordset[0]) {
      console.log(`❌ No admission records found for HospNum: ${hospnum}`);
      return res.status(404).json({ 
        success: false,
        message: 'No admission records found for this patient' 
      });
    }

    const idNum = latestAdmission.recordset[0].AdmissionNo;
    console.log(`📋 Latest Admission No: ${idNum}, Type: ${latestAdmission.recordset[0].AdmissionType}`);
    
    // Now get the clinical summary data - REMOVED the DECLARE statement
    const clinicalSummaryQuery = `
      IF RIGHT(@IDNum, 1) = 'B' 
      BEGIN
        SELECT
          M.LastName, M.FirstName, M.MiddleName,
          dbo.Compute_Age(M.BirthDate, A.AdmDate) AS Age,
          CASE M.Sex
            WHEN 'M' THEN 'MALE'
            WHEN 'F' THEN 'FEMALE'
          END AS Sex,
          CASE M.CivilStatus
            WHEN '0' THEN 'SINGLE'
            WHEN '1' THEN 'MARRIED'
            WHEN '2' THEN 'WIDOW'
            WHEN '3' THEN 'SEPARATED'
            WHEN '4' THEN 'CHILD'
          END AS CivilStatus,
          A.IDNum AS AdmissionNumber,
          A.HospNum AS HospitalNumber,
          'ER/OPD' AS Room,
          M.BirthDate AS BirthDate,
          A.AdmDate AS AdmissionDate,
          A.DcrDate AS DischargeDate,
          CASE A.DoctorID1
            WHEN NULL THEN ''
            ELSE dbo.fn_GetDrName(A.DoctorID1)
          END AS AttendingDoctor,
          CASE A.DoctorID2
            WHEN NULL THEN ''
            ELSE dbo.fn_GetDrName(A.DoctorID2)
          END AS AdmittingDoctor,
          '' AS AdmittingDiagnosis,
          H.ChiefComplaints AS ChiefComplaints,
          H.FINDINGS AS FinalDiagnosis,
          H.BloodPressure AS BloodPressure,
          H.Temperature AS Temperature,
          H.Weight AS Weight,
          dbo.fn_GetCompleteAddress(A.Hospnum) AS Address
        FROM tbOutPatient A
          INNER JOIN tbmaster M ON A.Hospnum = M.Hospnum
          LEFT OUTER JOIN tbOutPatientHistory H ON A.IDNum = H.IDNum
        WHERE A.IDNum = @IDNum;
      END
      ELSE
      BEGIN
        SELECT
          M.LastName, M.FirstName, M.MiddleName,
          dbo.Compute_Age(M.BirthDate, A.AdmDate) AS Age,
          CASE M.Sex
            WHEN 'M' THEN 'MALE'
            WHEN 'F' THEN 'FEMALE'
          END AS Sex,
          CASE M.CivilStatus
            WHEN '0' THEN 'SINGLE'
            WHEN '1' THEN 'MARRIED'
            WHEN '2' THEN 'WIDOW'
            WHEN '3' THEN 'SEPARATED'
            WHEN '4' THEN 'CHILD'
          END AS CivilStatus,
          A.IDNum AS AdmissionNumber,
          A.HospNum AS HospitalNumber,
          A.RoomID AS Room,
          M.BirthDate AS BirthDate,
          A.AdmDate AS AdmissionDate,
          A.DcrDate AS DischargeDate,
          CASE A.AttendingDR1
            WHEN NULL THEN ''
            ELSE dbo.fn_GetDrName(A.AttendingDR1)
          END AS AttendingDoctor,
          CASE A.AdmittingDR
            WHEN NULL THEN ''
            ELSE dbo.fn_GetDrName(A.AdmittingDR)
          END AS AdmittingDoctor,
          H.ADMDiagnosis AS AdmittingDiagnosis,
          H.ChiefComplaint AS ChiefComplaints,
          H.FinalDiagnosis AS FinalDiagnosis,
          '' AS BloodPressure,
          '' AS Temperature,
          H.Weight AS Weight,
          dbo.fn_GetCompleteAddress(A.Hospnum) AS Address
        FROM tbPatient A
          INNER JOIN tbmaster M ON A.Hospnum = M.Hospnum
          LEFT OUTER JOIN tbPatientHistory H ON A.IDNum = H.IDNum
        WHERE A.IDNum = @IDNum;
      END
    `;

    console.log(`📋 Fetching clinical summary data for IDNum: ${idNum}`);
    
    const clinicalData = await pool.request()
      .input('IDNum', sql.VarChar, idNum)  // Parameter name matches the one in the query
      .query(clinicalSummaryQuery);

    const result = {
      admissionInfo: latestAdmission.recordset[0],
      clinicalSummary: clinicalData.recordset[0] || {}
    };

    console.log(`✅ Clinical summary fetched successfully`);
    res.json(result);
  } catch (error) {
    console.error('❌ Error fetching clinical summary:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error',
      message: error.message 
    });
  }
});

// Check patient in tbmaster
router.post('/check-patient', async (req, res) => {
    let pool = null;
    
    try {
        const { fullName } = req.body;
        
        console.log('🔍 Searching for patient:', fullName);
        
        if (!fullName || fullName.length < 3) {
            return res.status(400).json({
                success: false,
                error: 'Please enter at least 3 characters',
                patients: [],
            });
        }
        
        pool = await getPatientPool();
        console.log('✅ Connected to Patient_Data for tbmaster');
        
        const searchPattern = fullName + '%';
        
        let result;
        try {
            result = await pool.request()
                .input('searchPattern', sql.NVarChar, searchPattern)
                .query(`
                    SELECT TOP 20
                        HospNum,
                        LastName + ', ' + FirstName + ISNULL(' ' + MiddleName, '') AS FullName,
                        FirstName,
                        MiddleName,
                        LastName,
                        Cellnum AS PhoneNumber
                    FROM tbmaster
                    WHERE LastName + ', ' + FirstName + ISNULL(' ' + MiddleName, '') LIKE @searchPattern
                    ORDER BY LastName, FirstName
                `);
        } catch (tableError) {
            console.log('⚠️ tbmaster not found, trying tbMaster...');
            try {
                result = await pool.request()
                    .input('searchPattern', sql.NVarChar, searchPattern)
                    .query(`
                        SELECT TOP 20
                            HospNum,
                            LastName + ', ' + FirstName + ISNULL(' ' + MiddleName, '') AS FullName,
                            FirstName,
                            MiddleName,
                            LastName,
                            Cellnum AS PhoneNumber
                        FROM tbMaster
                        WHERE LastName + ', ' + FirstName + ISNULL(' ' + MiddleName, '') LIKE @searchPattern
                        ORDER BY LastName, FirstName
                    `);
            } catch (tableError2) {
                console.log('⚠️ Full name search failed, trying simple search...');
                result = await pool.request()
                    .input('searchPattern', sql.NVarChar, searchPattern)
                    .query(`
                        SELECT TOP 20
                            HospNum,
                            LastName + ', ' + FirstName + ISNULL(' ' + MiddleName, '') AS FullName,
                            FirstName,
                            MiddleName,
                            LastName,
                            Cellnum AS PhoneNumber
                        FROM tbmaster
                        WHERE LastName LIKE @searchPattern 
                           OR FirstName LIKE @searchPattern
                        ORDER BY LastName, FirstName
                    `);
            }
        }
        
        console.log('📊 Found records:', result.recordset.length);
        
        res.json({
            success: true,
            patients: result.recordset,
            message: result.recordset.length + ' patient(s) found',
        });
        
    } catch (error) {
        console.error('❌ Error checking patient:', error.message);
        console.error('❌ Full error:', error);
        res.status(500).json({
            success: false,
            error: 'Database error: ' + error.message,
            patients: [],
        });
    }
});

// Get patient by HospNum
router.get('/patient/:hospNum', async (req, res) => {
    let pool = null;
    
    try {
        const { hospNum } = req.params;
        
        console.log('🔍 Fetching patient by HospNum:', hospNum);
        
        if (!hospNum) {
            return res.status(400).json({
                success: false,
                error: 'HospNum is required',
            });
        }
        
        pool = await getPatientPool();
        console.log('✅ Connected to Patient_Data');
        
        const result = await pool.request()
            .input('hospNum', sql.NVarChar, hospNum)
            .query(`
                SELECT 
                    HospNum,
                    LastName + ', ' + FirstName + ISNULL(' ' + MiddleName, '') AS FullName,
                    FirstName,
                    MiddleName,
                    LastName,
                    Cellnum AS PhoneNumber,
                    BirthDate,
                    Age,
                    Sex,
                    BloodType,
                    CivilStatus,
                    Occupation,
                    HouseStreet,
                    Barangay,
                    CityMunicipalityPSGC,
                    Email
                FROM tbmaster
                WHERE HospNum = @hospNum
            `);
        
        if (result.recordset.length > 0) {
            res.json({
                success: true,
                patient: result.recordset[0],
            });
        } else {
            res.json({
                success: false,
                error: 'Patient not found',
            });
        }
        
    } catch (error) {
        console.error('❌ Error fetching patient:', error.message);
        res.status(500).json({
            success: false,
            error: 'Database error: ' + error.message,
        });
    }
});

// Get patient by HospNum (authenticated)
router.get('/patient/:hospnum', authenticateToken, async function(req, res) {
  try {
    var hospnum = req.params.hospnum;
    
    var pool = await getPatientPool();
    
    var query = `
      SELECT 
        HospNum,
        LastName,
        FirstName,
        MiddleName,
        BirthDate,
        Sex,
        CivilStatus,
        Address,
        PhoneNumber
      FROM tbmaster
      WHERE HospNum = @Hospnum
    `;

    var result = await pool.request()
      .input('Hospnum', sql.VarChar, hospnum)
      .query(query);

    if (result.recordset.length === 0) {
      return res.status(404).json({ error: 'Patient not found' });
    }

    res.json({ patient: result.recordset[0] });
  } catch (error) {
    console.error('Error fetching patient:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get clinical summary for a patient
router.get('/clinical-summary/:hospnum', authenticateToken, async function(req, res) {
  try {
    var hospnum = req.params.hospnum;
    
    console.log('🔍 Fetching clinical summary for HospNum:', hospnum);
    
    var pool = await getPatientPool();
    
    var checkPatientQuery = `
      SELECT HospNum, LastName, FirstName 
      FROM tbmaster 
      WHERE HospNum = @Hospnum
    `;
    
    var patientCheck = await pool.request()
      .input('Hospnum', sql.VarChar, hospnum)
      .query(checkPatientQuery);
    
    if (patientCheck.recordset.length === 0) {
      console.log('❌ Patient not found with HospNum:', hospnum);
      return res.status(404).json({ 
        success: false,
        message: 'Patient not found with HospNum: ' + hospnum
      });
    }
    
    console.log('✅ Patient found:', patientCheck.recordset[0].FirstName, patientCheck.recordset[0].LastName);
    
    var latestAdmissionQuery = `
      WITH CombinedRecords AS (
        SELECT 
          IdNum AS AdmissionNo, 
          Admdate AS AdmissionDateTime,
          DcrDate AS DischargedDateTime,
          RoomID AS Room,
          'In-Patient' AS AdmissionType
        FROM tbpatient
        WHERE Hospnum = @Hospnum 
          AND Admdate IS NOT NULL

        UNION ALL

        SELECT 
          IdNum AS AdmissionNo, 
          Admdate AS AdmissionDateTime,
          DcrDate AS DischargedDateTime,
          'ER/OPD' AS Room,
          'Out-Patient' AS AdmissionType
        FROM tboutpatient
        WHERE Hospnum = @Hospnum 
          AND Admdate IS NOT NULL
      )
      SELECT TOP 1
        AdmissionNo,
        AdmissionDateTime,
        DischargedDateTime,
        Room,
        AdmissionType
      FROM CombinedRecords
      ORDER BY AdmissionDateTime DESC;
    `;

    console.log('📋 Getting latest admission for patient...');
    
    var latestAdmission = await pool.request()
      .input('Hospnum', sql.VarChar, hospnum)
      .query(latestAdmissionQuery);

    if (!latestAdmission.recordset[0]) {
      console.log('❌ No admission records found for HospNum:', hospnum);
      return res.status(404).json({ 
        success: false,
        message: 'No admission records found for this patient' 
      });
    }

    var idNum = latestAdmission.recordset[0].AdmissionNo;
    console.log('📋 Latest Admission No:', idNum, 'Type:', latestAdmission.recordset[0].AdmissionType);
    
    var clinicalSummaryQuery = `
      IF RIGHT(@IDNum, 1) = 'B' 
      BEGIN
        SELECT
          M.LastName, M.FirstName, M.MiddleName,
          dbo.Compute_Age(M.BirthDate, A.AdmDate) AS Age,
          CASE M.Sex
            WHEN 'M' THEN 'MALE'
            WHEN 'F' THEN 'FEMALE'
          END AS Sex,
          CASE M.CivilStatus
            WHEN '0' THEN 'SINGLE'
            WHEN '1' THEN 'MARRIED'
            WHEN '2' THEN 'WIDOW'
            WHEN '3' THEN 'SEPARATED'
            WHEN '4' THEN 'CHILD'
          END AS CivilStatus,
          A.IDNum AS AdmissionNumber,
          A.HospNum AS HospitalNumber,
          'ER/OPD' AS Room,
          M.BirthDate AS BirthDate,
          A.AdmDate AS AdmissionDate,
          A.DcrDate AS DischargeDate,
          CASE A.DoctorID1
            WHEN NULL THEN ''
            ELSE dbo.fn_GetDrName(A.DoctorID1)
          END AS AttendingDoctor,
          CASE A.DoctorID2
            WHEN NULL THEN ''
            ELSE dbo.fn_GetDrName(A.DoctorID2)
          END AS AdmittingDoctor,
          '' AS AdmittingDiagnosis,
          H.ChiefComplaints AS ChiefComplaints,
          H.FINDINGS AS FinalDiagnosis,
          H.BloodPressure AS BloodPressure,
          H.Temperature AS Temperature,
          H.Weight AS Weight,
          dbo.fn_GetCompleteAddress(A.Hospnum) AS Address
        FROM tbOutPatient A
          INNER JOIN tbmaster M ON A.Hospnum = M.Hospnum
          LEFT OUTER JOIN tbOutPatientHistory H ON A.IDNum = H.IDNum
        WHERE A.IDNum = @IDNum;
      END
      ELSE
      BEGIN
        SELECT
          M.LastName, M.FirstName, M.MiddleName,
          dbo.Compute_Age(M.BirthDate, A.AdmDate) AS Age,
          CASE M.Sex
            WHEN 'M' THEN 'MALE'
            WHEN 'F' THEN 'FEMALE'
          END AS Sex,
          CASE M.CivilStatus
            WHEN '0' THEN 'SINGLE'
            WHEN '1' THEN 'MARRIED'
            WHEN '2' THEN 'WIDOW'
            WHEN '3' THEN 'SEPARATED'
            WHEN '4' THEN 'CHILD'
          END AS CivilStatus,
          A.IDNum AS AdmissionNumber,
          A.HospNum AS HospitalNumber,
          A.RoomID AS Room,
          M.BirthDate AS BirthDate,
          A.AdmDate AS AdmissionDate,
          A.DcrDate AS DischargeDate,
          CASE A.AttendingDR1
            WHEN NULL THEN ''
            ELSE dbo.fn_GetDrName(A.AttendingDR1)
          END AS AttendingDoctor,
          CASE A.AdmittingDR
            WHEN NULL THEN ''
            ELSE dbo.fn_GetDrName(A.AdmittingDR)
          END AS AdmittingDoctor,
          H.ADMDiagnosis AS AdmittingDiagnosis,
          H.ChiefComplaint AS ChiefComplaints,
          H.FinalDiagnosis AS FinalDiagnosis,
          '' AS BloodPressure,
          '' AS Temperature,
          H.Weight AS Weight,
          dbo.fn_GetCompleteAddress(A.Hospnum) AS Address
        FROM tbPatient A
          INNER JOIN tbmaster M ON A.Hospnum = M.Hospnum
          LEFT OUTER JOIN tbPatientHistory H ON A.IDNum = H.IDNum
        WHERE A.IDNum = @IDNum;
      END
    `;

    console.log('📋 Fetching clinical summary data for IDNum:', idNum);
    
    var clinicalData = await pool.request()
      .input('IDNum', sql.VarChar, idNum)
      .query(clinicalSummaryQuery);

    var result = {
      admissionInfo: latestAdmission.recordset[0],
      clinicalSummary: clinicalData.recordset[0] || {}
    };

    console.log('✅ Clinical summary fetched successfully');
    res.json(result);
  } catch (error) {
    console.error('❌ Error fetching clinical summary:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error',
      message: error.message 
    });
  }
});

function cleanRtfText(rtfText) {
  if (!rtfText) return '';
  
  let cleanText = rtfText;
  
  // Step 1: Remove RTF formatting codes
  cleanText = cleanText.replace(/\\[a-zA-Z]+[\d]*/g, ' ');
  cleanText = cleanText.replace(/\\'[0-9a-f]{2}/g, ' ');
  cleanText = cleanText.replace(/\\u\d+\?/g, ' ');
  cleanText = cleanText.replace(/[{}]/g, ' ');
  
  // Step 2: Remove font information
  cleanText = cleanText.replace(/[A-Za-z\s]+Sans\s+Serif;?/g, '');
  cleanText = cleanText.replace(/[A-Za-z\s]+Serif;?/g, '');
  cleanText = cleanText.replace(/[A-Za-z\s]+Sans;?/g, '');
  
  // Step 3: Remove leading numbers (like "410 24")
  cleanText = cleanText.replace(/^\d+\s+\d+\s+/, '');
  
  // Step 4: Remove unnecessary phrases
  cleanText = cleanText.replace(/Thanks\s+for\s+referring\.?/gi, '');
  cleanText = cleanText.replace(/Thank\s+you\s+for\s+the\s+referral\.?/gi, '');
  cleanText = cleanText.replace(/Please\s+refer\s+for\s+further\s+management\.?/gi, '');
  cleanText = cleanText.replace(/For\s+further\s+referral\.?/gi, '');
  cleanText = cleanText.replace(/Kindly\s+refer\.?/gi, '');
  
  // Step 5: Remove multiple spaces
  cleanText = cleanText.replace(/\s+/g, ' ');
  
  // Step 6: Format the text
  cleanText = cleanText.replace(/IMPRESSION\s*:/gi, '\n\nIMPRESSION:');
  cleanText = cleanText.replace(/INTERPRETATION\s*:/gi, '\n\nINTERPRETATION:');
  cleanText = cleanText.replace(/FINDINGS\s*:/gi, '\n\nFINDINGS:');
  cleanText = cleanText.replace(/CONCLUSION\s*:/gi, '\n\nCONCLUSION:');
  cleanText = cleanText.replace(/RECOMMENDATION\s*:/gi, '\n\nRECOMMENDATION:');
  
  // Step 7: Clean up extra punctuation
  cleanText = cleanText.replace(/\.\s*\./g, '.');
  cleanText = cleanText.replace(/,\s*,/g, ',');
  
  // Step 8: Clean up
  cleanText = cleanText.replace(/\s+/g, ' ');
  cleanText = cleanText.replace(/ \n/g, '\n');
  cleanText = cleanText.replace(/\n /g, '\n');
  cleanText = cleanText.replace(/\n{3,}/g, '\n\n');
  cleanText = cleanText.replace(/[\\]/g, '');
  
  return cleanText.trim();
}
// Get latest laboratory results for a patient
router.get('/latest-results/:hospnum', authenticateToken, async function(req, res) {
  try {
    var hospnum = req.params.hospnum;
    
    console.log('🔍 Fetching latest results for HospNum:', hospnum);
    
    var pool = await getPatientPool();
    
    var getIdNumQuery = `
      SELECT TOP 1 IdNum 
      FROM tbpatient 
      WHERE Hospnum = @Hospnum 
        AND Admdate IS NOT NULL
      ORDER BY Admdate DESC
    `;
    
    var idNumResult = await pool.request()
      .input('Hospnum', sql.VarChar, hospnum)
      .query(getIdNumQuery);
    
    if (idNumResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No admission records found for this patient'
      });
    }
    
    var idNum = idNumResult.recordset[0].IdNum;
    console.log('📋 Patient IDNum:', idNum);
    
    var labResultsQuery = `
      SELECT 
        L.RequestNum,
        L.RefNum,
        L.TransDate,
        L.VerifyDate,
        L.LabExamID,
        LS.LabSection AS SectionName,
        LE.LabExam AS LabExam,
        L.AccessionNum,
        (ISNULL(D.LastName, '') + ' ' + ISNULL(D.FirstName, '')) AS Doctor,
        (ISNULL(MT.LastName, '') + ' ' + ISNULL(MT.FirstName, '')) AS MedTech,
        L.FormType,
        L.PatientType,
        L.RoomID,
        L.HospNum,
        L.IDNum,
        M.Rush AS Stat
      FROM laboratory..tbLabLogbook L WITH (NOLOCK)
      LEFT OUTER JOIN build_file..tbCoLabSection LS WITH (NOLOCK) 
        ON L.LabSectionID = LS.LabSectionID
      LEFT OUTER JOIN build_file..tbCoLabExam LE WITH (NOLOCK) 
        ON L.LabExamID = LE.LabExamID
      LEFT OUTER JOIN build_file..tbCoDoctor D WITH (NOLOCK) 
        ON L.doctorid = D.DoctorID
      LEFT OUTER JOIN build_file..tbCoMedTech MT WITH (NOLOCK) 
        ON L.medtechid = MT.medtechid
      LEFT OUTER JOIN laboratory..tbLabMaster M WITH (NOLOCK)
        ON L.RequestNum = M.RequestNum
      WHERE L.Hospnum = @Hospnum 
        AND L.IDNum = @IDNum
        AND L.VerifyID IS NOT NULL
      ORDER BY L.TransDate DESC, L.RefNum DESC
    `;
    
    var labResults = await pool.request()
      .input('Hospnum', sql.VarChar, hospnum)
      .input('IDNum', sql.VarChar, idNum)
      .query(labResultsQuery);
    
    var detailedResults = [];
    for (var i = 0; i < labResults.recordset.length; i++) {
      var lab = labResults.recordset[i];
      var requestNum = lab.RequestNum;
      var labExamId = lab.LabExamID;
      
      var detailsQuery = `
        SELECT 
          B.ItemId AS TestCode,
          ISNULL(V.ResultName, '') AS TestName,
          ISNULL(B.strResult, ISNULL(B.Result, '')) AS Result,
          ISNULL(B.strNValues, '') AS NormalValues,
          ISNULL(B.MinValue, '') AS MinValue,
          ISNULL(B.MaxValue, '') AS MaxValue,
          ISNULL(B.Unit, '') AS Unit,
          ISNULL(B.ConvStrResult, ISNULL(B.ConvResult, '')) AS ConvResult,
          ISNULL(B.ConvStrNValues, '') AS ConvNormalValues,
          ISNULL(B.ConvMin, '') AS ConvMin,
          ISNULL(B.ConvMax, '') AS ConvMax,
          ISNULL(B.ConvUnit, '') AS ConvUnit,
          ISNULL(B.Factor, 0) AS Factor,
          ISNULL(B.Remarks, '') AS Remarks,
          B.sortorder AS SortOrder
        FROM laboratory..tbLabResultNValues B WITH (NOLOCK)
        LEFT OUTER JOIN build_file..tbCoLabValues V WITH (NOLOCK) 
          ON V.Code = B.ItemID
        WHERE B.RequestNum = @RequestNum
        ORDER BY B.sortorder
      `;
      
      try {
        var detailsResult = await pool.request()
          .input('RequestNum', sql.VarChar, requestNum)
          .query(detailsQuery);
        
        var testDetails = detailsResult.recordset || [];
        
        if (testDetails.length === 0 && labExamId) {
          var fallbackQuery = `
            SELECT 
              @LabExamId AS TestCode,
              ISNULL(V.ResultName, '') AS TestName,
              ISNULL(B.strResult, ISNULL(B.Result, '')) AS Result,
              ISNULL(B.strNValues, '') AS NormalValues,
              ISNULL(B.MinValue, '') AS MinValue,
              ISNULL(B.MaxValue, '') AS MaxValue,
              ISNULL(B.Unit, '') AS Unit,
              ISNULL(B.Remarks, '') AS Remarks,
              B.sortorder AS SortOrder
            FROM laboratory..tbLabResultNValues B WITH (NOLOCK)
            LEFT OUTER JOIN build_file..tbCoLabValues V WITH (NOLOCK) 
              ON V.Code = @LabExamId
            WHERE B.RequestNum = @RequestNum
            ORDER BY B.sortorder
          `;
          
          var fallbackResult = await pool.request()
            .input('RequestNum', sql.VarChar, requestNum)
            .input('LabExamId', sql.VarChar, labExamId || '')
            .query(fallbackQuery);
          
          testDetails = fallbackResult.recordset || [];
        }
        
        var labWithDetails = {
          RequestNum: lab.RequestNum,
          RefNum: lab.RefNum,
          TransDate: lab.TransDate,
          VerifyDate: lab.VerifyDate,
          LabExamID: lab.LabExamID,
          SectionName: lab.SectionName,
          LabExam: lab.LabExam,
          AccessionNum: lab.AccessionNum,
          Doctor: lab.Doctor,
          MedTech: lab.MedTech,
          FormType: lab.FormType,
          PatientType: lab.PatientType,
          RoomID: lab.RoomID,
          HospNum: lab.HospNum,
          IDNum: lab.IDNum,
          Stat: lab.Stat,
          TestDetails: testDetails
        };
        
        detailedResults.push(labWithDetails);
      } catch (error) {
        console.log('⚠️ Error fetching details for RequestNum', requestNum + ':', error.message);
        var labWithEmptyDetails = {
          RequestNum: lab.RequestNum,
          RefNum: lab.RefNum,
          TransDate: lab.TransDate,
          VerifyDate: lab.VerifyDate,
          LabExamID: lab.LabExamID,
          SectionName: lab.SectionName,
          LabExam: lab.LabExam,
          AccessionNum: lab.AccessionNum,
          Doctor: lab.Doctor,
          MedTech: lab.MedTech,
          FormType: lab.FormType,
          PatientType: lab.PatientType,
          RoomID: lab.RoomID,
          HospNum: lab.HospNum,
          IDNum: lab.IDNum,
          Stat: lab.Stat,
          TestDetails: []
        };
        detailedResults.push(labWithEmptyDetails);
      }
    }
    
    // Query for X-Ray Results
    var xrayResultsQuery = `
      SELECT TOP 10
        Result.IdNum AS [TransNo],
        Result.VerifyDate AS [DateVerified],
        COALESCE(Exam.XRayExam, ISNULL(Result.ItemCode, 'N/A')) AS [ExamDescription],
        Result.RadiologistName AS Radiologist,
        Result.Interpretation,
        Result.InterpretationPureText,
        Result.RequestNum,
        Result.ExamDate,
        'X-Ray' AS ResultType
      FROM Radiology..tbxrResult AS Result WITH (NOLOCK)
      LEFT JOIN Build_File.dbo.tbCoXrayExam AS Exam WITH (NOLOCK)
        ON Result.ItemCode = Exam.XRayExamID
      WHERE Result.HospNum = @Hospnum
        AND Result.IDNum = @IDNum
        AND Result.VerifyById IS NOT NULL
      ORDER BY Result.TransDate DESC
    `;
    
    var xrayResults = await pool.request()
      .input('Hospnum', sql.VarChar, hospnum)
      .input('IDNum', sql.VarChar, idNum)
      .query(xrayResultsQuery);
    
    var cleanedXrayResults = [];
    for (var i = 0; i < xrayResults.recordset.length; i++) {
      var result = xrayResults.recordset[i];
      cleanedXrayResults.push({
        TransNo: result.TransNo,
        DateVerified: result.DateVerified,
        ExamDescription: result.ExamDescription,
        Radiologist: result.Radiologist,
        Interpretation: cleanRtfText(result.Interpretation),
        InterpretationPureText: result.InterpretationPureText ? cleanRtfText(result.InterpretationPureText) : '',
        RequestNum: result.RequestNum,
        ExamDate: result.ExamDate,
        ResultType: result.ResultType
      });
    }
    
    // Query for Ultrasound Results
    var ultrasoundResultsQuery = `
      SELECT TOP 10
        Result.IdNum AS [TransNo],
        Result.VerifyDate AS [DateVerified],
        COALESCE(Exam.UltraExam, ISNULL(Result.ItemCode, 'N/A')) AS [ExamDescription],
        Result.RadiologistName AS Radiologist,
        Result.Interpretation,
        Result.InterpretationPureText,
        Result.RequestNum,
        Result.ExamDate,
        'Ultrasound' AS ResultType
      FROM Radiology..tbUlResult AS Result WITH (NOLOCK)
      LEFT JOIN Build_File.dbo.tbCoUltraExam AS Exam WITH (NOLOCK)
        ON Result.ItemCode = Exam.UltraExamID
      WHERE Result.HospNum = @Hospnum
        AND Result.IDNum = @IDNum
        AND Result.VerifyById IS NOT NULL
      ORDER BY Result.TransDate DESC
    `;
    
    var ultrasoundResults = await pool.request()
      .input('Hospnum', sql.VarChar, hospnum)
      .input('IDNum', sql.VarChar, idNum)
      .query(ultrasoundResultsQuery);
    
    var cleanedUltrasoundResults = [];
    for (var i = 0; i < ultrasoundResults.recordset.length; i++) {
      var result = ultrasoundResults.recordset[i];
      cleanedUltrasoundResults.push({
        TransNo: result.TransNo,
        DateVerified: result.DateVerified,
        ExamDescription: result.ExamDescription,
        Radiologist: result.Radiologist,
        Interpretation: cleanRtfText(result.Interpretation),
        InterpretationPureText: result.InterpretationPureText ? cleanRtfText(result.InterpretationPureText) : '',
        RequestNum: result.RequestNum,
        ExamDate: result.ExamDate,
        ResultType: result.ResultType
      });
    }
    
    // Query for CT Scan Results
    var ctResultsQuery = `
      SELECT TOP 10
        Result.IdNum AS [TransNo],
        Result.VerifyDate AS [DateVerified],
        COALESCE(Exam.CTExam, ISNULL(Result.ItemCode, 'N/A')) AS [ExamDescription],
        Result.RadiologistName AS Radiologist,
        Result.Interpretation,
        Result.InterpretationPureText,
        Result.RequestNum,
        Result.ExamDate,
        'CT Scan' AS ResultType
      FROM Radiology..tbCtResult AS Result WITH (NOLOCK)
      LEFT JOIN Build_File.dbo.tbCoCTExam AS Exam WITH (NOLOCK)
        ON Result.ItemCode = Exam.CTExamID
      WHERE Result.HospNum = @Hospnum
        AND Result.IDNum = @IDNum
        AND Result.VerifyById IS NOT NULL
      ORDER BY Result.TransDate DESC
    `;
    
    var ctResults = await pool.request()
      .input('Hospnum', sql.VarChar, hospnum)
      .input('IDNum', sql.VarChar, idNum)
      .query(ctResultsQuery);
    
    var cleanedCtResults = [];
    for (var i = 0; i < ctResults.recordset.length; i++) {
      var result = ctResults.recordset[i];
      cleanedCtResults.push({
        TransNo: result.TransNo,
        DateVerified: result.DateVerified,
        ExamDescription: result.ExamDescription,
        Radiologist: result.Radiologist,
        Interpretation: cleanRtfText(result.Interpretation),
        InterpretationPureText: result.InterpretationPureText ? cleanRtfText(result.InterpretationPureText) : '',
        RequestNum: result.RequestNum,
        ExamDate: result.ExamDate,
        ResultType: result.ResultType
      });
    }
    
    var allResults = {
      labResults: detailedResults,
      xrayResults: cleanedXrayResults,
      ultrasoundResults: cleanedUltrasoundResults,
      ctResults: cleanedCtResults
    };
    
    console.log('✅ Found', allResults.labResults.length, 'lab results,', allResults.xrayResults.length, 'x-ray results,', allResults.ultrasoundResults.length, 'ultrasound results,', allResults.ctResults.length, 'CT results');
    
    res.json({
      success: true,
      data: allResults,
      message: 'Results fetched successfully'
    });
    
  } catch (error) {
    console.error('❌ Error fetching latest results:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message
    });
  }
});

// Get doctors by category with schedule information
router.get('/doctors/with-schedule/:categoryId', authenticateToken, async (req, res) => {
    let pool = null;
    
    try {
        const { categoryId } = req.params;
        const { dayOfWeek } = req.query; // Optional: filter by day (1=Monday, 7=Sunday)
        
        console.log(`🔍 Fetching doctors with CategoryID: ${categoryId}${dayOfWeek ? ` for day: ${dayOfWeek}` : ''}`);
        
        if (!categoryId) {
            return res.status(400).json({
                success: false,
                error: 'Category ID is required',
                doctors: [],
            });
        }
        
        pool = await getPatientPool();
        console.log('✅ Connected to Build_File for tbCoDoctor');
        
        // Build the day column name based on dayOfWeek
        let dayColumn = '';
        let timeColumn = '';
        if (dayOfWeek) {
            const dayMap = {
                '1': 'SchedDay1',
                '2': 'SchedDay2',
                '3': 'SchedDay3',
                '4': 'SchedDay4',
                '5': 'SchedDay5',
                '6': 'SchedDay6',
                '7': 'SchedDay7'
            };
            dayColumn = dayMap[dayOfWeek] || '';
        }
        
        let query = `
            SELECT 
                DoctorID,
                Lastname,
                Firstname,
                Middlename,
                SpecialtyID,
                CategoryID,
                Status,
                Title,
                CellNum,
                SchedDay1,
                SchedDay2,
                SchedDay3,
                SchedDay4,
                SchedDay5,
                SchedDay6,
                SchedDay7
        `;
        
        // If day specified, add the schedule for that day
        if (dayColumn) {
            query += `, ${dayColumn} AS ScheduleDay`;
        }
        
        query += `
            FROM Build_File..tbCoDoctor
            WHERE Status = 'A' 
                AND CategoryID = @categoryId
        `;
        
        // If day specified, filter only doctors with schedule on that day
        if (dayColumn) {
            query += ` AND ${dayColumn} IS NOT NULL AND ${dayColumn} != ''`;
        }
        
        query += ` ORDER BY Lastname, Firstname`;
        
        const request = pool.request();
        request.input('categoryId', sql.Int, parseInt(categoryId));
        
        const result = await request.query(query);
        
        console.log(`📊 Found ${result.recordset.length} doctors`);
        
        // Parse schedule times for each doctor
        const doctorsWithParsedSchedule = result.recordset.map(doctor => {
            const schedule = [];
            const dayMap = {
                '1': { col: 'SchedDay1', label: 'Monday' },
                '2': { col: 'SchedDay2', label: 'Tuesday' },
                '3': { col: 'SchedDay3', label: 'Wednesday' },
                '4': { col: 'SchedDay4', label: 'Thursday' },
                '5': { col: 'SchedDay5', label: 'Friday' },
                '6': { col: 'SchedDay6', label: 'Saturday' },
                '7': { col: 'SchedDay7', label: 'Sunday' }
            };
            
            // Parse each day's schedule
            for (const [dayNum, dayInfo] of Object.entries(dayMap)) {
                const scheduleText = doctor[dayInfo.col];
                if (scheduleText && scheduleText.trim() !== '') {
                    // Parse schedule text (e.g., "9:00am - 5:00pm")
                    const timeParts = scheduleText.split(/[-–]/).map(s => s.trim());
                    if (timeParts.length === 2) {
                        const startTime = timeParts[0];
                        const endTime = timeParts[1];
                        // Generate time slots between start and end (every hour)
                        const timeSlots = generateTimeSlots(startTime, endTime);
                        schedule.push({
                            day: parseInt(dayNum),
                            dayLabel: dayInfo.label,
                            startTime: startTime,
                            endTime: endTime,
                            timeSlots: timeSlots,
                            fullSchedule: scheduleText
                        });
                    } else {
                        // If it's a single time or "By Appointment", just add as is
                        schedule.push({
                            day: parseInt(dayNum),
                            dayLabel: dayInfo.label,
                            timeSlots: [scheduleText],
                            fullSchedule: scheduleText,
                            isCustom: true
                        });
                    }
                }
            }
            
            return {
                ...doctor,
                schedule: schedule
            };
        });
        
        res.json({
            success: true,
            doctors: doctorsWithParsedSchedule,
            message: `${doctorsWithParsedSchedule.length} doctor(s) found`,
        });
        
    } catch (error) {
        console.error('❌ Error fetching doctors with schedule:', error.message);
        res.status(500).json({
            success: false,
            error: 'Database error: ' + error.message,
            doctors: [],
        });
    }
});

// Helper function to generate time slots
function generateTimeSlots(startTime, endTime) {
    const slots = [];
    
    // Parse time strings
    const parseTime = (timeStr) => {
        const cleaned = timeStr.trim().toLowerCase();
        const isPM = cleaned.includes('pm');
        const isAM = cleaned.includes('am');
        let hours = parseInt(cleaned.replace(/[^0-9:]/g, '').split(':')[0]);
        const minutes = parseInt(cleaned.replace(/[^0-9:]/g, '').split(':')[1] || '0');
        
        if (isPM && hours < 12) hours += 12;
        if (isAM && hours === 12) hours = 0;
        
        return { hours, minutes };
    };
    
    const start = parseTime(startTime);
    const end = parseTime(endTime);
    
    if (start.hours === undefined || end.hours === undefined) {
        return [startTime];
    }
    
    let currentHour = start.hours;
    let currentMinute = start.minutes;
    
    // Generate slots every hour
    while (currentHour < end.hours || (currentHour === end.hours && currentMinute < end.minutes)) {
        const hour12 = currentHour % 12 === 0 ? 12 : currentHour % 12;
        const ampm = currentHour >= 12 ? 'PM' : 'AM';
        const timeStr = `${hour12}:${String(currentMinute).padStart(2, '0')} ${ampm}`;
        slots.push(timeStr);
        
        currentHour += 1;
        if (currentHour > 23) break;
    }
    
    if (slots.length === 0) {
        slots.push(startTime);
    }
    
    return slots;
}
module.exports = router;