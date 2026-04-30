USE StudentClinicEMR_P2;

-- 4. TRIGGERS FOR AUDIT TRAIL

DELIMITER //

CREATE TRIGGER tr_patient_insert AFTER INSERT ON Patient FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (TableName, RecordID, ActionType, OldValue, NewValue, ChangedBy)
    VALUES ('Patient', NEW.PatientID, 'INSERT', NULL,
            CONCAT('Name=', NEW.FirstName, ' ', NEW.LastName, '; DOB=', NEW.DOB, '; Phone=', IFNULL(NEW.Phone,''), '; Email=', IFNULL(NEW.Email,'')),
            IFNULL(@current_app_user, USER()));
END //

CREATE TRIGGER tr_patient_update AFTER UPDATE ON Patient FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (TableName, RecordID, ActionType, OldValue, NewValue, ChangedBy)
    VALUES ('Patient', OLD.PatientID, 'UPDATE',
            CONCAT('Phone=', IFNULL(OLD.Phone,''), '; Email=', IFNULL(OLD.Email,''), '; InsuranceID=', IFNULL(OLD.InsuranceID,'')),
            CONCAT('Phone=', IFNULL(NEW.Phone,''), '; Email=', IFNULL(NEW.Email,''), '; InsuranceID=', IFNULL(NEW.InsuranceID,'')),
            IFNULL(@current_app_user, USER()));
END //

CREATE TRIGGER tr_patient_delete BEFORE DELETE ON Patient FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (TableName, RecordID, ActionType, OldValue, NewValue, ChangedBy)
    VALUES ('Patient', OLD.PatientID, 'DELETE',
            CONCAT('Name=', OLD.FirstName, ' ', OLD.LastName, '; DOB=', OLD.DOB, '; Phone=', IFNULL(OLD.Phone,''), '; Email=', IFNULL(OLD.Email,'')),
            NULL,
            IFNULL(@current_app_user, USER()));
END //

CREATE TRIGGER tr_appointment_insert AFTER INSERT ON Appointment FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (TableName, RecordID, ActionType, OldValue, NewValue, ChangedBy)
    VALUES ('Appointment', NEW.VisitID, 'INSERT', NULL,
            CONCAT('PatientID=', NEW.PatientID, '; StaffID=', NEW.StaffID, '; VisitDate=', NEW.VisitDate, '; Status=', NEW.Status),
            IFNULL(@current_app_user, USER()));
END //

CREATE TRIGGER tr_appointment_update AFTER UPDATE ON Appointment FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (TableName, RecordID, ActionType, OldValue, NewValue, ChangedBy)
    VALUES ('Appointment', OLD.VisitID, 'UPDATE',
            CONCAT('VisitDate=', OLD.VisitDate, '; Status=', OLD.Status),
            CONCAT('VisitDate=', NEW.VisitDate, '; Status=', NEW.Status),
            IFNULL(@current_app_user, USER()));
END //

CREATE TRIGGER tr_appointment_delete BEFORE DELETE ON Appointment FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (TableName, RecordID, ActionType, OldValue, NewValue, ChangedBy)
    VALUES ('Appointment', OLD.VisitID, 'DELETE',
            CONCAT('PatientID=', OLD.PatientID, '; StaffID=', OLD.StaffID, '; VisitDate=', OLD.VisitDate, '; Status=', OLD.Status),
            NULL,
            IFNULL(@current_app_user, USER()));
END //

CREATE TRIGGER tr_diagnose_insert AFTER INSERT ON Diagnose FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (TableName, RecordID, ActionType, OldValue, NewValue, ChangedBy)
    VALUES ('Diagnose', NEW.DiagnosisID, 'INSERT', NULL,
            CONCAT('VisitID=', NEW.VisitID, '; DiagnosisCode=', NEW.DiagnosisCode, '; Notes=', IFNULL(NEW.Notes,'')),
            IFNULL(@current_app_user, USER()));
END //

CREATE TRIGGER tr_prescription_insert AFTER INSERT ON Prescription FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (TableName, RecordID, ActionType, OldValue, NewValue, ChangedBy)
    VALUES ('Prescription', NEW.PrescriptionID, 'INSERT', NULL,
            CONCAT('VisitID=', NEW.VisitID, '; Medication=', NEW.MedicationName, '; Dosage=', IFNULL(NEW.Dosage,'')),
            IFNULL(@current_app_user, USER()));
END //

CREATE TRIGGER tr_lab_insert AFTER INSERT ON LabResults FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (TableName, RecordID, ActionType, OldValue, NewValue, ChangedBy)
    VALUES ('LabResults', NEW.LabID, 'INSERT', NULL,
            CONCAT('VisitID=', NEW.VisitID, '; TestName=', NEW.TestName, '; ResultValue=', IFNULL(NEW.ResultValue,'')),
            IFNULL(@current_app_user, USER()));
END //

CREATE TRIGGER tr_billing_update AFTER UPDATE ON Billing FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (TableName, RecordID, ActionType, OldValue, NewValue, ChangedBy)
    VALUES ('Billing', OLD.BillID, 'UPDATE',
            CONCAT('PatientBalance=', OLD.PatientBalance, '; PaymentStatus=', OLD.PaymentStatus),
            CONCAT('PatientBalance=', NEW.PatientBalance, '; PaymentStatus=', NEW.PaymentStatus),
            IFNULL(@current_app_user, USER()));
END //

