USE StudentClinicEMR_P2;

-- 3. VIEWS

CREATE OR REPLACE VIEW vw_Admin_SecurityFeed AS
SELECT
    'CHANGE' AS LogType,
    TableName,
    ChangedBy AS UserName,
    ChangedAt AS EventTime,
    ActionType AS Detail,
    OldValue,
    NewValue
FROM AuditLog
UNION ALL
SELECT
    'ACCESS' AS LogType,
    TableName,
    AccessedBy AS UserName,
    AccessTime AS EventTime,
    ActionDetail AS Detail,
    NULL AS OldValue,
    NULL AS NewValue
FROM AccessLog;

CREATE OR REPLACE VIEW vw_Doctor_ClinicalSummary AS
SELECT
    A.VisitID,
    P.PatientID,
    CONCAT(P.FirstName, ' ', P.LastName) AS PatientName,
    P.DOB,
    P.Phone,
    P.Email,
    A.VisitDate,
    A.Status,
    A.ReasonForVisit,
    DC.DiagnosisDescription,
    D.Notes AS DiagnosisNotes,
    PR.MedicationName,
    PR.Dosage,
    PR.Instructions
FROM Appointment A
JOIN Patient P ON A.PatientID = P.PatientID
LEFT JOIN Diagnose D ON A.VisitID = D.VisitID
LEFT JOIN DiagnosisCatalog DC ON D.DiagnosisCode = DC.DiagnosisCode
LEFT JOIN Prescription PR ON A.VisitID = PR.VisitID;

CREATE OR REPLACE VIEW vw_Nurse_TriageQueue AS
SELECT
    A.VisitID,
    A.VisitDate,
    A.Status,
    CONCAT(P.FirstName, ' ', P.LastName) AS PatientName,
    A.ReasonForVisit,
    F.FacilityName
FROM Appointment A
JOIN Patient P ON A.PatientID = P.PatientID
JOIN Facility F ON A.FacilityID = F.FacilityID
WHERE A.Status IN ('Scheduled', 'Completed');

CREATE OR REPLACE VIEW vw_Patient_Portal AS
SELECT
    U.Username,
    P.PatientID,
    A.VisitID,
    A.VisitDate,
    A.Status,
    DC.DiagnosisDescription,
    PR.MedicationName,
    PR.Dosage,
    B.PatientBalance,
    B.PaymentStatus
FROM Users U
JOIN Patient P ON U.PatientID = P.PatientID
JOIN Appointment A ON P.PatientID = A.PatientID
LEFT JOIN Diagnose D ON A.VisitID = D.VisitID
LEFT JOIN DiagnosisCatalog DC ON D.DiagnosisCode = DC.DiagnosisCode
LEFT JOIN Prescription PR ON A.VisitID = PR.VisitID
LEFT JOIN Billing B ON A.VisitID = B.VisitID;

