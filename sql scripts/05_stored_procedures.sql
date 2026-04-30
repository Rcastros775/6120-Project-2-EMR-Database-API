USE StudentClinicEMR_P2;

-- 5. STORED PROCEDURES / API

DELIMITER //

DROP PROCEDURE IF EXISTS sp_Admin_Login //
CREATE PROCEDURE sp_Admin_Login(
    IN p_Username VARCHAR(50),
    IN p_Password VARCHAR(255)
)
BEGIN
    INSERT INTO AccessLog (TableName, AccessedBy, ActionDetail)
    VALUES ('Users', p_Username, 'Login attempt');

    SELECT UserID, Username, UserRole, PatientID, StaffID
    FROM Users
    WHERE Username = p_Username
      AND UserPassword = p_Password
      AND IsActive = 1;
END //

DROP PROCEDURE IF EXISTS sp_Admin_GetSecurityFeed //
CREATE PROCEDURE sp_Admin_GetSecurityFeed()
BEGIN
    IF COALESCE(@current_app_role, '') <> 'Admin' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Access denied: Admin role required';
    END IF;

    INSERT INTO AccessLog (TableName, AccessedBy, ActionDetail)
    VALUES ('AuditLog/AccessLog', COALESCE(@current_app_user, USER()), 'Viewed security feed');

    SELECT *
    FROM vw_Admin_SecurityFeed
    ORDER BY EventTime DESC
    LIMIT 100;
END //

DROP PROCEDURE IF EXISTS sp_Admin_AddUser //
CREATE PROCEDURE sp_Admin_AddUser(
    IN p_StaffID INT,
    IN p_PatientID INT,
    IN p_Username VARCHAR(50),
    IN p_Password VARCHAR(255),
    IN p_Role VARCHAR(20)
)
BEGIN
    IF COALESCE(@current_app_role, '') <> 'Admin' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Access denied: Admin role required';
    END IF;

    IF (p_StaffID IS NULL AND p_PatientID IS NULL) OR
       (p_StaffID IS NOT NULL AND p_PatientID IS NOT NULL) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'User must be linked to either one staff member OR one patient, but not both';
    END IF;

    IF p_Role NOT IN ('Admin', 'Doctor', 'Nurse', 'Receptionist', 'Patient') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid user role';
    END IF;

    IF p_Role = 'Patient' AND p_PatientID IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Patient role requires PatientID';
    END IF;

    IF p_Role <> 'Patient' AND p_StaffID IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Staff role requires StaffID';
    END IF;

    INSERT INTO Users (StaffID, PatientID, Username, UserPassword, UserRole)
    VALUES (p_StaffID, p_PatientID, p_Username, p_Password, p_Role);
END //

DROP PROCEDURE IF EXISTS sp_Admin_ToggleUser //
CREATE PROCEDURE sp_Admin_ToggleUser(
    IN p_UserID INT,
    IN p_IsActive TINYINT
)
BEGIN
    IF COALESCE(@current_app_role, '') <> 'Admin' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Access denied: Admin role required';
    END IF;

    UPDATE Users
    SET IsActive = p_IsActive
    WHERE UserID = p_UserID;
END //

DROP PROCEDURE IF EXISTS sp_Doc_GetPatientDashboard //
CREATE PROCEDURE sp_Doc_GetPatientDashboard(IN p_PatientID INT)
BEGIN
    IF COALESCE(@current_app_role, '') NOT IN ('Admin', 'Doctor', 'Nurse') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Access denied: clinical role required';
    END IF;

    INSERT INTO AccessLog (TableName, AccessedBy, ActionDetail)
    VALUES (
        'Patient/Appointment/Diagnose/Prescription',
        COALESCE(@current_app_user, USER()),
        CONCAT('Viewed patient dashboard for PatientID ', p_PatientID)
    );

    SELECT *
    FROM vw_Doctor_ClinicalSummary
    WHERE PatientID = p_PatientID
    ORDER BY VisitDate DESC;
