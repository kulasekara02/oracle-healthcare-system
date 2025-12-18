-- ========================================
-- Healthcare Appointments System - OLTP DDL
-- Oracle 19c Compatible
-- ========================================

-- Drop tables in reverse dependency order
BEGIN
    FOR rec IN (SELECT table_name FROM user_tables WHERE table_name LIKE 'TEST_%' ORDER BY table_name DESC) LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || rec.table_name || ' CASCADE CONSTRAINTS';
    END LOOP;
END;
/

-- Drop sequences
BEGIN
    FOR rec IN (SELECT sequence_name FROM user_sequences WHERE sequence_name LIKE 'TEST_%') LOOP
        EXECUTE IMMEDIATE 'DROP SEQUENCE ' || rec.sequence_name;
    END LOOP;
END;
/

-- ========================================
-- SEQUENCES
-- ========================================

CREATE SEQUENCE test_patient_seq START WITH 1000 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE test_provider_seq START WITH 2000 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE test_specialty_seq START WITH 100 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE test_insurance_seq START WITH 3000 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE test_service_seq START WITH 4000 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE test_appointment_seq START WITH 5000 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE test_visit_seq START WITH 6000 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE test_bill_seq START WITH 7000 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE test_claim_seq START WITH 8000 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE test_diagnosis_seq START WITH 200 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE test_schedule_seq START WITH 9000 INCREMENT BY 1 NOCACHE;

-- ========================================
-- MASTER ENTITIES
-- ========================================

-- Lookup: Specialties
CREATE TABLE test_specialties (
    specialty_id NUMBER PRIMARY KEY,
    specialty_name VARCHAR2(100) NOT NULL UNIQUE,
    specialty_code VARCHAR2(20) NOT NULL UNIQUE,
    is_active CHAR(1) DEFAULT 'Y' CHECK (is_active IN ('Y', 'N')),
    created_date DATE DEFAULT SYSDATE
);

