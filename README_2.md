# Healthcare Appointments System

**Database Platform:** Oracle 19c+  
**Domain:** Healthcare appointment scheduling, visits, billing, and insurance claims

---

## 1. System Overview

This system manages patient appointments, clinical visits, billing, and insurance for a multi-specialty medical facility with 15 patients, 8 providers, 5 specialties, and 30+ appointments.

---

## 2. OLTP Tables (3NF)

**Total Tables: 14**

### Master Tables (6)

#### 1. test_patients
| Column | Type | Constraint |
|--------|------|-----------|
| patient_id | NUMBER | PK |
| first_name | VARCHAR2(100) | NOT NULL |
| last_name | VARCHAR2(100) | NOT NULL |
| date_of_birth | DATE | NOT NULL |
| gender | CHAR(1) | CHECK (M/F/O) |
| email | VARCHAR2(200) | UNIQUE NOT NULL |
| phone | VARCHAR2(20) | |
| city | VARCHAR2(100) | |

#### 2. test_providers
| Column | Type | Constraint |
|--------|------|-----------|
| provider_id | NUMBER | PK |
| first_name | VARCHAR2(100) | NOT NULL |
| last_name | VARCHAR2(100) | NOT NULL |
| specialty_id | NUMBER | FK |
| license_number | VARCHAR2(50) | UNIQUE NOT NULL |
| email | VARCHAR2(200) | |
| phone | VARCHAR2(20) | |

#### 3. test_specialties
| Column | Type | Constraint |
|--------|------|-----------|
| specialty_id | NUMBER | PK |
| specialty_name | VARCHAR2(100) | NOT NULL |
| specialty_code | VARCHAR2(20) | UNIQUE NOT NULL |

#### 4. test_insurance_plans
| Column | Type | Constraint |
|--------|------|-----------|
| insurance_id | NUMBER | PK |
| plan_name | VARCHAR2(100) | NOT NULL |
| plan_code | VARCHAR2(20) | UNIQUE NOT NULL |
| coverage_percentage | NUMBER | |
| copay_amount | NUMBER | |

#### 5. test_services
| Column | Type | Constraint |
|--------|------|-----------|
| service_id | NUMBER | PK |
| service_name | VARCHAR2(100) | NOT NULL |
| service_code | VARCHAR2(20) | UNIQUE NOT NULL |
| standard_price | NUMBER | |
| duration_minutes | NUMBER | |

#### 6. test_diagnosis_codes
| Column | Type | Constraint |
|--------|------|-----------|
| diagnosis_id | NUMBER | PK |
| icd10_code | VARCHAR2(10) | UNIQUE NOT NULL |
| diagnosis_name | VARCHAR2(200) | NOT NULL |
| category | VARCHAR2(50) | |

### Transactional Tables (4)

#### 7. test_appointments
| Column | Type | Constraint |
|--------|------|-----------|
| appointment_id | NUMBER | PK |
| patient_id | NUMBER | FK |
| provider_id | NUMBER | FK |
| service_id | NUMBER | FK |
| appointment_date | DATE | NOT NULL |
| start_time | TIMESTAMP | NOT NULL |
| end_time | TIMESTAMP | NOT NULL |
| status | VARCHAR2(20) | CHECK (SCHEDULED/CONFIRMED/CHECKED_IN/COMPLETED/CANCELLED/NO_SHOW) |

#### 8. test_visits
| Column | Type | Constraint |
|--------|------|-----------|
| visit_id | NUMBER | PK |
| appointment_id | NUMBER | FK |
| patient_id | NUMBER | FK |
| provider_id | NUMBER | FK |
| visit_date | DATE | NOT NULL |
| check_in_time | TIMESTAMP | |
| check_out_time | TIMESTAMP | |

#### 9. test_bills
| Column | Type | Constraint |
|--------|------|-----------|
| bill_id | NUMBER | PK |
| visit_id | NUMBER | FK |
| patient_id | NUMBER | FK |
| bill_date | DATE | NOT NULL |
| total_amount | NUMBER | NOT NULL |
| insurance_covered | NUMBER | |
| patient_responsibility | NUMBER | |

#### 10. test_claims
| Column | Type | Constraint |
|--------|------|-----------|
| claim_id | NUMBER | PK |
| bill_id | NUMBER | FK |
| insurance_id | NUMBER | FK |
| claim_number | VARCHAR2(50) | UNIQUE NOT NULL |
| claim_date | DATE | NOT NULL |
| claim_amount | NUMBER | |
| approved_amount | NUMBER | |

