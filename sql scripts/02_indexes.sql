USE StudentClinicEMR_P2;

-- 2. INDEXES

CREATE INDEX idx_users_auth ON Users (Username, UserPassword, IsActive);
CREATE INDEX idx_users_role ON Users (UserRole);
CREATE INDEX idx_patient_name ON Patient (LastName, FirstName);
CREATE INDEX idx_patient_email ON Patient (Email);
CREATE INDEX idx_appointment_patient_date ON Appointment (PatientID, VisitDate);
CREATE INDEX idx_appointment_staff_date ON Appointment (StaffID, VisitDate);
CREATE INDEX idx_appointment_status ON Appointment (Status);
CREATE INDEX idx_diagnose_visit ON Diagnose (VisitID);
CREATE INDEX idx_prescription_visit ON Prescription (VisitID);
CREATE INDEX idx_lab_visit ON LabResults (VisitID);
CREATE INDEX idx_audit_table_time ON AuditLog (TableName, ChangedAt);
CREATE INDEX idx_access_user_time ON AccessLog (AccessedBy, AccessTime);

