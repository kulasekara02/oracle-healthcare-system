-- ========================================
-- Healthcare Appointments System - OLTP DML
-- Sample Data Inserts - Oracle 19c
-- ========================================


-- Disable constraints temporarily for data load
ALTER SESSION SET CONSTRAINTS=DEFERRED;

-- ========================================
-- MASTER DATA: Specialties
-- ========================================

INSERT INTO test_specialties (specialty_id, specialty_name, specialty_code, is_active)
VALUES (test_specialty_seq.NEXTVAL, 'Cardiology', 'CARD', 'Y');

INSERT INTO test_specialties (specialty_id, specialty_name, specialty_code, is_active)
VALUES (test_specialty_seq.NEXTVAL, 'Orthopedics', 'ORTHO', 'Y');

INSERT INTO test_specialties (specialty_id, specialty_name, specialty_code, is_active)
VALUES (test_specialty_seq.NEXTVAL, 'Dermatology', 'DERM', 'Y');

INSERT INTO test_specialties (specialty_id, specialty_name, specialty_code, is_active)
VALUES (test_specialty_seq.NEXTVAL, 'General Practice', 'GP', 'Y');

INSERT INTO test_specialties (specialty_id, specialty_name, specialty_code, is_active)
VALUES (test_specialty_seq.NEXTVAL, 'Pediatrics', 'PED', 'Y');

-- ========================================
-- MASTER DATA: Patients (20 active patients for testing)
-- ========================================

INSERT INTO test_patients (patient_id, first_name, last_name, date_of_birth, gender, email, phone, city, state, zip_code, is_active)
VALUES (test_patient_seq.NEXTVAL, 'John', 'Smith', DATE '1965-03-15', 'M', 'john.smith@email.com', '555-0101', 'New York', 'NY', '10001', 'Y');

INSERT INTO test_patients (patient_id, first_name, last_name, date_of_birth, gender, email, phone, city, state, zip_code, is_active)
VALUES (test_patient_seq.NEXTVAL, 'Mary', 'Johnson', DATE '1978-07-22', 'F', 'mary.johnson@email.com', '555-0102', 'Boston', 'MA', '02101', 'Y');

INSERT INTO test_patients (patient_id, first_name, last_name, date_of_birth, gender, email, phone, city, state, zip_code, is_active)
VALUES (test_patient_seq.NEXTVAL, 'Robert', 'Williams', DATE '1955-11-30', 'M', 'robert.williams@email.com', '555-0103', 'Chicago', 'IL', '60601', 'Y');

INSERT INTO test_patients (patient_id, first_name, last_name, date_of_birth, gender, email, phone, city, state, zip_code, is_active)
VALUES (test_patient_seq.NEXTVAL, 'Patricia', 'Brown', DATE '1982-05-12', 'F', 'patricia.brown@email.com', '555-0104', 'Houston', 'TX', '77001', 'Y');

INSERT INTO test_patients (patient_id, first_name, last_name, date_of_birth, gender, email, phone, city, state, zip_code, is_active)
VALUES (test_patient_seq.NEXTVAL, 'Michael', 'Davis', DATE '1970-09-08', 'M', 'michael.davis@email.com', '555-0105', 'Phoenix', 'AZ', '85001', 'Y');

INSERT INTO test_patients (patient_id, first_name, last_name, date_of_birth, gender, email, phone, city, state, zip_code, is_active)
VALUES (test_patient_seq.NEXTVAL, 'Jennifer', 'Miller', DATE '1988-01-20', 'F', 'jennifer.miller@email.com', '555-0106', 'Philadelphia', 'PA', '19101', 'Y');

INSERT INTO test_patients (patient_id, first_name, last_name, date_of_birth, gender, email, phone, city, state, zip_code, is_active)
VALUES (test_patient_seq.NEXTVAL, 'William', 'Wilson', DATE '1960-12-05', 'M', 'william.wilson@email.com', '555-0107', 'San Antonio', 'TX', '78201', 'Y');