END //

DROP PROCEDURE IF EXISTS sp_Doc_AddDiagnosis //
CREATE PROCEDURE sp_Doc_AddDiagnosis(
    IN p_VisitID INT,
    IN p_Code VARCHAR(20),
    IN p_Notes TEXT
)
BEGIN
    IF COALESCE(@current_app_role, '') <> 'Doctor' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Access denied: Doctor role required';
    END IF;

    INSERT INTO Diagnose (VisitID, DiagnosisCode, Notes)
    VALUES (p_VisitID, p_Code, p_Notes);
END //

DROP PROCEDURE IF EXISTS sp_Doc_AddPrescription //
CREATE PROCEDURE sp_Doc_AddPrescription(
    IN p_VisitID INT,
    IN p_Med VARCHAR(100),
    IN p_Dose VARCHAR(50),
    IN p_Inst TEXT
)
BEGIN
    IF COALESCE(@current_app_role, '') <> 'Doctor' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Access denied: Doctor role required';
    END IF;

    INSERT INTO Prescription (VisitID, MedicationName, Dosage, Instructions)
    VALUES (p_VisitID, p_Med, p_Dose, p_Inst);
END //

DROP PROCEDURE IF EXISTS sp_Nurse_GetTriageQueue //
CREATE PROCEDURE sp_Nurse_GetTriageQueue()
BEGIN
    IF COALESCE(@current_app_role, '') NOT IN ('Admin', 'Doctor', 'Nurse') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Access denied: Nurse/clinical role required';
    END IF;

    INSERT INTO AccessLog (TableName, AccessedBy, ActionDetail)
    VALUES ('Appointment', COALESCE(@current_app_user, USER()), 'Viewed triage queue');

    SELECT *
    FROM vw_Nurse_TriageQueue
    ORDER BY VisitDate;
END //

DROP PROCEDURE IF EXISTS sp_Nurse_AddSymptom //
CREATE PROCEDURE sp_Nurse_AddSymptom(
    IN p_VisitID INT,
    IN p_SymptomID INT,
    IN p_Severity VARCHAR(20)
)
BEGIN
    IF COALESCE(@current_app_role, '') <> 'Nurse' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Access denied: Nurse role required';
    END IF;

    INSERT INTO VisitSymptoms (VisitID, SymptomID, Severity)
    VALUES (p_VisitID, p_SymptomID, p_Severity);
END //

DROP PROCEDURE IF EXISTS sp_Nurse_UpdateLab //
CREATE PROCEDURE sp_Nurse_UpdateLab(
    IN p_VisitID INT,
    IN p_TestName VARCHAR(100),
    IN p_ResultValue VARCHAR(255)
)
BEGIN
    IF COALESCE(@current_app_role, '') <> 'Nurse' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Access denied: Nurse role required';
    END IF;

    INSERT INTO LabResults (VisitID, TestName, ResultValue)
    VALUES (p_VisitID, p_TestName, p_ResultValue);
END //

DROP PROCEDURE IF EXISTS sp_Recept_RegisterPatient //
CREATE PROCEDURE sp_Recept_RegisterPatient(
    IN p_FirstName VARCHAR(50),
    IN p_LastName VARCHAR(50),
    IN p_DOB DATE,
    IN p_Gender VARCHAR(10),
    IN p_Phone VARCHAR(20),
    IN p_Email VARCHAR(100)
)
BEGIN
    IF COALESCE(@current_app_role, '') <> 'Receptionist' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Access denied: Receptionist role required';
    END IF;

    INSERT INTO Patient (FirstName, LastName, DOB, Gender, Phone, Email)
    VALUES (p_FirstName, p_LastName, p_DOB, p_Gender, p_Phone, p_Email);

    SELECT LAST_INSERT_ID() AS NewPatientID;
END //

