-- ========================================
-- Healthcare Appointments System - OLAP DDL
-- Dimensional Star Schema for Analytics
-- Oracle 19c Compatible
-- ========================================

-- ========================================
-- DROP OLAP OBJECTS (if exist)
-- ========================================

BEGIN
    FOR rec IN (SELECT table_name FROM user_tables 
                WHERE table_name IN ('DIM_DATE', 'DIM_PATIENT', 'DIM_PROVIDER', 'DIM_SPECIALTY', 
                                     'DIM_INSURANCE', 'DIM_SERVICE', 'DIM_DIAGNOSIS', 'DIM_APPOINTMENT_STATUS',
                                     'FACT_APPOINTMENTS', 'FACT_VISITS', 'FACT_BILLS_MONTHLY')
                ORDER BY table_name DESC) LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || rec.table_name || ' CASCADE CONSTRAINTS';
    END LOOP;
END;
/

-- ========================================
-- DIMENSION TABLES
-- ========================================

-- ========================================
-- DIM_DATE: Time dimension (mandatory for all OLAP models)
-- ========================================

CREATE TABLE dim_date (
    date_key NUMBER PRIMARY KEY,
    calendar_date DATE NOT NULL UNIQUE,
    year_number NUMBER(4),
    quarter_number NUMBER(1),
    month_number NUMBER(2),
    week_number NUMBER(2),
    day_of_month NUMBER(2),
    day_of_week NUMBER(1),
    day_name VARCHAR2(10),
    month_name VARCHAR2(10),
    quarter_name VARCHAR2(10),
    is_weekend CHAR(1),
    is_holiday CHAR(1) DEFAULT 'N'
);

CREATE INDEX idx_dim_date_calendar ON dim_date(calendar_date);
CREATE INDEX idx_dim_date_yearmonth ON dim_date(year_number, month_number);

-- ========================================
-- DIM_PATIENT: Patient dimension
-- SCD Type 2: Tracks historical changes (current_flag, effective_from, effective_to)
-- ========================================

CREATE TABLE dim_patient (
    patient_key NUMBER PRIMARY KEY,
    patient_id NUMBER NOT NULL,
    patient_name VARCHAR2(200),
    date_of_birth DATE,
    gender CHAR(1),
    city VARCHAR2(100),
    state VARCHAR2(50),
    age_group VARCHAR2(20),
    is_active CHAR(1),
    current_flag CHAR(1) DEFAULT 'Y',
    effective_from DATE DEFAULT TRUNC(SYSDATE),
    effective_to DATE DEFAULT TO_DATE('9999-12-31', 'YYYY-MM-DD'),
    created_date DATE DEFAULT SYSDATE,
    CONSTRAINT uk_patient_current UNIQUE (patient_id, current_flag)
);

CREATE INDEX idx_dim_patient_id ON dim_patient(patient_id);
CREATE INDEX idx_dim_patient_current ON dim_patient(patient_id, current_flag);

-- ========================================
-- DIM_PROVIDER: Provider dimension
-- SCD Type 2: Tracks license changes, specialty changes
-- ========================================

CREATE TABLE dim_provider (
    provider_key NUMBER PRIMARY KEY,
    provider_id NUMBER NOT NULL,
    provider_name VARCHAR2(200),
    specialty_code VARCHAR2(20),
    specialty_name VARCHAR2(100),
    license_number VARCHAR2(50),
    license_expiry_date DATE,
    hire_date DATE,
    is_active CHAR(1),
    current_flag CHAR(1) DEFAULT 'Y',
    effective_from DATE DEFAULT TRUNC(SYSDATE),
    effective_to DATE DEFAULT TO_DATE('9999-12-31', 'YYYY-MM-DD'),
    created_date DATE DEFAULT SYSDATE,
    CONSTRAINT uk_provider_current UNIQUE (provider_id, current_flag)
);

CREATE INDEX idx_dim_provider_id ON dim_provider(provider_id);
CREATE INDEX idx_dim_provider_specialty ON dim_provider(specialty_code);
CREATE INDEX idx_dim_provider_current ON dim_provider(provider_id, current_flag);

-- ========================================
-- DIM_SPECIALTY: Medical Specialty dimension
-- ========================================

CREATE TABLE dim_specialty (
    specialty_key NUMBER PRIMARY KEY,
    specialty_id NUMBER NOT NULL UNIQUE,
    specialty_name VARCHAR2(100) NOT NULL,
    specialty_code VARCHAR2(20) NOT NULL,
    is_active CHAR(1)
);