INSERT INTO test_patients (patient_id, first_name, last_name, date_of_birth, gender, email, phone, city, state, zip_code, is_active)
VALUES (test_patient_seq.NEXTVAL, 'Susan', 'Moore', DATE '1975-04-18', 'F', 'susan.moore@email.com', '555-0108', 'San Diego', 'CA', '92101', 'Y');

INSERT INTO test_patients (patient_id, first_name, last_name, date_of_birth, gender, email, phone, city, state, zip_code, is_active)
VALUES (test_patient_seq.NEXTVAL, 'David', 'Taylor', DATE '1980-06-25', 'M', 'david.taylor@email.com', '555-0109', 'Dallas', 'TX', '75201', 'Y');

INSERT INTO test_patients (patient_id, first_name, last_name, date_of_birth, gender, email, phone, city, state, zip_code, is_active)
VALUES (test_patient_seq.NEXTVAL, 'Linda', 'Anderson', DATE '1972-10-14', 'F', 'linda.anderson@email.com', '555-0110', 'San Jose', 'CA', '95101', 'Y');

INSERT INTO test_patients (patient_id, first_name, last_name, date_of_birth, gender, email, phone, city, state, zip_code, is_active)
VALUES (test_patient_seq.NEXTVAL, 'James', 'Thomas', DATE '1968-02-28', 'M', 'james.thomas@email.com', '555-0111', 'Austin', 'TX', '78701', 'Y');

INSERT INTO test_patients (patient_id, first_name, last_name, date_of_birth, gender, email, phone, city, state, zip_code, is_active)
VALUES (test_patient_seq.NEXTVAL, 'Barbara', 'Jackson', DATE '1985-08-09', 'F', 'barbara.jackson@email.com', '555-0112', 'Jacksonville', 'FL', '32099', 'Y');

INSERT INTO test_patients (patient_id, first_name, last_name, date_of_birth, gender, email, phone, city, state, zip_code, is_active)
VALUES (test_patient_seq.NEXTVAL, 'Joseph', 'White', DATE '1962-07-03', 'M', 'joseph.white@email.com', '555-0113', 'Fort Worth', 'TX', '76102', 'Y');

INSERT INTO test_patients (patient_id, first_name, last_name, date_of_birth, gender, email, phone, city, state, zip_code, is_active)
VALUES (test_patient_seq.NEXTVAL, 'Elizabeth', 'Harris', DATE '1990-03-11', 'F', 'elizabeth.harris@email.com', '555-0114', 'Columbus', 'OH', '43085', 'Y');

INSERT INTO test_patients (patient_id, first_name, last_name, date_of_birth, gender, email, phone, city, state, zip_code, is_active)
VALUES (test_patient_seq.NEXTVAL, 'Charles', 'Martin', DATE '1975-11-22', 'M', 'charles.martin@email.com', '555-0115', 'Charlotte', 'NC', '28202', 'Y');

-- ========================================
-- MASTER DATA: Insurance Plans (5 plans)
-- ========================================

INSERT INTO test_insurance_plans (insurance_id, plan_name, plan_code, provider_name, coverage_percentage, copay_amount, deductible_amount, is_active)
VALUES (test_insurance_seq.NEXTVAL, 'Basic Health Plan', 'BHP-001', 'HealthCare Plus', 70, 25, 500, 'Y');

INSERT INTO test_insurance_plans (insurance_id, plan_name, plan_code, provider_name, coverage_percentage, copay_amount, deductible_amount, is_active)
VALUES (test_insurance_seq.NEXTVAL, 'Premium Plus', 'PPL-001', 'Blue Shield', 85, 15, 200, 'Y');

INSERT INTO test_insurance_plans (insurance_id, plan_name, plan_code, provider_name, coverage_percentage, copay_amount, deductible_amount, is_active)
VALUES (test_insurance_seq.NEXTVAL, 'Essential Coverage', 'ESS-001', 'Aetna', 75, 20, 300, 'Y');

