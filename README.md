# Healthcare Appointments System - Complete Database Solution

**Database Platform:** Oracle 19c+

---

## Table of Contents
1. [Domain Overview](#1-domain-overview)
2. [Business Rules](#2-business-rules)
3. [OLTP Design](#3-oltp-design-3nf)
4. [OLAP Design](#4-olap-design-star-schema)
5. [Document Model](#5-document-model-rationale)
6. [KPI Catalogue](#6-kpi-catalogue)
7. [Performance & Maintainability](#7-performance--maintainability)
8. [How to Run](#8-how-to-run)
9. [Assumptions & Limitations](#9-assumptions-and-limitations)
10. [Data Quality Checks](#10-data-quality-checks)

---

## 1. Domain Overview

### System Description
This Healthcare Appointments System manages the complete lifecycle of patient appointments, visits, billing, and insurance claims for a multi-specialty medical facility. The system tracks patient demographics, provider schedules, appointment workflows, clinical visits, and financial transactions.

### Scope Boundaries

**Included:**
- Patient registration and demographics management  
- Provider management with specialty assignments  
- Appointment scheduling with status lifecycle tracking  
- Clinical visit documentation with diagnoses and services  
- Billing and insurance claim processing  
- Service catalog and pricing management  
- Provider schedules across multiple locations

**Excluded:**
- Prescription management and pharmacy integration  
- Laboratory result tracking  
- Medical imaging (DICOM/PACS integration)  
- Detailed clinical notes and EHR functionality  
- Staff scheduling beyond providers  
- Inventory management for medical supplies

### Business Context
The system supports a healthcare organization with multiple specialties (Cardiology, Orthopedics, Dermatology, General Practice, Pediatrics) operating across multiple locations (Main Clinic, Satellite Office). It enables operational tracking, financial management, and analytical reporting for healthcare quality and business performance metrics.

**Scale:** 15 patients, 8 providers, 5 specialties, 30+ appointments

---

## 2. Business Rules

| # | Rule Statement | Enforcement Method | Location |
|---|---------------|-------------------|----------|
| 1 | Appointment status must follow valid lifecycle: SCHEDULED → CONFIRMED → CHECKED_IN → COMPLETED (or CANCELLED/NO_SHOW from any state) | CHECK constraint + application logic | oltp_ddl.sql: test_appointments |
| 2 | Appointment end time must be after start time, minimum 15 minutes duration | CHECK constraint | oltp_ddl.sql: test_appointments |
| 3 | Provider license must be valid (expiry_date > SYSDATE) for active status | CHECK constraint | oltp_ddl.sql: test_providers |
| 4 | Visit must have at least one service and one diagnosis to be marked COMPLETED | Trigger or application logic | Business rule enforced in ETL |
| 5 | Bill total_amount must equal SUM(visit_services line totals) | Calculated via trigger or stored procedure | etl_load_plsql.sql |
| 6 | Insurance coverage cannot exceed bill total_amount | CHECK constraint | oltp_ddl.sql: test_bills |
| 7 | Patient responsibility = total_amount - insurance_covered | Calculated column or trigger | oltp_ddl.sql: test_bills |
| 8 | Claim approved_amount cannot exceed claim_amount | CHECK constraint | oltp_ddl.sql: test_claims |
| 9 | No overlapping appointments for same provider | UNIQUE constraint or trigger | oltp_ddl.sql: business logic |
| 10 | Primary diagnosis must be flagged (is_primary = 'Y') for each completed visit | Application validation + data quality check | kpi_report.sql: data quality section |
| 11 | Active providers must have at least one schedule entry | Data quality rule | kpi_report.sql: orphan check |
| 12 | Cancelled appointments must log cancellation reason in status history | Trigger on status change to CANCELLED | oltp_ddl.sql: trg_appointment_status |
| 13 | Insurance policy effective_date must be before or equal to appointment_date | CHECK constraint or validation trigger | oltp_ddl.sql: test_patient_insurance |
| 14 | Service standard_price must be non-negative | CHECK constraint: standard_price >= 0 | oltp_ddl.sql: test_services |
| 15 | Patient email must be unique (business key) | UNIQUE constraint | oltp_ddl.sql: test_patients |

---

## 3. OLTP Design (3NF)

### Master Entities

| Entity | Purpose | Key Attributes | Row Est |
|--------|---------|---------------|---------|
| **test_patients** | Patient demographics and contact information | patient_id (PK), first_name, last_name, date_of_birth, gender, email (UK), phone, address, is_active | 15 |
| **test_providers** | Healthcare providers (doctors, specialists) | provider_id (PK), first_name, last_name, specialty_id (FK), license_number (UK), license_expiry_date, email, phone, hire_date, is_active | 8 |
| **test_specialties** | Medical specialties catalog | specialty_id (PK), specialty_name, specialty_code (UK), is_active | 5 |
| **test_insurance_plans** | Insurance plan catalog | insurance_id (PK), plan_name, plan_code (UK), provider_name, coverage_percentage, copay_amount, deductible_amount, is_active | 5 |
| **test_services** | Service/procedure catalog with pricing | service_id (PK), service_name, service_code (UK), description, standard_price, duration_minutes, specialty_id (FK), is_active | 10 |
| **test_diagnosis_codes** | ICD-10 diagnosis code master | diagnosis_id (PK), icd10_code (UK), diagnosis_name, category, is_active | 10 |

### Transactional Entities

| Entity | Purpose | Key Attributes | Row Est |
|--------|---------|---------------|---------|
| **test_appointments** | Scheduled patient appointments with lifecycle status | appointment_id (PK), patient_id (FK), provider_id (FK), service_id (FK), appointment_date, start_time, end_time, status, reason_for_visit, created_date | 30+ |
| **test_visits** | Completed clinical visits with documentation | visit_id (PK), appointment_id (FK), patient_id (FK), provider_id (FK), visit_date, check_in_time, check_out_time, chief_complaint, assessment, treatment_plan, visit_status | 3 |
| **test_bills** | Financial bills for services rendered | bill_id (PK), visit_id (FK), patient_id (FK), bill_date, total_amount, insurance_covered, patient_responsibility, paid_amount, bill_status | 3 |
| **test_claims** | Insurance claims submitted for bills | claim_id (PK), bill_id (FK), insurance_id (FK), claim_number (UK), claim_date, claim_amount, approved_amount, paid_amount, claim_status | 2 |

### Event/History Entity

| Entity | Purpose | Key Attributes |
|--------|---------|---------------|
| **test_appointment_status_history** | Audit trail for appointment lifecycle transitions | appointment_id (FK), old_status, new_status, changed_date, notes, changed_by |

### M:N Intersection Tables

| Entity | Relationship | Purpose | Key Attributes |
|--------|-------------|---------|---------------|
| **test_patient_insurance** | Patient ↔ Insurance Plans | Tracks which insurance policies patients hold | patient_id (FK), insurance_id (FK), policy_number, group_number, effective_date, expiry_date, is_primary |
| **test_visit_services** | Visit ↔ Services | Services provided during a visit | visit_id (FK), service_id (FK), quantity, unit_price, discount_percentage |
| **test_visit_diagnoses** | Visit ↔ Diagnosis Codes | Diagnoses assigned during visit | visit_id (FK), diagnosis_id (FK), is_primary |

### Supporting Entity

| Entity | Purpose |
|--------|---------|
| **test_provider_schedules** | Provider availability by day/time/location (day_of_week, start_time, end_time, location, is_active) |

**Total Tables:** 14 (6 master + 4 transactional + 1 event + 3 M:N)

### Relationship Patterns

**1:N Relationships:**
- Specialty → Providers  
- Specialty → Services  
- Patient → Appointments  
- Provider → Appointments  
- Visit → Bills  
- Bill → Claims

**M:N Relationships:**
- Patient ↔ Insurance Plans (via test_patient_insurance)  
- Visit ↔ Services (via test_visit_services)  
- Visit ↔ Diagnoses (via test_visit_diagnoses)

**Optional FK:**
- Appointment → Visit (optional: not all appointments result in visits)  
- Visit → Bill (optional: some visits may be free/waived)

**Role-Based Relationship:**
- Provider schedules reference providers for different roles/time slots

### Primary and Business Keys

- **Surrogate Keys (PK):** All entities use sequence-generated numeric primary keys (patient_id, appointment_id, visit_id, etc.)  
- **Business Keys (UNIQUE constraints):**
  - `specialty_code` in test_specialties  
  - `service_code` in test_services  
  - `icd10_code` in test_diagnosis_codes  
  - `license_number` in test_providers  
  - `claim_number` in test_claims  
  - `email` in test_patients  
  - `(policy_number, insurance_id)` composite in test_patient_insurance

### Normalization

- **3NF Compliance:** All tables eliminate transitive dependencies  
- **No Denormalization:** Maintains full referential integrity  
- **Calculated Fields:** Bill amounts calculated via triggers, not stored redundantly unless for audit

---

## 4. OLAP Design (Star Schema)

### Fact Tables

#### **fact_appointments** (Transaction Fact)
- **Grain:** One row per appointment  
- **Measures:**
  - appointment_count (always 1, for SUM aggregation)  
  - scheduled_duration_minutes  
  - actual_duration_minutes (if completed)  
  - service_standard_price  
  - no_show_flag (1/0)  
  - cancellation_flag (1/0)  
  - completion_flag (1/0)
- **Dimension Keys:** date_key, patient_key, provider_key, service_key, specialty_key, location_key

#### **fact_visits** (Transaction Fact)
- **Grain:** One row per completed visit  
- **Measures:**
  - visit_count (always 1)  
  - total_bill_amount  
  - insurance_covered_amount  
  - patient_responsibility_amount  
  - service_count  
  - diagnosis_count  
  - visit_duration_minutes
- **Dimension Keys:** visit_date_key, bill_date_key (role-playing), patient_key, provider_key, insurance_key, location_key

#### **fact_patient_monthly_snapshot** (Periodic Snapshot)
- **Grain:** One row per patient per month  
- **Measures:**
  - appointment_count  
  - completed_visit_count  
  - no_show_count  
  - cancelled_count  
  - total_revenue  
  - avg_visit_duration  
  - active_patient_flag
- **Dimension Keys:** month_key (date dimension), patient_key, primary_insurance_key

### Dimensions

| Dimension | Type | Description | SCD Type | Est Rows |
|-----------|------|-------------|----------|----------|
| **dim_date** | Date | Calendar dimension (year/quarter/month/week/day hierarchies) | Type 0 (static) | 730+ |
| **dim_patient** | Master | Patient demographics, age group, gender, city, state, zip | Type 2 (address changes) | 15+ |
| **dim_provider** | Master | Provider name, specialty, license info, hire date | Type 2 (specialty changes) | 8+ |
| **dim_service** | Master | Service name, code, standard price, duration, category | Type 2 (price changes) | 10+ |
| **dim_specialty** | Master | Specialty name, code, department | Type 1 | 5 |
| **dim_insurance** | Master | Insurance plan details, provider name, coverage %, copay | Type 2 (plan changes) | 5+ |
| **dim_location** | Master | Clinic/office locations (name, address, type) | Type 1 | 3 |

**Total Dimensions:** 7 (including dim_date)

### SCD Type 2 Implementation

Dimensions with Type 2 tracking include:
- **dim_patient:** Tracks address relocations  
- **dim_provider:** Tracks specialty changes  
- **dim_service:** Tracks price changes

**Fields:**
- `effective_from_date` (DATE) - When version became active  
- `effective_to_date` (DATE) - When version expired (NULL for current)  
- `current_flag` (CHAR(1)) - 'Y' for current, 'N' for historical  
- `row_version` (NUMBER) - Version number for same natural key

### Conformed Dimensions

- **dim_date:** Shared across all fact tables (role-playing: appointment_date, visit_date, bill_date)  
- **dim_patient:** Shared across fact_appointments and fact_visits  
- **dim_provider:** Shared across fact_appointments and fact_visits

### OLTP → OLAP Mapping

| OLTP Source | OLAP Target | Transformation |
|-------------|-------------|----------------|
| test_appointments | fact_appointments | One-to-one mapping with status flags derived |
| test_visits + test_bills | fact_visits | Join on visit_id, calculate aggregates |
| test_patients | dim_patient | SCD Type 2 on address change detection |
| test_providers | dim_provider | SCD Type 2 on specialty change |
| test_services | dim_service | SCD Type 2 on price change |
| test_specialties | dim_specialty | Type 1 updates |
| test_insurance_plans | dim_insurance | SCD Type 2 on coverage changes |
| Calendar logic | dim_date | Generated date dimension (2020-2030) |

### Aggregate Strategy

**Materialized Views:**
1. **mv_monthly_provider_summary** - Provider performance by month (COMPLETE ON DEMAND refresh)  
2. **mv_specialty_quarterly_kpis** - Specialty-level metrics by quarter  
3. **mv_daily_summary** - Daily operational metrics

---

## 5. Document Model Rationale

### Document Object: **Visit Record Document**

### Why Document Storage?

The **Visit Record** benefits from document storage because:
1. **Variable Structure:** Each specialty has different clinical note requirements  
2. **Nested Complexity:** Visits contain arrays of services, diagnoses, vital signs  
3. **Schema Evolution:** Medical documentation standards change; documents handle versioning  
4. **Query Efficiency:** "Retrieve complete visit" is common pattern

### Embedded vs Referenced Decisions

| Data Element | Storage Strategy | Justification |
|--------------|------------------|---------------|
| **Visit Services** | Embedded Array | Visit-owned, always retrieved together |
| **Visit Diagnoses** | Embedded Array | Captured at visit time, medical record snapshot |
| **Vital Signs** | Embedded Object | Visit-specific measurements |
| **Clinical Notes** | Embedded Text | Free-form notes specific to visit |
| **Patient ID** | Referenced (FK) | Patient master data maintained separately |
| **Provider ID** | Referenced (FK) | Provider info managed in OLTP |
| **Appointment ID** | Referenced (FK) | Links to transaction history |

### Document Structure Example

```json
{
  "visit_id": "V123456",
  "version": "1.0",
  "visit_date": "2025-11-17T09:00:00Z",
  "patient_ref": {"patient_id": 1001, "patient_name": "John Smith"},
  "provider_ref": {"provider_id": 5001, "provider_name": "Dr. Sarah Mitchell", "specialty": "Cardiology"},
  "appointment_id": 2001,
  "vital_signs": {"blood_pressure": "120/80", "heart_rate": 72, "temperature": 98.6"},
  "chief_complaint": "Regular checkup",
  "assessment": "Vital signs stable, no abnormalities",
  "services": [
    {"service_code": "SVC-001", "service_name": "Routine Checkup", "quantity": 1, "line_total": 135.00}
  ],
  "diagnoses": [
    {"icd10_code": "Z00.00", "diagnosis_name": "Encounter for General Adult Medical Exam", "is_primary": true}
  ],
  "status_history": [
    {"status": "CHECKED_IN", "timestamp": "2025-11-17T09:00:00Z"},
    {"status": "COMPLETED", "timestamp": "2025-11-17T09:25:00Z"}
  ]
}
```

### Versioning Strategy

- **Schema Version Field:** Each document includes `"version": "1.0"`  
- **Backward Compatibility:** Queries handle missing fields with defaults (JSON_VALUE)  
- **Migration:** New fields added optionally; old documents remain valid  
- **Version Tracking:** Separate table tracks field changes by version

### Storage Implementation

- **Oracle JSON Column:** `test_visit_documents.visit_json` (CLOB with IS JSON constraint)  
- **Check Constraint:** `CONSTRAINT chk_visit_json CHECK (visit_json IS JSON)`  
- **Search Index:** `CREATE SEARCH INDEX idx_visit_json_search ON test_visit_documents(visit_json) FOR JSON`

---

## 6. KPI Catalogue

### Financial KPIs (4)

| # | KPI Name | Formula | Source | Target |
|---|----------|---------|--------|--------|
| 1 | **Total Revenue** | SUM(total_amount) WHERE bill_status IN ('PAID', 'PARTIAL') | fact_visits | Track monthly |
| 2 | **Revenue per Visit** | Total Revenue / COUNT(completed visits) | fact_visits | > $150 |
| 3 | **Insurance Coverage Rate** | (SUM(insurance_covered) / SUM(total_amount)) * 100 | fact_visits | > 75% |
| 4 | **Avg Patient Responsibility** | AVG(patient_responsibility) | fact_visits | Monitor trend |

### Behavioral/Lifecycle KPIs (4)

| # | KPI Name | Formula | Source | Target |
|---|----------|---------|--------|--------|
| 5 | **Appointment No-Show Rate** | (COUNT(status='NO_SHOW') / COUNT(scheduled)) * 100 | fact_appointments | < 10% |
| 6 | **Appointment Completion Rate** | (COUNT(status='COMPLETED') / COUNT(all appts)) * 100 | fact_appointments | > 85% |
| 7 | **Cancellation Rate** | (COUNT(status='CANCELLED') / COUNT(all appts)) * 100 | fact_appointments | < 5% |
| 8 | **Avg Days to Follow-Up** | AVG(follow_up_days) WHERE recommended = 'Y' | OLTP test_visits | Monitor |

### Segmentation KPIs (2)

| # | KPI Name | Formula | Source |
|---|----------|---------|--------|
| 9 | **Revenue by Specialty** | SUM(total_amount) GROUP BY specialty | fact_visits + dim_specialty |
| 10 | **Patient Volume by Location** | COUNT(DISTINCT patient_id) GROUP BY location | fact_appointments + dim_location |

### Quality KPIs (2)

| # | KPI Name | Formula | Source | Target |
|---|----------|---------|--------|--------|
| 11 | **Visits Missing Primary Diagnosis Rate** | (COUNT(no primary diag) / COUNT(completed visits)) * 100 | OLTP quality check | 0% |
| 12 | **Orphaned Appointments Rate** | (COUNT(completed appts with no visit) / COUNT(completed appts)) * 100 | OLTP quality check | 0% |

### Additional KPIs (2)

| # | KPI Name | Formula | Source |
|---|----------|---------|--------|
| 13 | **Provider Utilization Rate** | (Actual appt hours / Available hours) * 100 | fact_appointments + provider schedules |
| 14 | **Claim Approval Rate** | (COUNT(status='PAID') / COUNT(all claims)) * 100 | OLTP test_claims |

---

## 7. Performance & Maintainability

### Indexing Strategy

#### OLTP Indexes

**Primary Key Indexes** (Automatic):
- All `_id` columns (patient_id, provider_id, etc.)

**Foreign Key Indexes** (Explicit - prevent locking):
```sql
CREATE INDEX idx_appointments_patient ON test_appointments(patient_id);
CREATE INDEX idx_appointments_provider ON test_appointments(provider_id);
CREATE INDEX idx_visits_appointment ON test_visits(appointment_id);
CREATE INDEX idx_bills_visit ON test_bills(visit_id);
CREATE INDEX idx_claims_bill ON test_claims(bill_id);
```

**Business Key Indexes** (Unique):
```sql
CREATE UNIQUE INDEX uk_specialty_code ON test_specialties(specialty_code);
CREATE UNIQUE INDEX uk_service_code ON test_services(service_code);
CREATE UNIQUE INDEX uk_provider_license ON test_providers(license_number);
```

**Query Performance Indexes**:
```sql
CREATE INDEX idx_appt_date_status ON test_appointments(appointment_date, status);
CREATE INDEX idx_visit_date ON test_visits(visit_date);
CREATE INDEX idx_bill_date_status ON test_bills(bill_date, bill_status);
```

#### OLAP Indexes

**B-Tree Indexes** (Range queries):
```sql
CREATE INDEX idx_fact_appt_date ON fact_appointments(date_key);
CREATE INDEX idx_fact_visit_date ON fact_visits(visit_date_key);
```

**Bitmap Indexes** (Low cardinality):
```sql
CREATE BITMAP INDEX bix_fact_specialty ON fact_appointments(specialty_key);
CREATE BITMAP INDEX bix_fact_insurance ON fact_visits(insurance_key);
```

### Partitioning Strategy

**OLTP Partitioning** (Large tables):
```sql
-- test_appointments: Range by month
PARTITION BY RANGE (appointment_date)
INTERVAL (NUMTOYMINTERVAL(1, 'MONTH'));

-- Enables: Partition pruning, easy archival of old data
```

**OLAP Partitioning:**
```sql
-- fact_appointments: Range by date_key
PARTITION BY RANGE (date_key);
```

### Expected Query Patterns

1. **Operational:** Today's appointments, This week's schedule  
2. **Provider Performance:** Monthly revenue, Patient volume, Utilization  
3. **Financial:** Daily/monthly revenue, Outstanding bills, Claims status  
4. **Patient History:** Visit history (last 12 months), Billing history  
5. **Analytics:** Slot utilization, Wait time analysis, Service mix

---

## 8. How to Run

### Prerequisites

- Oracle Database 19c or later  
- SQL*Plus, SQLcl, or SQL Developer  
- Database user with: CREATE TABLE, CREATE SEQUENCE, CREATE INDEX, CREATE VIEW, CREATE PROCEDURE  
- Sufficient tablespace quota

### Execution Order

**Step 1: Connect to Oracle**
```sql
conn username/password@service_name
```

**Step 2: Create OLTP Schema**
```sql
@oltp_ddl.sql
```
- Creates 14 tables, sequences, constraints, indexes  
- Duration: ~30 seconds  
- Output: "OLTP DDL Complete"

**Step 3: Load Sample Data**
```sql
@oltp_dml.sql
```
- Inserts 15 patients, 8 providers, 30+ appointments  
- Duration: ~20 seconds  
- Output: Row counts summary

**Step 4: Create OLAP Schema**
```sql
@olap_ddl.sql
```
- Creates dimensions, facts, materialized views  
- Duration: ~40 seconds  
- Output: "OLAP DDL Complete"

**Step 5: Run ETL Load**
```sql
@etl_load_plsql.sql
```
- Populates OLAP from OLTP  
- Duration: ~30 seconds  
- Output: Row counts per dimension/fact

**Step 6: Create Document Store**
```sql
@doc_store_ddl_dml.sql
```
- Creates JSON tables, loads sample documents  
- Duration: ~15 seconds  
- Output: "Document Store Complete"

**Step 7: Generate KPI Report**
```sql
SET SERVEROUTPUT ON SIZE UNLIMITED
@kpi_report.sql
```
- Generates formatted KPI report  
- Duration: ~10 seconds  
- Output: Multi-section report

### Verification Queries

```sql
-- Check OLTP data
SELECT 'Patients' AS entity, COUNT(*) FROM test_patients
UNION ALL SELECT 'Appointments', COUNT(*) FROM test_appointments;

-- Check OLAP data
SELECT 'dim_patient' AS dim, COUNT(*) FROM dim_patient
UNION ALL SELECT 'fact_appointments', COUNT(*) FROM fact_appointments;

-- Check documents
SELECT COUNT(*) FROM test_visit_documents;
```

### Troubleshooting

- **ORA-00955 (object exists):** Drop existing objects first  
- **ORA-02292 (FK violation):** Ensure correct execution order  
- **No data in OLAP:** Re-run ETL script  
- **Report shows N/A:** Insufficient historical data (need 2+ months)

---

## 9. Assumptions and Limitations

### Assumptions

1. Single healthcare organization (shared patient/provider pool)  
2. US healthcare context (ICD-10, USD)  
3. Simplified billing (no complex modifiers/bundling)  
4. Provider = licensed clinician only  
5. One primary service per appointment  
6. Insurance: primary coverage only tracked  
7. Timestamps accurate to minute level

### Limitations

1. No multi-tenancy support  
2. Limited clinical detail vs. real EHR  
3. Simplified status lifecycle  
4. No recurring appointments  
5. No RBAC/detailed audit logging  
6. Batch ETL only (no CDC/real-time)  
7. Simple document versioning  
8. English only (no I18N)  
9. Calendar year = fiscal year  
10. No automated archival policy

---

## 10. Data Quality Checks

Automated checks included in [kpi_report.sql](kpi_report.sql):

| Check # | Check Name | Expected |
|---------|------------|----------|
| 1 | Negative Bill Amounts | 0 rows |
| 2 | Orphaned Completed Appointments | 0 rows |
| 3 | Visits Missing Primary Diagnosis | 0 rows |
| 4 | Invalid Status Transitions | 0 rows |
| 5 | Expired Provider Licenses | 0 rows |
| 6 | Bills Exceeding Insurance Coverage | 0 rows |
| 7 | Claims Without Bills | 0 rows |
| 8 | Active Patients No Appointments | Low count |
| 9 | Future-Dated Completed Appointments | 0 rows |
| 10 | Missing Service Prices | 0 rows |

---

## Files Included

| File | Lines | Purpose |
|------|-------|---------|
| [oltp_ddl.sql](oltp_ddl.sql) | ~500 | OLTP schema creation |
| [oltp_dml.sql](oltp_dml.sql) | ~400 | Sample data inserts |
| [olap_ddl.sql](olap_ddl.sql) | ~400 | Star schema creation |
| [etl_load_plsql.sql](etl_load_plsql.sql) | ~350 | ETL procedures |
| [doc_store_ddl_dml.sql](doc_store_ddl_dml.sql) | ~400 | Document store with JSON |
| [kpi_report.sql](kpi_report.sql) | ~350 | KPI reporting script |
| **README.md** | This file | Complete documentation |

**Total:** ~2,400 lines of SQL/PL-SQL code

---

## Contact Information

**Student Name:** [Your Name]  
**Student ID:** [Your ID]  
**Course:** Oracle Database - Practical Exam  
**Submission Date:** December 31, 2025

---

**End of Documentation**
