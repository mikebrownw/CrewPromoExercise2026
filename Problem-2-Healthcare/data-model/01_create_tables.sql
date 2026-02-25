-- SQL Server (T-SQL)
-- Complete Data Model for Healthcare Analytics

-- Create patients table
CREATE TABLE patients (
    patient_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    birth_date DATE NOT NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    region VARCHAR(50) NOT NULL
);

-- Create appointments table with status constraint
CREATE TABLE appointments (
    appt_id INT PRIMARY KEY,
    patient_id INT NOT NULL,
    appt_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('SCHEDULED', 'COMPLETED', 'NO_SHOW')),
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
);

-- Create indexes for performance
CREATE INDEX idx_appointments_patient_date ON appointments(patient_id, appt_date) INCLUDE (status);
CREATE INDEX idx_appointments_date_status ON appointments(appt_date, status) INCLUDE (patient_id);

PRINT 'Healthcare tables created successfully';