INSERT INTO test_insurance_plans (insurance_id, plan_name, plan_code, provider_name, coverage_percentage, copay_amount, deductible_amount, is_active)
VALUES (test_insurance_seq.NEXTVAL, 'Executive Health', 'EXC-001', 'United Health', 90, 10, 100, 'Y');

INSERT INTO test_insurance_plans (insurance_id, plan_name, plan_code, provider_name, coverage_percentage, copay_amount, deductible_amount, is_active)
VALUES (test_insurance_seq.NEXTVAL, 'Community Care', 'COM-001', 'Medicaid State', 80, 5, 50, 'Y');

-- ========================================
-- MASTER DATA: Services Catalog (10 services)
-- ========================================

INSERT INTO test_services (service_id, service_name, service_code, description, standard_price, duration_minutes, specialty_id, is_active)
SELECT test_service_seq.NEXTVAL, 'Routine Checkup', 'SVC-001', 'General health examination', 150, 30, specialty_id, 'Y' FROM test_specialties WHERE specialty_code = 'GP';

INSERT INTO test_services (service_id, service_name, service_code, description, standard_price, duration_minutes, specialty_id, is_active)
SELECT test_service_seq.NEXTVAL, 'Cardiac Consultation', 'SVC-002', 'Heart health evaluation', 300, 45, specialty_id, 'Y' FROM test_specialties WHERE specialty_code = 'CARD';

INSERT INTO test_services (service_id, service_name, service_code, description, standard_price, duration_minutes, specialty_id, is_active)
SELECT test_service_seq.NEXTVAL, 'Orthopedic Assessment', 'SVC-003', 'Joint and bone evaluation', 250, 40, specialty_id, 'Y' FROM test_specialties WHERE specialty_code = 'ORTHO';

INSERT INTO test_services (service_id, service_name, service_code, description, standard_price, duration_minutes, specialty_id, is_active)
SELECT test_service_seq.NEXTVAL, 'ECG Test', 'SVC-004', 'Electrocardiogram', 200, 20, specialty_id, 'Y' FROM test_specialties WHERE specialty_code = 'CARD';

INSERT INTO test_services (service_id, service_name, service_code, description, standard_price, duration_minutes, specialty_id, is_active)
SELECT test_service_seq.NEXTVAL, 'Skin Treatment', 'SVC-005', 'Dermatology treatment session', 180, 30, specialty_id, 'Y' FROM test_specialties WHERE specialty_code = 'DERM';

INSERT INTO test_services (service_id, service_name, service_code, description, standard_price, duration_minutes, specialty_id, is_active)
SELECT test_service_seq.NEXTVAL, 'Child Development Screening', 'SVC-006', 'Pediatric developmental assessment', 175, 35, specialty_id, 'Y' FROM test_specialties WHERE specialty_code = 'PED';

INSERT INTO test_services (service_id, service_name, service_code, description, standard_price, duration_minutes, specialty_id, is_active)
SELECT test_service_seq.NEXTVAL, 'Lab Work', 'SVC-007', 'Blood and lab tests', 100, 15, specialty_id, 'Y' FROM test_specialties WHERE specialty_code = 'GP';

INSERT INTO test_services (service_id, service_name, service_code, description, standard_price, duration_minutes, specialty_id, is_active)
SELECT test_service_seq.NEXTVAL, 'X-Ray Service', 'SVC-008', 'Radiological imaging', 150, 20, specialty_id, 'Y' FROM test_specialties WHERE specialty_code = 'ORTHO';

INSERT INTO test_services (service_id, service_name, service_code, description, standard_price, duration_minutes, specialty_id, is_active)
SELECT test_service_seq.NEXTVAL, 'Vaccination', 'SVC-009', 'Immunization service', 50, 15, specialty_id, 'Y' FROM test_specialties WHERE specialty_code = 'PED';

INSERT INTO test_services (service_id, service_name, service_code, description, standard_price, duration_minutes, specialty_id, is_active)
SELECT test_service_seq.NEXTVAL, 'Follow-up Visit', 'SVC-010', 'Post-treatment follow-up', 100, 20, specialty_id, 'Y' FROM test_specialties WHERE specialty_code = 'GP';

