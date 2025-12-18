-- Check OLTP data
SELECT 'Patients' AS entity, COUNT(*) FROM test_patients
UNION ALL SELECT 'Appointments', COUNT(*) FROM test_appointments;

-- Check OLAP data
SELECT 'dim_patient' AS dim, COUNT(*) FROM dim_patient
UNION ALL SELECT 'fact_appointments', COUNT(*) FROM fact_appointments;

-- Check documents
SELECT COUNT(*) FROM test_visit_documents;