CREATE INDEX idx_dim_specialty_code ON dim_specialty(specialty_code);

-- ========================================
-- DIM_SERVICE: Service Catalog dimension
-- ========================================

CREATE TABLE dim_service (
    service_key NUMBER PRIMARY KEY,
    service_id NUMBER NOT NULL UNIQUE,
    service_name VARCHAR2(200) NOT NULL,
    service_code VARCHAR2(50),
    standard_price NUMBER(10,2),
    duration_minutes NUMBER,
    specialty_code VARCHAR2(20),
    is_active CHAR(1)
);

CREATE INDEX idx_dim_service_id ON dim_service(service_id);
CREATE INDEX idx_dim_service_code ON dim_service(service_code);

-- ========================================
-- DIM_INSURANCE: Insurance Plan dimension
-- ========================================

CREATE TABLE dim_insurance (
    insurance_key NUMBER PRIMARY KEY,
    insurance_id NUMBER NOT NULL UNIQUE,
    plan_name VARCHAR2(200),
    plan_code VARCHAR2(50),
    provider_name VARCHAR2(200),
    coverage_percentage NUMBER(5,2),
    copay_amount NUMBER(10,2),
    deductible_amount NUMBER(10,2),
    is_active CHAR(1)
);

CREATE INDEX idx_dim_insurance_id ON dim_insurance(insurance_id);
CREATE INDEX idx_dim_insurance_code ON dim_insurance(plan_code);

-- ========================================
-- DIM_DIAGNOSIS: Diagnosis/ICD-10 dimension
-- ========================================

CREATE TABLE dim_diagnosis (
    diagnosis_key NUMBER PRIMARY KEY,
    diagnosis_id NUMBER NOT NULL UNIQUE,
    icd10_code VARCHAR2(20) NOT NULL,
    diagnosis_name VARCHAR2(300),
    category VARCHAR2(100),
    is_active CHAR(1)
);

CREATE INDEX idx_dim_diagnosis_code ON dim_diagnosis(icd10_code);

-- ========================================
-- DIM_APPOINTMENT_STATUS: Appointment Status dimension
-- ========================================

CREATE TABLE dim_appointment_status (
    status_key NUMBER PRIMARY KEY,
    status_code VARCHAR2(20) NOT NULL UNIQUE,
    status_name VARCHAR2(50),
    status_category VARCHAR2(50)  -- e.g., 'PENDING', 'COMPLETED', 'CANCELLED'
);

INSERT INTO dim_appointment_status VALUES (1, 'SCHEDULED', 'Scheduled', 'PENDING');
INSERT INTO dim_appointment_status VALUES (2, 'CONFIRMED', 'Confirmed', 'PENDING');
INSERT INTO dim_appointment_status VALUES (3, 'CHECKED_IN', 'Checked In', 'ACTIVE');
INSERT INTO dim_appointment_status VALUES (4, 'COMPLETED', 'Completed', 'COMPLETED');
INSERT INTO dim_appointment_status VALUES (5, 'CANCELLED', 'Cancelled', 'CANCELLED');
INSERT INTO dim_appointment_status VALUES (6, 'NO_SHOW', 'No Show', 'CANCELLED');

CREATE INDEX idx_dim_status_code ON dim_appointment_status(status_code);

-- ========================================
-- FACT TABLES
-- ========================================

-- ========================================
-- FACT_APPOINTMENTS: Transaction Fact Table
-- Grain: One row per appointment
-- Used to track appointment activity and KPIs
-- ========================================

CREATE TABLE fact_appointments (
    appointment_key NUMBER PRIMARY KEY,
    appointment_id NUMBER NOT NULL,
    date_key NUMBER NOT NULL,
    patient_key NUMBER,
    provider_key NUMBER,
    service_key NUMBER,
    specialty_key NUMBER,
    status_key NUMBER,
    appointment_count NUMBER DEFAULT 1,
    duration_minutes NUMBER,
    is_completed CHAR(1),
    is_noshow CHAR(1),
    is_cancelled CHAR(1),
    created_date DATE DEFAULT SYSDATE,
    CONSTRAINT fk_fact_appt_date FOREIGN KEY (date_key) REFERENCES dim_date(date_key),
    CONSTRAINT fk_fact_appt_patient FOREIGN KEY (patient_key) REFERENCES dim_patient(patient_key),
    CONSTRAINT fk_fact_appt_provider FOREIGN KEY (provider_key) REFERENCES dim_provider(provider_key),
    CONSTRAINT fk_fact_appt_service FOREIGN KEY (service_key) REFERENCES dim_service(service_key),
    CONSTRAINT fk_fact_appt_specialty FOREIGN KEY (specialty_key) REFERENCES dim_specialty(specialty_key),
    CONSTRAINT fk_fact_appt_status FOREIGN KEY (status_key) REFERENCES dim_appointment_status(status_key),
    CONSTRAINT uk_fact_appt_id UNIQUE (appointment_id)
);