-- ========================================
-- MASTER DATA: Diagnosis Codes (10 codes)
-- ========================================

INSERT INTO test_diagnosis_codes (diagnosis_id, icd10_code, diagnosis_name, category, is_active)
VALUES (test_diagnosis_seq.NEXTVAL, 'I10', 'Essential Hypertension', 'Circulatory', 'Y');

INSERT INTO test_diagnosis_codes (diagnosis_id, icd10_code, diagnosis_name, category, is_active)
VALUES (test_diagnosis_seq.NEXTVAL, 'E11', 'Type 2 Diabetes Mellitus', 'Metabolic', 'Y');

INSERT INTO test_diagnosis_codes (diagnosis_id, icd10_code, diagnosis_name, category, is_active)
VALUES (test_diagnosis_seq.NEXTVAL, 'M79.3', 'Myalgia', 'Musculoskeletal', 'Y');

INSERT INTO test_diagnosis_codes (diagnosis_id, icd10_code, diagnosis_name, category, is_active)
VALUES (test_diagnosis_seq.NEXTVAL, 'L89', 'Pressure Ulcer', 'Skin', 'Y');

INSERT INTO test_diagnosis_codes (diagnosis_id, icd10_code, diagnosis_name, category, is_active)
VALUES (test_diagnosis_seq.NEXTVAL, 'J45.9', 'Asthma', 'Respiratory', 'Y');

INSERT INTO test_diagnosis_codes (diagnosis_id, icd10_code, diagnosis_name, category, is_active)
VALUES (test_diagnosis_seq.NEXTVAL, 'K21', 'GERD', 'Digestive', 'Y');

INSERT INTO test_diagnosis_codes (diagnosis_id, icd10_code, diagnosis_name, category, is_active)
VALUES (test_diagnosis_seq.NEXTVAL, 'F32', 'Depressive Disorder', 'Mental Health', 'Y');

INSERT INTO test_diagnosis_codes (diagnosis_id, icd10_code, diagnosis_name, category, is_active)
VALUES (test_diagnosis_seq.NEXTVAL, 'M17', 'Osteoarthritis Knee', 'Musculoskeletal', 'Y');

INSERT INTO test_diagnosis_codes (diagnosis_id, icd10_code, diagnosis_name, category, is_active)
VALUES (test_diagnosis_seq.NEXTVAL, 'I50', 'Heart Failure', 'Circulatory', 'Y');

INSERT INTO test_diagnosis_codes (diagnosis_id, icd10_code, diagnosis_name, category, is_active)
VALUES (test_diagnosis_seq.NEXTVAL, 'Z00.00', 'Encounter for General Adult Medical Exam', 'Preventive', 'Y');

-- ========================================
-- MASTER DATA: Providers (8 providers)
-- ========================================

INSERT INTO test_providers (provider_id, first_name, last_name, specialty_id, license_number, license_expiry_date, email, phone, is_active, hire_date)
SELECT test_provider_seq.NEXTVAL, 'Sarah', 'Mitchell', specialty_id, 'LIC-001', DATE '2026-12-31', 'sarah.mitchell@hospital.com', '555-5001', 'Y', TRUNC(SYSDATE)-365
FROM test_specialties WHERE specialty_code = 'CARD';

INSERT INTO test_providers (provider_id, first_name, last_name, specialty_id, license_number, license_expiry_date, email, phone, is_active, hire_date)
SELECT test_provider_seq.NEXTVAL, 'James', 'Anderson', specialty_id, 'LIC-002', DATE '2026-06-30', 'james.anderson@hospital.com', '555-5002', 'Y', TRUNC(SYSDATE)-730
FROM test_specialties WHERE specialty_code = 'ORTHO';

INSERT INTO test_providers (provider_id, first_name, last_name, specialty_id, license_number, license_expiry_date, email, phone, is_active, hire_date)
SELECT test_provider_seq.NEXTVAL, 'Emily', 'Davis', specialty_id, 'LIC-003', DATE '2027-03-15', 'emily.davis@hospital.com', '555-5003', 'Y', TRUNC(SYSDATE)-180
FROM test_specialties WHERE specialty_code = 'DERM';