DROP PROCEDURE IF EXISTS sp_Recept_SearchPatient //
CREATE PROCEDURE sp_Recept_SearchPatient(IN p_LastName VARCHAR(50))
BEGIN
    IF COALESCE(@current_app_role, '') NOT IN ('Admin', 'Doctor', 'Nurse', 'Receptionist') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Access denied';
    END IF;

    INSERT INTO AccessLog (TableName, AccessedBy, ActionDetail)
    VALUES (
        'Patient',
        COALESCE(@current_app_user, USER()),
        CONCAT('Searched patients by last name: ', p_LastName)
    );

    SELECT PatientID, FirstName, LastName, DOB, Phone, Email
    FROM Patient
    WHERE LastName LIKE CONCAT(p_LastName, '%')
    ORDER BY LastName, FirstName;
END //

DROP PROCEDURE IF EXISTS sp_Recept_BookAppt //
CREATE PROCEDURE sp_Recept_BookAppt(
    IN p_PatientID INT,
    IN p_StaffID INT,
    IN p_FacilityID INT,
    IN p_Date DATETIME,
    IN p_Reason TEXT
)
BEGIN
    IF COALESCE(@current_app_role, '') <> 'Receptionist' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Access denied: Receptionist role required';
    END IF;

    INSERT INTO Appointment (PatientID, StaffID, FacilityID, VisitDate, ReasonForVisit)
    VALUES (p_PatientID, p_StaffID, p_FacilityID, p_Date, p_Reason);

    SELECT LAST_INSERT_ID() AS NewVisitID;
END //

DROP PROCEDURE IF EXISTS sp_Recept_ProcessPayment //
CREATE PROCEDURE sp_Recept_ProcessPayment(
    IN p_VisitID INT,
    IN p_Amount DECIMAL(10,2)
)
BEGIN
    IF COALESCE(@current_app_role, '') <> 'Receptionist' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Access denied: Receptionist role required';
    END IF;

    UPDATE Billing
    SET PatientBalance = GREATEST(PatientBalance - p_Amount, 0),
        PaymentStatus = CASE
            WHEN GREATEST(PatientBalance - p_Amount, 0) = 0 THEN 'Paid'
            ELSE 'Pending'
        END
    WHERE VisitID = p_VisitID;
END //

DROP PROCEDURE IF EXISTS sp_Patient_GetMyHistory //
CREATE PROCEDURE sp_Patient_GetMyHistory(IN p_Username VARCHAR(50))
BEGIN
    IF COALESCE(@current_app_role, '') NOT IN ('Patient', 'Admin') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Access denied: Patient or Admin role required';
    END IF;

    IF COALESCE(@current_app_role, '') = 'Patient' AND p_Username <> COALESCE(@current_app_user, '') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Access denied: patients may only view their own record';
    END IF;

    INSERT INTO AccessLog (TableName, AccessedBy, ActionDetail)
    VALUES ('Patient Portal', COALESCE(@current_app_user, USER()), 'Viewed patient history');

    SELECT *
    FROM vw_Patient_Portal
    WHERE Username = p_Username
    ORDER BY VisitDate DESC;
END //

DROP PROCEDURE IF EXISTS sp_Patient_UpdateContact //
CREATE PROCEDURE sp_Patient_UpdateContact(
    IN p_PatientID INT,
    IN p_Phone VARCHAR(20),
    IN p_Email VARCHAR(100)
)
BEGIN
    IF COALESCE(@current_app_role, '') NOT IN ('Patient', 'Receptionist') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Access denied';
    END IF;

    IF COALESCE(@current_app_role, '') = 'Patient' AND p_PatientID <> COALESCE(@current_patient_id, -1) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Access denied: patients may only update their own contact information';
    END IF;

    UPDATE Patient
    SET Phone = p_Phone,
        Email = p_Email
    WHERE PatientID = p_PatientID;
END //

DELIMITER ;