-- Master: Patients
CREATE TABLE test_patients (
    patient_id NUMBER PRIMARY KEY,
    first_name VARCHAR2(100) NOT NULL,
    last_name VARCHAR2(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender CHAR(1) CHECK (gender IN ('M', 'F', 'O')),
    email VARCHAR2(200) UNIQUE NOT NULL,
    phone VARCHAR2(20),
    address_line1 VARCHAR2(200),
    address_line2 VARCHAR2(200),
    city VARCHAR2(100),
    state VARCHAR2(50),
    zip_code VARCHAR2(20),
    country VARCHAR2(50) DEFAULT 'USA',
    is_active CHAR(1) DEFAULT 'Y' CHECK (is_active IN ('Y', 'N')),
    created_date DATE DEFAULT SYSDATE,
    updated_date DATE DEFAULT SYSDATE
);

-- Master: Providers
CREATE TABLE test_providers (
    provider_id NUMBER PRIMARY KEY,
    first_name VARCHAR2(100) NOT NULL,
    last_name VARCHAR2(100) NOT NULL,
    specialty_id NUMBER NOT NULL,
    license_number VARCHAR2(50) UNIQUE NOT NULL,
    license_expiry_date DATE NOT NULL,
    email VARCHAR2(200) UNIQUE NOT NULL,
    phone VARCHAR2(20),
    is_active CHAR(1) DEFAULT 'Y' CHECK (is_active IN ('Y', 'N')),
    hire_date DATE DEFAULT SYSDATE,
    created_date DATE DEFAULT SYSDATE,
    updated_date DATE DEFAULT SYSDATE,
    CONSTRAINT fk_provider_specialty FOREIGN KEY (specialty_id) REFERENCES test_specialties(specialty_id),
    CONSTRAINT chk_license_valid CHECK (license_expiry_date > created_date)
);

-- Master: Insurance Plans
CREATE TABLE test_insurance_plans (
    insurance_id NUMBER PRIMARY KEY,
    plan_name VARCHAR2(200) NOT NULL,
    plan_code VARCHAR2(50) UNIQUE NOT NULL,
    provider_name VARCHAR2(200) NOT NULL,
    coverage_percentage NUMBER(5,2) DEFAULT 80 CHECK (coverage_percentage BETWEEN 0 AND 100),
    copay_amount NUMBER(10,2) DEFAULT 0 CHECK (copay_amount >= 0),
    deductible_amount NUMBER(10,2) DEFAULT 0 CHECK (deductible_amount >= 0),
    is_active CHAR(1) DEFAULT 'Y' CHECK (is_active IN ('Y', 'N')),
    created_date DATE DEFAULT SYSDATE
);

-- Master: Services Catalog
CREATE TABLE test_services (
    service_id NUMBER PRIMARY KEY,
    service_name VARCHAR2(200) NOT NULL,
    service_code VARCHAR2(50) UNIQUE NOT NULL,
    description VARCHAR2(500),
    standard_price NUMBER(10,2) NOT NULL CHECK (standard_price >= 0),
    duration_minutes NUMBER DEFAULT 30 CHECK (duration_minutes >= 15),
    specialty_id NUMBER,
    is_active CHAR(1) DEFAULT 'Y' CHECK (is_active IN ('Y', 'N')),
    created_date DATE DEFAULT SYSDATE,
    CONSTRAINT fk_service_specialty FOREIGN KEY (specialty_id) REFERENCES test_specialties(specialty_id)
);

-- Lookup: Diagnosis Codes (ICD-10 simplified)
CREATE TABLE test_diagnosis_codes (
    diagnosis_id NUMBER PRIMARY KEY,
    icd10_code VARCHAR2(20) UNIQUE NOT NULL,
    diagnosis_name VARCHAR2(300) NOT NULL,
    category VARCHAR2(100),
    is_active CHAR(1) DEFAULT 'Y' CHECK (is_active IN ('Y', 'N')),
    created_date DATE DEFAULT SYSDATE
);

-- ========================================
-- M:N RELATIONSHIP: Patient-Insurance
-- ========================================

CREATE TABLE test_patient_insurance (
    patient_id NUMBER NOT NULL,
    insurance_id NUMBER NOT NULL,
    policy_number VARCHAR2(100) NOT NULL,
    group_number VARCHAR2(100),
    effective_date DATE NOT NULL,
    expiry_date DATE,
    is_primary CHAR(1) DEFAULT 'Y' CHECK (is_primary IN ('Y', 'N')),
    created_date DATE DEFAULT SYSDATE,
    CONSTRAINT pk_patient_insurance PRIMARY KEY (patient_id, insurance_id, effective_date),
    CONSTRAINT fk_pi_patient_pi FOREIGN KEY (patient_id) REFERENCES test_patients(patient_id),
    CONSTRAINT fk_pi_insurance_pi FOREIGN KEY (insurance_id) REFERENCES test_insurance_plans(insurance_id),
    CONSTRAINT chk_pi_dates_pi CHECK (expiry_date IS NULL OR expiry_date > effective_date),
    CONSTRAINT uk_pi_policy_pi UNIQUE (policy_number, insurance_id)
);

-- ========================================
-- TRANSACTIONAL ENTITIES
-- ========================================

-- Transactional: Appointments
CREATE TABLE test_appointments (
    appointment_id NUMBER PRIMARY KEY,
    patient_id NUMBER NOT NULL,
    provider_id NUMBER NOT NULL,
    service_id NUMBER NOT NULL,
    appointment_date DATE NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    status VARCHAR2(20) DEFAULT 'SCHEDULED' CHECK (status IN ('SCHEDULED', 'CONFIRMED', 'CHECKED_IN', 'COMPLETED', 'CANCELLED', 'NO_SHOW')),
    reason_for_visit VARCHAR2(500),
    notes VARCHAR2(1000),
    created_date DATE DEFAULT SYSDATE,
    updated_date DATE DEFAULT SYSDATE,
    CONSTRAINT fk_appt_patient_appt FOREIGN KEY (patient_id) REFERENCES test_patients(patient_id),
    CONSTRAINT fk_appt_provider_appt FOREIGN KEY (provider_id) REFERENCES test_providers(provider_id),
    CONSTRAINT fk_appt_service_appt FOREIGN KEY (service_id) REFERENCES test_services(service_id),
    CONSTRAINT chk_appt_times_appt CHECK (end_time > start_time),
    CONSTRAINT chk_appt_duration_appt CHECK (end_time - start_time >= NUMTODSINTERVAL(15, 'MINUTE'))
);

-- Event/History: Appointment Status History
CREATE TABLE test_appointment_status_history (
    appointment_id NUMBER NOT NULL,
    old_status VARCHAR2(20),
    new_status VARCHAR2(20) NOT NULL,
    changed_date TIMESTAMP DEFAULT SYSTIMESTAMP,
    changed_by VARCHAR2(100) DEFAULT USER,
    notes VARCHAR2(500),
    CONSTRAINT fk_ash_appointment FOREIGN KEY (appointment_id) REFERENCES test_appointments(appointment_id) ON DELETE CASCADE
);

-- Transactional: Visits (actual encounter)
CREATE TABLE test_visits (
    visit_id NUMBER PRIMARY KEY,
    appointment_id NUMBER UNIQUE NOT NULL,
    patient_id NUMBER NOT NULL,
    provider_id NUMBER NOT NULL,
    visit_date DATE NOT NULL,
    check_in_time TIMESTAMP,
    check_out_time TIMESTAMP,
    chief_complaint VARCHAR2(500),
    hpi VARCHAR2(2000),
    assessment VARCHAR2(2000),
    treatment_plan VARCHAR2(2000),
    follow_up_days NUMBER,
    visit_status VARCHAR2(20) DEFAULT 'IN_PROGRESS' CHECK (visit_status IN ('IN_PROGRESS', 'COMPLETED', 'PENDING_REVIEW')),
    created_date DATE DEFAULT SYSDATE,
    CONSTRAINT fk_visit_appointment FOREIGN KEY (appointment_id) REFERENCES test_appointments(appointment_id),
    CONSTRAINT fk_visit_patient FOREIGN KEY (patient_id) REFERENCES test_patients(patient_id),
    CONSTRAINT fk_visit_provider FOREIGN KEY (provider_id) REFERENCES test_providers(provider_id),
    CONSTRAINT chk_visit_times CHECK (check_out_time IS NULL OR check_out_time > check_in_time)
);

-- M:N: Visit Services (services provided during visit)
CREATE TABLE test_visit_services (
    visit_id NUMBER NOT NULL,
    service_id NUMBER NOT NULL,
    quantity NUMBER DEFAULT 1 CHECK (quantity > 0),
    unit_price NUMBER(10,2) NOT NULL CHECK (unit_price >= 0),
    discount_percentage NUMBER(5,2) DEFAULT 0 CHECK (discount_percentage BETWEEN 0 AND 100),
    notes VARCHAR2(500),
    created_date DATE DEFAULT SYSDATE,
    CONSTRAINT pk_visit_services PRIMARY KEY (visit_id, service_id),
    CONSTRAINT fk_vs_visit FOREIGN KEY (visit_id) REFERENCES test_visits(visit_id),
    CONSTRAINT fk_vs_service FOREIGN KEY (service_id) REFERENCES test_services(service_id)
);

-- Visit Diagnoses
CREATE TABLE test_visit_diagnoses (
    visit_id NUMBER NOT NULL,
    diagnosis_id NUMBER NOT NULL,
    is_primary CHAR(1) DEFAULT 'N' CHECK (is_primary IN ('Y', 'N')),
    notes VARCHAR2(500),
    created_date DATE DEFAULT SYSDATE,
    CONSTRAINT pk_visit_diagnoses PRIMARY KEY (visit_id, diagnosis_id),
    CONSTRAINT fk_vd_visit FOREIGN KEY (visit_id) REFERENCES test_visits(visit_id),
    CONSTRAINT fk_vd_diagnosis FOREIGN KEY (diagnosis_id) REFERENCES test_diagnosis_codes(diagnosis_id)
);

-- Transactional: Bills
CREATE TABLE test_bills (
    bill_id NUMBER PRIMARY KEY,
    visit_id NUMBER UNIQUE NOT NULL,
    patient_id NUMBER NOT NULL,
    bill_date DATE DEFAULT SYSDATE NOT NULL,
    total_amount NUMBER(10,2) NOT NULL CHECK (total_amount >= 0),
    insurance_covered NUMBER(10,2) DEFAULT 0 CHECK (insurance_covered >= 0),
    patient_responsibility NUMBER(10,2) NOT NULL CHECK (patient_responsibility >= 0),
    paid_amount NUMBER(10,2) DEFAULT 0 CHECK (paid_amount >= 0),
    payment_date DATE,
    payment_method VARCHAR2(50),
    bill_status VARCHAR2(20) DEFAULT 'PENDING' CHECK (bill_status IN ('PENDING', 'PAID', 'PARTIAL', 'OVERDUE', 'WRITTEN_OFF')),
    created_date DATE DEFAULT SYSDATE,
    CONSTRAINT fk_bill_visit FOREIGN KEY (visit_id) REFERENCES test_visits(visit_id),
    CONSTRAINT fk_bill_patient FOREIGN KEY (patient_id) REFERENCES test_patients(patient_id),
    CONSTRAINT chk_bill_payment_date CHECK (payment_date IS NULL OR payment_date >= bill_date),
    CONSTRAINT chk_bill_paid CHECK (paid_amount <= patient_responsibility)
);

-- Transactional: Claims (to insurance)
CREATE TABLE test_claims (
    claim_id NUMBER PRIMARY KEY,
    bill_id NUMBER NOT NULL,
    insurance_id NUMBER NOT NULL,
    claim_number VARCHAR2(100) UNIQUE NOT NULL,
    claim_date DATE DEFAULT SYSDATE NOT NULL,
    claim_amount NUMBER(10,2) NOT NULL CHECK (claim_amount >= 0),
    approved_amount NUMBER(10,2),
    paid_amount NUMBER(10,2) DEFAULT 0 CHECK (paid_amount >= 0),
    payment_date DATE,
    claim_status VARCHAR2(20) DEFAULT 'SUBMITTED' CHECK (claim_status IN ('SUBMITTED', 'APPROVED', 'DENIED', 'PARTIAL', 'PAID')),
    denial_reason VARCHAR2(500),
    created_date DATE DEFAULT SYSDATE,
    CONSTRAINT fk_claim_bill FOREIGN KEY (bill_id) REFERENCES test_bills(bill_id),
    CONSTRAINT fk_claim_insurance FOREIGN KEY (insurance_id) REFERENCES test_insurance_plans(insurance_id),
    CONSTRAINT chk_claim_paid CHECK (paid_amount <= claim_amount)
);

-- ========================================
-- SUPPORTING TABLES
-- ========================================

-- Provider Schedules (role-based FK: provider as "owner" of schedule)
CREATE TABLE test_provider_schedules (
    schedule_id NUMBER PRIMARY KEY,
    provider_id NUMBER NOT NULL,
    day_of_week NUMBER CHECK (day_of_week BETWEEN 1 AND 7),
    start_time VARCHAR2(5) NOT NULL,
    end_time VARCHAR2(5) NOT NULL,
    location VARCHAR2(100),
    is_active CHAR(1) DEFAULT 'Y' CHECK (is_active IN ('Y', 'N')),
    created_date DATE DEFAULT SYSDATE,
    CONSTRAINT fk_schedule_provider FOREIGN KEY (provider_id) REFERENCES test_providers(provider_id),
    CONSTRAINT chk_schedule_times CHECK (end_time > start_time)
);

-- ========================================
-- INDEXES (Performance optimization)
-- ========================================

-- Business keys (omitted - UNIQUE constraints create implicit indexes)
-- CREATE INDEX idx_patient_email ON test_patients(email);  -- UNIQUE already indexes
-- CREATE INDEX idx_provider_license ON test_providers(license_number);  -- UNIQUE already indexes
-- CREATE INDEX idx_insurance_code ON test_insurance_plans(plan_code);  -- UNIQUE already indexes

-- Foreign keys for joins
CREATE INDEX idx_appt_patient ON test_appointments(patient_id);
CREATE INDEX idx_appt_provider ON test_appointments(provider_id);
CREATE INDEX idx_appt_date ON test_appointments(appointment_date);
CREATE INDEX idx_appt_status ON test_appointments(status);

-- Composite for scheduling queries
CREATE INDEX idx_appt_provider_date ON test_appointments(provider_id, appointment_date);

-- Visit indexes
CREATE INDEX idx_visit_patient ON test_visits(patient_id);
CREATE INDEX idx_visit_provider ON test_visits(provider_id);
CREATE INDEX idx_visit_date ON test_visits(visit_date);

-- Billing indexes
CREATE INDEX idx_bill_patient ON test_bills(patient_id);
CREATE INDEX idx_bill_status ON test_bills(bill_status);
CREATE INDEX idx_bill_date ON test_bills(bill_date);

-- Claims indexes
CREATE INDEX idx_claim_insurance ON test_claims(insurance_id);
CREATE INDEX idx_claim_status ON test_claims(claim_status);

COMMIT;

PROMPT 'OLTP DDL completed successfully. Tables, constraints, and indexes created.'