CREATE INDEX idx_fact_appt_date ON fact_appointments(date_key);
CREATE INDEX idx_fact_appt_patient ON fact_appointments(patient_key);
CREATE INDEX idx_fact_appt_provider ON fact_appointments(provider_key);
CREATE INDEX idx_fact_appt_specialty ON fact_appointments(specialty_key);
CREATE INDEX idx_fact_appt_status ON fact_appointments(status_key);

-- ========================================
-- FACT_VISITS: Transaction Fact Table
-- Grain: One row per visit (actual encounter)
-- Used to track clinical activity and outcomes
-- ========================================

CREATE TABLE fact_visits (
    visit_key NUMBER PRIMARY KEY,
    visit_id NUMBER NOT NULL,
    appointment_id NUMBER,
    date_key NUMBER NOT NULL,
    patient_key NUMBER,
    provider_key NUMBER,
    service_key NUMBER,
    specialty_key NUMBER,
    insurance_key NUMBER,
    visit_duration_minutes NUMBER,
    total_service_amount NUMBER(10,2),
    visit_count NUMBER DEFAULT 1,
    has_diagnosis CHAR(1),
    created_date DATE DEFAULT SYSDATE,
    CONSTRAINT fk_fact_visit_date FOREIGN KEY (date_key) REFERENCES dim_date(date_key),
    CONSTRAINT fk_fact_visit_patient FOREIGN KEY (patient_key) REFERENCES dim_patient(patient_key),
    CONSTRAINT fk_fact_visit_provider FOREIGN KEY (provider_key) REFERENCES dim_provider(provider_key),
    CONSTRAINT fk_fact_visit_service FOREIGN KEY (service_key) REFERENCES dim_service(service_key),
    CONSTRAINT fk_fact_visit_specialty FOREIGN KEY (specialty_key) REFERENCES dim_specialty(specialty_key),
    CONSTRAINT fk_fact_visit_insurance FOREIGN KEY (insurance_key) REFERENCES dim_insurance(insurance_key),
    CONSTRAINT uk_fact_visit_id UNIQUE (visit_id)
);

CREATE INDEX idx_fact_visit_date ON fact_visits(date_key);
CREATE INDEX idx_fact_visit_patient ON fact_visits(patient_key);
CREATE INDEX idx_fact_visit_provider ON fact_visits(provider_key);
CREATE INDEX idx_fact_visit_specialty ON fact_visits(specialty_key);

-- ========================================
-- FACT_BILLS_MONTHLY: Snapshot Fact Table
-- Grain: One row per patient per month (billing activity)
-- Tracks cumulative billing metrics by month
-- ========================================

CREATE TABLE fact_bills_monthly (
    bill_key NUMBER PRIMARY KEY,
    year_month VARCHAR2(7),  -- YYYY-MM format
    date_key NUMBER NOT NULL,
    patient_key NUMBER NOT NULL,
    insurance_key NUMBER,
    total_bills_count NUMBER DEFAULT 0,
    total_bill_amount NUMBER(10,2) DEFAULT 0,
    total_insurance_covered NUMBER(10,2) DEFAULT 0,
    total_patient_responsibility NUMBER(10,2) DEFAULT 0,
    total_paid_amount NUMBER(10,2) DEFAULT 0,
    bills_paid_count NUMBER DEFAULT 0,
    bills_partial_count NUMBER DEFAULT 0,
    bills_pending_count NUMBER DEFAULT 0,
    bills_overdue_count NUMBER DEFAULT 0,
    created_date DATE DEFAULT SYSDATE,
    CONSTRAINT fk_fact_bills_date FOREIGN KEY (date_key) REFERENCES dim_date(date_key),
    CONSTRAINT fk_fact_bills_patient FOREIGN KEY (patient_key) REFERENCES dim_patient(patient_key),
    CONSTRAINT fk_fact_bills_insurance FOREIGN KEY (insurance_key) REFERENCES dim_insurance(insurance_key),
    CONSTRAINT uk_fact_bills_patient_month UNIQUE (patient_key, year_month)
);