### Junction Tables (3)

#### 11. test_patient_insurance
| Column | Type | Constraint |
|--------|------|-----------|
| patient_id | NUMBER | FK, PK |
| insurance_id | NUMBER | FK, PK |
| policy_number | VARCHAR2(50) | |

#### 12. test_visit_services
| Column | Type | Constraint |
|--------|------|-----------|
| visit_id | NUMBER | FK, PK |
| service_id | NUMBER | FK, PK |
| quantity | NUMBER | |
| unit_price | NUMBER | |

#### 13. test_visit_diagnoses
| Column | Type | Constraint |
|--------|------|-----------|
| visit_id | NUMBER | FK, PK |
| diagnosis_id | NUMBER | FK, PK |
| is_primary | CHAR(1) | |

### Support Tables (1)

#### 14. test_provider_schedules
| Column | Type | Constraint |
|--------|------|-----------|
| provider_id | NUMBER | FK |
| day_of_week | VARCHAR2(10) | |
| start_time | VARCHAR2(5) | |
| end_time | VARCHAR2(5) | |
| location | VARCHAR2(100) | |

---

## 3. OLAP Tables (Star Schema)

### Fact Tables (3)
1. **fact_appointments** - Appointment transactions with metrics (appointment_count, duration, service_price, no_show_flag)
2. **fact_visits** - Visit transactions (visit_count, total_bill_amount, insurance_covered, service_count)
3. **fact_patient_monthly_snapshot** - Monthly patient summary (appointment_count, revenue, avg_visit_duration)

### Dimension Tables (7)
1. **dim_date** - Calendar dimension (date_key, full_date, year, quarter, month, day)
2. **dim_patient** - Patient dimension with SCD Type 2 (patient_key, patient_id, name, gender, age_group, city)
3. **dim_provider** - Provider dimension with SCD Type 2 (provider_key, provider_id, name, specialty, license_number)
4. **dim_service** - Service dimension with SCD Type 2 (service_key, service_id, service_name, standard_price)
5. **dim_specialty** - Specialty dimension (specialty_key, specialty_id, specialty_name)
6. **dim_insurance** - Insurance dimension (insurance_key, insurance_id, plan_name, coverage_percentage)
7. **dim_location** - Location dimension (location_key, location_name, location_type)

---

## 4. Document Store

**Table:** test_visit_documents  
**Structure:** JSON documents storing complete visit records with nested services, diagnoses, vital signs, and clinical notes  
**Storage:** CLOB column with IS JSON constraint

---

## 5. How to Run

### Execution Order

**Step 1:** Connect to Oracle
```sql
conn username/password@service_name
```

**Step 2:** Create OLTP Schema
```sql
@oltp_ddl.sql
```
Creates 14 tables, sequences, constraints, indexes

**Step 3:** Load Sample Data
```sql
@oltp_dml.sql
```
Inserts 15 patients, 8 providers, 30+ appointments

**Step 4:** Create OLAP Schema
```sql
@olap_ddl.sql
```
Creates dimensions, facts, materialized views

**Step 5:** Run ETL Load
```sql
@etl_load_plsql.sql
```
Populates OLAP from OLTP

**Step 6:** Create Document Store
```sql
@doc_store_ddl_dml.sql
```
Creates JSON tables, loads sample documents

**Step 7:** Generate KPI Report
```sql
SET SERVEROUTPUT ON SIZE UNLIMITED
@kpi_report.sql
EXEC generate_kpi_report('2024-12', 'ALL');
```

### Verification
```sql
-- Check OLTP data
SELECT 'Patients' AS entity, COUNT(*) FROM test_patients
UNION ALL SELECT 'Appointments', COUNT(*) FROM test_appointments;

-- Check OLAP data
SELECT 'dim_patient' AS dim, COUNT(*) FROM dim_patient
UNION ALL SELECT 'fact_appointments', COUNT(*) FROM fact_appointments;
```

---

## 6. Files Included

| File | Purpose |
|------|---------|
| oltp_ddl.sql | OLTP schema creation |
| oltp_dml.sql | Sample data inserts |
| olap_ddl.sql | Star schema creation |
| etl_load_plsql.sql | ETL procedures |
| doc_store_ddl_dml.sql | Document store with JSON |
| kpi_report.sql | KPI reporting script |

---

## Contact Information

**Student Name:** [Your Name]  
**Student ID:** [Your ID]  
**Course:** Oracle Database - Practical Exam  
**Submission Date:** December 31, 2025