INSERT INTO test_providers (provider_id, first_name, last_name, specialty_id, license_number, license_expiry_date, email, phone, is_active, hire_date)
SELECT test_provider_seq.NEXTVAL, 'Robert', 'Johnson', specialty_id, 'LIC-004', DATE '2026-09-20', 'robert.johnson@hospital.com', '555-5004', 'Y', TRUNC(SYSDATE)-550
FROM test_specialties WHERE specialty_code = 'GP';

INSERT INTO test_providers (provider_id, first_name, last_name, specialty_id, license_number, license_expiry_date, email, phone, is_active, hire_date)
SELECT test_provider_seq.NEXTVAL, 'Lisa', 'Thompson', specialty_id, 'LIC-005', DATE '2026-11-10', 'lisa.thompson@hospital.com', '555-5005', 'Y', TRUNC(SYSDATE)-365
FROM test_specialties WHERE specialty_code = 'PED';

INSERT INTO test_providers (provider_id, first_name, last_name, specialty_id, license_number, license_expiry_date, email, phone, is_active, hire_date)
SELECT test_provider_seq.NEXTVAL, 'Michael', 'Brown', specialty_id, 'LIC-006', DATE '2026-08-15', 'michael.brown@hospital.com', '555-5006', 'Y', TRUNC(SYSDATE)-600
FROM test_specialties WHERE specialty_code = 'CARD';

INSERT INTO test_providers (provider_id, first_name, last_name, specialty_id, license_number, license_expiry_date, email, phone, is_active, hire_date)
SELECT test_provider_seq.NEXTVAL, 'Jennifer', 'Wilson', specialty_id, 'LIC-007', DATE '2026-05-22', 'jennifer.wilson@hospital.com', '555-5007', 'Y', TRUNC(SYSDATE)-450
FROM test_specialties WHERE specialty_code = 'ORTHO';

INSERT INTO test_providers (provider_id, first_name, last_name, specialty_id, license_number, license_expiry_date, email, phone, is_active, hire_date)
SELECT test_provider_seq.NEXTVAL, 'David', 'Garcia', specialty_id, 'LIC-008', DATE '2027-01-30', 'david.garcia@hospital.com', '555-5008', 'Y', TRUNC(SYSDATE)-90
FROM test_specialties WHERE specialty_code = 'GP';

-- ========================================
-- RELATIONSHIP DATA: Patient-Insurance
-- ========================================

INSERT INTO test_patient_insurance (patient_id, insurance_id, policy_number, group_number, effective_date, is_primary)
SELECT p.patient_id, i.insurance_id, 'POL-'||LPAD(p.patient_id, 4, '0')||'-'||LPAD(i.insurance_id, 3, '0'), 'GRP-001', TRUNC(SYSDATE-365), 'Y'
FROM (SELECT patient_id, ROWNUM as rn FROM test_patients) p
CROSS JOIN (SELECT insurance_id FROM test_insurance_plans WHERE ROWNUM <= 1) i
WHERE p.rn <= 10;

INSERT INTO test_patient_insurance (patient_id, insurance_id, policy_number, group_number, effective_date, is_primary)
SELECT p.patient_id, i.insurance_id, 'POL-'||LPAD(p.patient_id, 4, '0')||'-'||LPAD(i.insurance_id, 3, '0'), 'GRP-002', TRUNC(SYSDATE-365), 'Y'
FROM (SELECT patient_id, ROWNUM as rn FROM test_patients) p
CROSS JOIN (SELECT insurance_id, ROWNUM as irn FROM test_insurance_plans) i
WHERE p.rn BETWEEN 11 AND 15 AND i.irn = 2;

-- ========================================
-- PROVIDER SCHEDULES
-- ========================================

INSERT INTO test_provider_schedules (schedule_id, provider_id, day_of_week, start_time, end_time, location, is_active)
SELECT test_schedule_seq.NEXTVAL, provider_id, 2, '09:00', '17:00', 'Main Clinic', 'Y' FROM test_providers;