CREATE INDEX idx_fact_bills_date ON fact_bills_monthly(date_key);
CREATE INDEX idx_fact_bills_month ON fact_bills_monthly(year_month);
CREATE INDEX idx_fact_bills_patient ON fact_bills_monthly(patient_key);

-- ========================================
-- MATERIALIZED VIEW: Appointment Summary by Provider & Specialty
-- Provides pre-aggregated data for common queries
-- ========================================

CREATE MATERIALIZED VIEW mv_appt_by_provider_specialty AS
SELECT 
    f.provider_key,
    f.specialty_key,
    dp.provider_name,
    ds.specialty_name,
    COUNT(*) as total_appointments,
    SUM(CASE WHEN f.is_completed = 'Y' THEN 1 ELSE 0 END) as completed_count,
    SUM(CASE WHEN f.is_noshow = 'Y' THEN 1 ELSE 0 END) as noshow_count,
    SUM(CASE WHEN f.is_cancelled = 'Y' THEN 1 ELSE 0 END) as cancelled_count,
    ROUND(100.0 * SUM(CASE WHEN f.is_completed = 'Y' THEN 1 ELSE 0 END) / COUNT(*), 2) as completion_rate
FROM fact_appointments f
JOIN dim_provider dp ON f.provider_key = dp.provider_key
JOIN dim_specialty ds ON f.specialty_key = ds.specialty_key
WHERE dp.current_flag = 'Y'
GROUP BY f.provider_key, f.specialty_key, dp.provider_name, ds.specialty_name;

-- ========================================
-- MATERIALIZED VIEW: Monthly Patient Visit Statistics
-- Snapshot of patient visit activity by month
-- ========================================

CREATE MATERIALIZED VIEW mv_patient_visits_monthly AS
SELECT 
    TRUNC(dd.calendar_date, 'MM') as month_start,
    TO_CHAR(dd.calendar_date, 'YYYY-MM') as year_month,
    COUNT(DISTINCT fv.patient_key) as unique_patients,
    COUNT(fv.visit_key) as total_visits,
    ROUND(AVG(fv.total_service_amount), 2) as avg_visit_amount,
    SUM(fv.total_service_amount) as total_visit_revenue
FROM fact_visits fv
JOIN dim_date dd ON fv.date_key = dd.date_key
GROUP BY TRUNC(dd.calendar_date, 'MM'), TO_CHAR(dd.calendar_date, 'YYYY-MM');

-- ========================================
-- MATERIALIZED VIEW: Insurance Claims Performance
-- Tracks claim approval and payment rates
-- ========================================

CREATE MATERIALIZED VIEW mv_insurance_claims_performance AS
SELECT 
    fi.insurance_key,
    fi.plan_name,
    COUNT(DISTINCT fb.bill_key) as total_bills,
    SUM(fb.total_bill_amount) as total_amount,
    SUM(fb.total_insurance_covered) as insurance_amount,
    ROUND(100.0 * SUM(fb.total_paid_amount) / NULLIF(SUM(fb.total_insurance_covered), 0), 2) as payment_rate
FROM fact_bills_monthly fb
JOIN dim_insurance fi ON fb.insurance_key = fi.insurance_key
WHERE fb.total_bill_amount > 0
GROUP BY fi.insurance_key, fi.plan_name;

-- ========================================
-- INDEXES ON FACT TABLES (Performance optimization)
-- ========================================

-- Composite indexes for common query patterns
CREATE INDEX idx_fact_appt_patient_date ON fact_appointments(patient_key, date_key);
CREATE INDEX idx_fact_appt_provider_date ON fact_appointments(provider_key, date_key);
CREATE INDEX idx_fact_visit_patient_date ON fact_visits(patient_key, date_key);
CREATE INDEX idx_fact_visit_provider_date ON fact_visits(provider_key, date_key);

COMMIT;

PROMPT 'OLAP DDL completed successfully.'
PROMPT 'Created:'
PROMPT '  - 8 Dimensions (Date, Patient, Provider, Specialty, Service, Insurance, Diagnosis, Status)'
PROMPT '  - 3 Fact Tables (Appointments, Visits, Bills Monthly)'
PROMPT '  - 3 Materialized Views for pre-aggregated analytics'
PROMPT '  - Comprehensive indexes for query performance'
