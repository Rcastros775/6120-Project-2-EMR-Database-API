USE StudentClinicEMR_P2;

-- 6. SAMPLE DATA

SET @current_app_user = 'seed_script';
SET @current_app_role = 'Admin';
SET @current_patient_id = NULL;

INSERT INTO Insurance (ProviderName, PlanType, PolicyNumber)
VALUES ('BCBS', 'PPO', 'POL123'), ('Aetna', 'HMO', 'POL456');

INSERT INTO Facility (FacilityName)
VALUES ('Exam Room 1'), ('Exam Room 2'), ('Lab Room');

INSERT INTO DiagnosisCatalog (DiagnosisCode, DiagnosisDescription)
VALUES ('J00', 'Common Cold'), ('I10', 'Hypertension'), ('E11', 'Type 2 Diabetes Mellitus');

INSERT INTO SymptomCatalog (SymptomName)
VALUES ('Fever'), ('Cough'), ('Headache'), ('Fatigue');

INSERT INTO Employee (FirstName, LastName, JobTitle)
VALUES
('Admin', 'Root', 'Admin'),
('Alice', 'Smith', 'Doctor'),
('Bob', 'Jones', 'Nurse'),
('Mary', 'Davis', 'Receptionist');

INSERT INTO Patient (FirstName, LastName, DOB, Gender, Phone, Email, InsuranceID)
VALUES
('John', 'Doe', '1990-01-01', 'Male', '555-0101', 'john@test.com', 1),
('Jane', 'Rivera', '1985-06-15', 'Female', '555-0102', 'jane@test.com', 2);

INSERT INTO PatientAddress (PatientID, Street, City, State, ZipCode)
VALUES
(1, '123 Main St', 'Charlotte', 'NC', '28202'),
(2, '500 College Ave', 'Charlotte', 'NC', '28223');

INSERT INTO Users (StaffID, PatientID, Username, UserPassword, UserRole)
VALUES
(1, NULL, 'admin_user', 'Admin123!', 'Admin'),
(2, NULL, 'doctor_smith', 'DocPass456', 'Doctor'),
(3, NULL, 'nurse_jones', 'Nurse789', 'Nurse'),
(4, NULL, 'recept_mary', 'MaryPass000', 'Receptionist'),
(NULL, 1, 'patient_john', 'JohnPass321', 'Patient');

INSERT INTO Appointment (PatientID, StaffID, FacilityID, VisitDate, ReasonForVisit, Status)
VALUES
(1, 2, 1, '2026-04-30 09:00:00', 'Fever and cough', 'Scheduled'),
(2, 2, 2, '2026-05-01 10:30:00', 'Routine checkup', 'Scheduled');

INSERT INTO Billing (VisitID, AmountCharged, PatientBalance, PaymentStatus)
VALUES
(1, 50.00, 50.00, 'Unpaid'),
(2, 75.00, 75.00, 'Unpaid');

INSERT INTO VisitSymptoms (VisitID, SymptomID, Severity)
VALUES (1, 1, 'Moderate'), (1, 2, 'Mild');

INSERT INTO Diagnose (VisitID, DiagnosisCode, Notes)
VALUES (1, 'J00', 'Likely viral infection');

INSERT INTO Prescription (VisitID, MedicationName, Dosage, Instructions)
VALUES (1, 'Acetaminophen', '500mg', 'Take every 6 hours as needed');

INSERT INTO LabResults (VisitID, TestName, ResultValue)
VALUES (1, 'Flu Test', 'Negative');

SET @current_app_user = NULL;
SET @current_app_role = NULL;
SET @current_patient_id = NULL;