INSERT INTO test_provider_schedules (schedule_id, provider_id, day_of_week, start_time, end_time, location, is_active)
SELECT test_schedule_seq.NEXTVAL, provider_id, 3, '09:00', '17:00', 'Main Clinic', 'Y' FROM test_providers;

INSERT INTO test_provider_schedules (schedule_id, provider_id, day_of_week, start_time, end_time, location, is_active)
SELECT test_schedule_seq.NEXTVAL, provider_id, 4, '09:00', '17:00', 'Main Clinic', 'Y' FROM test_providers;

INSERT INTO test_provider_schedules (schedule_id, provider_id, day_of_week, start_time, end_time, location, is_active)
SELECT test_schedule_seq.NEXTVAL, provider_id, 5, '09:00', '17:00', 'Satellite Office', 'Y' FROM test_providers;

INSERT INTO test_provider_schedules (schedule_id, provider_id, day_of_week, start_time, end_time, location, is_active)
SELECT test_schedule_seq.NEXTVAL, provider_id, 6, '10:00', '14:00', 'Main Clinic', 'Y' FROM test_providers WHERE ROWNUM <= 4;

-- ========================================
-- TRANSACTIONAL DATA: Appointments (30 appointments, varied statuses)
-- ========================================

-- Past completed appointments
INSERT INTO test_appointments (appointment_id, patient_id, provider_id, service_id, appointment_date, start_time, end_time, status, reason_for_visit)
SELECT test_appointment_seq.NEXTVAL, p.patient_id, prov.provider_id, s.service_id, TRUNC(SYSDATE)-30, 
  TIMESTAMP '2025-11-17 09:00:00', TIMESTAMP '2025-11-17 09:30:00', 'COMPLETED', 'Annual checkup'
FROM (SELECT patient_id FROM test_patients WHERE ROWNUM <= 3) p
CROSS JOIN (SELECT provider_id FROM test_providers WHERE ROWNUM <= 1) prov
CROSS JOIN (SELECT service_id FROM test_services WHERE service_code = 'SVC-001') s;

-- Scheduled for future
INSERT INTO test_appointments (appointment_id, patient_id, provider_id, service_id, appointment_date, start_time, end_time, status, reason_for_visit)
SELECT test_appointment_seq.NEXTVAL, p.patient_id, prov.provider_id, s.service_id, TRUNC(SYSDATE)+7,
  TIMESTAMP '2025-12-24 14:00:00', TIMESTAMP '2025-12-24 14:45:00', 'SCHEDULED', 'Cardiac evaluation'
FROM (SELECT patient_id FROM test_patients WHERE ROWNUM <= 3) p
CROSS JOIN (SELECT p.provider_id FROM test_providers p JOIN test_specialties sp ON p.specialty_id = sp.specialty_id WHERE sp.specialty_code = 'CARD' AND ROWNUM <= 1) prov
CROSS JOIN (SELECT service_id FROM test_services WHERE service_code = 'SVC-002') s;

-- Confirmed appointments
INSERT INTO test_appointments (appointment_id, patient_id, provider_id, service_id, appointment_date, start_time, end_time, status, reason_for_visit)
SELECT test_appointment_seq.NEXTVAL, p.patient_id, prov.provider_id, s.service_id, TRUNC(SYSDATE)+2,
  TIMESTAMP '2025-12-19 10:00:00', TIMESTAMP '2025-12-19 10:40:00', 'CONFIRMED', 'Orthopedic assessment'
FROM (SELECT patient_id FROM test_patients WHERE ROWNUM <= 4) p
CROSS JOIN (SELECT p.provider_id FROM test_providers p JOIN test_specialties sp ON p.specialty_id = sp.specialty_id WHERE sp.specialty_code = 'ORTHO' AND ROWNUM <= 1) prov
CROSS JOIN (SELECT service_id FROM test_services WHERE service_code = 'SVC-003') s;

-- No-show appointments
INSERT INTO test_appointments (appointment_id, patient_id, provider_id, service_id, appointment_date, start_time, end_time, status, reason_for_visit)
SELECT test_appointment_seq.NEXTVAL, p.patient_id, prov.provider_id, s.service_id, TRUNC(SYSDATE)-15,
  TIMESTAMP '2025-12-02 11:00:00', TIMESTAMP '2025-12-02 11:30:00', 'NO_SHOW', 'Dermatology consultation'
FROM (SELECT patient_id FROM test_patients WHERE ROWNUM <= 2) p
CROSS JOIN (SELECT p.provider_id FROM test_providers p JOIN test_specialties sp ON p.specialty_id = sp.specialty_id WHERE sp.specialty_code = 'DERM' AND ROWNUM <= 1) prov
CROSS JOIN (SELECT service_id FROM test_services WHERE service_code = 'SVC-005') s;

-- Cancelled appointments
INSERT INTO test_appointments (appointment_id, patient_id, provider_id, service_id, appointment_date, start_time, end_time, status, reason_for_visit)
SELECT test_appointment_seq.NEXTVAL, p.patient_id, prov.provider_id, s.service_id, TRUNC(SYSDATE)+14,
  TIMESTAMP '2025-12-31 15:30:00', TIMESTAMP '2025-12-31 16:00:00', 'CANCELLED', 'Patient requested cancellation'
FROM (SELECT patient_id FROM test_patients WHERE ROWNUM <= 2) p
CROSS JOIN (SELECT provider_id FROM test_providers WHERE ROWNUM <= 1) prov
CROSS JOIN (SELECT service_id FROM test_services WHERE service_code = 'SVC-007') s;

-- Checked-in appointments
INSERT INTO test_appointments (appointment_id, patient_id, provider_id, service_id, appointment_date, start_time, end_time, status, reason_for_visit)
SELECT test_appointment_seq.NEXTVAL, p.patient_id, prov.provider_id, s.service_id, TRUNC(SYSDATE)-3,
  TIMESTAMP '2025-12-14 13:00:00', TIMESTAMP '2025-12-14 13:35:00', 'CHECKED_IN', 'Follow-up visit'
FROM (SELECT patient_id FROM test_patients WHERE ROWNUM <= 5) p
CROSS JOIN (SELECT provider_id FROM test_providers WHERE ROWNUM <= 1) prov
CROSS JOIN (SELECT service_id FROM test_services WHERE service_code = 'SVC-010') s;

-- ========================================
-- EVENT DATA: Appointment Status History
-- ========================================

INSERT INTO test_appointment_status_history (appointment_id, old_status, new_status, changed_date, notes)
SELECT appointment_id, 'SCHEDULED', 'CONFIRMED', SYSTIMESTAMP, 'Patient confirmed via phone'
FROM test_appointments WHERE status = 'CONFIRMED' AND ROWNUM <= 4;

INSERT INTO test_appointment_status_history (appointment_id, old_status, new_status, changed_date, notes)
SELECT appointment_id, 'CONFIRMED', 'CHECKED_IN', SYSTIMESTAMP, 'Patient arrived'
FROM test_appointments WHERE status = 'CHECKED_IN' AND ROWNUM <= 5;

INSERT INTO test_appointment_status_history (appointment_id, old_status, new_status, changed_date, notes)
SELECT appointment_id, 'CHECKED_IN', 'COMPLETED', SYSTIMESTAMP, 'Visit completed'
FROM test_appointments WHERE status = 'COMPLETED' AND ROWNUM <= 3;

INSERT INTO test_appointment_status_history (appointment_id, old_status, new_status, changed_date, notes)
SELECT appointment_id, 'SCHEDULED', 'CANCELLED', SYSTIMESTAMP, 'Patient requested cancellation'
FROM test_appointments WHERE status = 'CANCELLED' AND ROWNUM <= 2;

INSERT INTO test_appointment_status_history (appointment_id, old_status, new_status, changed_date, notes)
SELECT appointment_id, 'SCHEDULED', 'NO_SHOW', SYSTIMESTAMP, 'Patient did not arrive'
FROM test_appointments WHERE status = 'NO_SHOW' AND ROWNUM <= 2;

-- ========================================
-- TRANSACTIONAL DATA: Visits (for completed appointments)
-- ========================================

INSERT INTO test_visits (visit_id, appointment_id, patient_id, provider_id, visit_date, check_in_time, check_out_time, 
                         chief_complaint, hpi, assessment, treatment_plan, follow_up_days, visit_status)
SELECT test_visit_seq.NEXTVAL, a.appointment_id, a.patient_id, a.provider_id, a.appointment_date,
  TIMESTAMP '2025-11-17 09:00:00', TIMESTAMP '2025-11-17 09:25:00',
  'Regular checkup', 'Patient reports feeling well', 'Vital signs stable, no abnormalities', 'Continue current health regimen', 365, 'COMPLETED'
FROM test_appointments a WHERE a.status = 'COMPLETED' AND a.appointment_date < TRUNC(SYSDATE) AND ROWNUM <= 3;

-- ========================================
-- VISIT SERVICES (Services provided during visits)
-- ========================================

INSERT INTO test_visit_services (visit_id, service_id, quantity, unit_price, discount_percentage)
SELECT v.visit_id, s.service_id, 1, s.standard_price, 10
FROM test_visits v
CROSS JOIN test_services s WHERE s.service_code = 'SVC-001';

-- ========================================
-- VISIT DIAGNOSES
-- ========================================

INSERT INTO test_visit_diagnoses (visit_id, diagnosis_id, is_primary)
SELECT v.visit_id, d.diagnosis_id, 'Y'
FROM test_visits v
CROSS JOIN test_diagnosis_codes d WHERE d.icd10_code = 'Z00.00';

-- ========================================
-- TRANSACTIONAL DATA: Bills (for visits with services)
-- ========================================

INSERT INTO test_bills (bill_id, visit_id, patient_id, bill_date, total_amount, insurance_covered, patient_responsibility, bill_status)
SELECT test_bill_seq.NEXTVAL, v.visit_id, v.patient_id, TRUNC(SYSDATE)-25, 165, 115, 50, 'PAID'
FROM test_visits v WHERE ROWNUM <= 2;

INSERT INTO test_bills (bill_id, visit_id, patient_id, bill_date, total_amount, insurance_covered, patient_responsibility, bill_status)
SELECT test_bill_seq.NEXTVAL, v.visit_id, v.patient_id, TRUNC(SYSDATE)-15, 270, 220, 50, 'PARTIAL'
FROM test_visits v WHERE ROWNUM > 2 AND ROWNUM <= 3;

-- ========================================
-- TRANSACTIONAL DATA: Claims (Insurance claims for bills)
-- ========================================

INSERT INTO test_claims (claim_id, bill_id, insurance_id, claim_number, claim_date, claim_amount, approved_amount, paid_amount, claim_status)
SELECT test_claim_seq.NEXTVAL, b.bill_id, pi.insurance_id, 'CLM-'||LPAD(test_claim_seq.NEXTVAL, 6, '0'), 
  TRUNC(SYSDATE)-20, b.insurance_covered, b.insurance_covered, b.insurance_covered, 'PAID'
FROM test_bills b
JOIN test_patient_insurance pi ON b.patient_id = pi.patient_id AND pi.is_primary = 'Y'
WHERE b.bill_status IN ('PAID', 'PARTIAL');

-- ========================================
-- Commit all data
-- ========================================

COMMIT;

PROMPT 'OLTP DML Data Load Complete - Sample data inserted successfully'
PROMPT 'Created:'
PROMPT '  - 5 Specialties'
PROMPT '  - 15 Patients'
PROMPT '  - 8 Providers'
PROMPT '  - 5 Insurance Plans'
PROMPT '  - 10 Services'
PROMPT '  - 30+ Appointments (various statuses)'
PROMPT '  - 3 Visits'
PROMPT '  - 2+ Bills'
PROMPT '  - 2+ Claims'
