-- ========================================
-- Healthcare Appointments System - ETL Load
-- PL/SQL Procedure Compilation ONLY
-- Oracle 23ai Compatible
-- ========================================

CREATE OR REPLACE PROCEDURE etl_load_healthcare(
    p_load_mode VARCHAR2 DEFAULT 'FULL',  -- 'FULL' or 'INCREMENTAL'
    p_log_table VARCHAR2 DEFAULT 'etl_load_log'
) IS
    v_record_count NUMBER := 0;
    v_error_count NUMBER := 0;
    v_start_time TIMESTAMP := SYSTIMESTAMP;
    v_load_id NUMBER;
    v_last_update_date DATE;
    v_sql_error VARCHAR2(1000);
BEGIN
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('ETL Load Started: ' || p_load_mode || ' mode');
    DBMS_OUTPUT.PUT_LINE('Start Time: ' || v_start_time);
    DBMS_OUTPUT.PUT_LINE('========================================');

    -- ========================================
    -- STEP 0: Clean up fact tables first (if FULL mode)
    -- ========================================
    IF p_load_mode = 'FULL' THEN
        DBMS_OUTPUT.PUT_LINE(CHR(10) || 'Step 0: Cleaning up fact and dimension tables...');
        DELETE FROM fact_bills_monthly;
        DELETE FROM fact_visits;
        DELETE FROM fact_appointments;
        DELETE FROM dim_provider;
        DELETE FROM dim_patient;
        DELETE FROM dim_insurance;
        DELETE FROM dim_diagnosis;
        DELETE FROM dim_service;
        DELETE FROM dim_specialty;
        DELETE FROM dim_date;
        DBMS_OUTPUT.PUT_LINE('  All tables cleaned for FULL load');
    END IF;

    -- ========================================
    -- STEP 1: Load DIM_DATE (Reference Data)
    -- ========================================
    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'Step 1: Loading DIM_DATE...');
    
    IF p_load_mode = 'FULL' THEN
        NULL;  -- Already deleted above
    END IF;

    INSERT INTO dim_date (date_key, calendar_date, year_number, quarter_number, 
                          month_number, week_number, day_of_month, day_of_week, 
                          day_name, month_name, quarter_name, is_weekend, is_holiday)
    WITH date_range AS (
        SELECT TO_DATE('2024-01-01', 'YYYY-MM-DD') + LEVEL - 1 as dt
        FROM DUAL
        CONNECT BY LEVEL <= 1095  -- 3 years of dates
    )
    SELECT 
        TO_NUMBER(TO_CHAR(dt, 'YYYYMMDD')) as date_key,
        dt as calendar_date,
        TO_NUMBER(TO_CHAR(dt, 'YYYY')) as year_number,
        TO_NUMBER(TO_CHAR(dt, 'Q')) as quarter_number,
        TO_NUMBER(TO_CHAR(dt, 'MM')) as month_number,
        TO_NUMBER(TO_CHAR(dt, 'WW')) as week_number,
        TO_NUMBER(TO_CHAR(dt, 'DD')) as day_of_month,
        TO_NUMBER(TO_CHAR(dt, 'D')) as day_of_week,
        TO_CHAR(dt, 'DAY') as day_name,
        TO_CHAR(dt, 'MONTH') as month_name,
        'Q' || TO_CHAR(dt, 'Q') || ' ' || TO_CHAR(dt, 'YYYY') as quarter_name,
        CASE WHEN TO_NUMBER(TO_CHAR(dt, 'D')) IN (1, 7) THEN 'Y' ELSE 'N' END as is_weekend,
        'N' as is_holiday
    FROM date_range
    WHERE NOT EXISTS (SELECT 1 FROM dim_date dd WHERE dd.calendar_date = dt);
    
    v_record_count := SQL%ROWCOUNT;
    DBMS_OUTPUT.PUT_LINE('  DIM_DATE: ' || v_record_count || ' rows inserted/updated');

    -- ========================================
    -- STEP 2: Load DIM_SPECIALTY (Reference Data)
    -- ========================================
    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'Step 2: Loading DIM_SPECIALTY...');
    
    INSERT INTO dim_specialty (specialty_key, specialty_id, specialty_name, specialty_code, is_active)
    SELECT 
        specialty_id as specialty_key,
        specialty_id,
        specialty_name,
        specialty_code,
        is_active
    FROM test_specialties s
    WHERE NOT EXISTS (SELECT 1 FROM dim_specialty ds WHERE ds.specialty_id = s.specialty_id);
    
    v_record_count := SQL%ROWCOUNT;
    DBMS_OUTPUT.PUT_LINE('  DIM_SPECIALTY: ' || v_record_count || ' rows inserted/updated');

    -- ========================================
    -- STEP 3: Load DIM_SERVICE (Reference Data)
    -- ========================================
    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'Step 3: Loading DIM_SERVICE...');
    
    INSERT INTO dim_service (service_key, service_id, service_name, service_code, 
                             standard_price, duration_minutes, specialty_code, is_active)
    SELECT 
        service_id as service_key,
        service_id,
        service_name,
        service_code,
        standard_price,
        duration_minutes,
        s.specialty_code,
        svc.is_active
    FROM test_services svc
    LEFT JOIN test_specialties s ON svc.specialty_id = s.specialty_id
    WHERE NOT EXISTS (SELECT 1 FROM dim_service ds WHERE ds.service_id = svc.service_id);
    
    v_record_count := SQL%ROWCOUNT;
    DBMS_OUTPUT.PUT_LINE('  DIM_SERVICE: ' || v_record_count || ' rows inserted/updated');

    -- ========================================
    -- STEP 4: Load DIM_DIAGNOSIS (Reference Data)
    -- ========================================
    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'Step 4: Loading DIM_DIAGNOSIS...');
    
    INSERT INTO dim_diagnosis (diagnosis_key, diagnosis_id, icd10_code, diagnosis_name, category, is_active)
    SELECT 
        diagnosis_id as diagnosis_key,
        diagnosis_id,
        icd10_code,
        diagnosis_name,
        category,
        is_active
    FROM test_diagnosis_codes d
    WHERE NOT EXISTS (SELECT 1 FROM dim_diagnosis dd WHERE dd.diagnosis_id = d.diagnosis_id);
    
    v_record_count := SQL%ROWCOUNT;
    DBMS_OUTPUT.PUT_LINE('  DIM_DIAGNOSIS: ' || v_record_count || ' rows inserted/updated');

    -- ========================================
    -- STEP 5: Load DIM_INSURANCE (Reference Data)
    -- ========================================
    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'Step 5: Loading DIM_INSURANCE...');
    
    INSERT INTO dim_insurance (insurance_key, insurance_id, plan_name, plan_code, 
                               provider_name, coverage_percentage, copay_amount, 
                               deductible_amount, is_active)
    SELECT 
        ROWNUM as insurance_key,
        insurance_id,
        plan_name,
        plan_code,
        provider_name,
        coverage_percentage,
        copay_amount,
        deductible_amount,
        is_active
    FROM test_insurance_plans i
    WHERE NOT EXISTS (SELECT 1 FROM dim_insurance di WHERE di.insurance_id = i.insurance_id);
    
    v_record_count := SQL%ROWCOUNT;
    DBMS_OUTPUT.PUT_LINE('  DIM_INSURANCE: ' || v_record_count || ' rows inserted/updated');

    -- ========================================
    -- STEP 6: Load DIM_PATIENT (SCD Type 2)
    -- ========================================
    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'Step 6: Loading DIM_PATIENT (SCD Type 2)...');
    
    -- Mark old records as inactive if patient has changed
    UPDATE dim_patient dp
    SET current_flag = 'N', effective_to = TRUNC(SYSDATE) - 1
    WHERE current_flag = 'Y'
      AND EXISTS (
          SELECT 1 FROM test_patients tp
          WHERE tp.patient_id = dp.patient_id
            AND (tp.is_active != dp.is_active 
                 OR NVL(tp.city, 'NULL') != NVL(dp.city, 'NULL'))
      );

    -- Insert new/changed records
    INSERT INTO dim_patient (patient_key, patient_id, patient_name, date_of_birth, gender, 
                             city, state, age_group, is_active, current_flag, effective_from)
    SELECT 
        ROWNUM + NVL((SELECT MAX(patient_key) FROM dim_patient), 0),
        tp.patient_id,
        TRIM(tp.first_name || ' ' || tp.last_name),
        tp.date_of_birth,
        tp.gender,
        tp.city,
        tp.state,
        CASE 
            WHEN TRUNC((SYSDATE - tp.date_of_birth) / 365.25) < 20 THEN 'Under 20'
            WHEN TRUNC((SYSDATE - tp.date_of_birth) / 365.25) < 40 THEN '20-39'
            WHEN TRUNC((SYSDATE - tp.date_of_birth) / 365.25) < 60 THEN '40-59'
            ELSE '60+'
        END,
        tp.is_active,
        'Y',
        TRUNC(SYSDATE)
    FROM test_patients tp
    WHERE NOT EXISTS (
        SELECT 1 FROM dim_patient dp 
        WHERE dp.patient_id = tp.patient_id AND dp.current_flag = 'Y'
    );
    
    v_record_count := SQL%ROWCOUNT;
    DBMS_OUTPUT.PUT_LINE('  DIM_PATIENT: ' || v_record_count || ' rows inserted (SCD Type 2)');

    -- ========================================
    -- STEP 7: Load DIM_PROVIDER (SCD Type 2)
    -- ========================================
    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'Step 7: Loading DIM_PROVIDER (SCD Type 2)...');
    
    -- Mark old records as inactive if provider has changed
    UPDATE dim_provider dprov
    SET current_flag = 'N', effective_to = TRUNC(SYSDATE) - 1
    WHERE current_flag = 'Y'
      AND EXISTS (
          SELECT 1 FROM test_providers tprov
          JOIN test_specialties spec ON tprov.specialty_id = spec.specialty_id
          WHERE tprov.provider_id = dprov.provider_id
            AND (tprov.is_active != dprov.is_active 
                 OR NVL(spec.specialty_code, 'NULL') != NVL(dprov.specialty_code, 'NULL')
                 OR NVL(tprov.license_number, 'NULL') != NVL(dprov.license_number, 'NULL'))
      );

    -- Insert new/changed records
    INSERT INTO dim_provider (provider_key, provider_id, provider_name, specialty_code, 
                              specialty_name, license_number, license_expiry_date, 
                              hire_date, is_active, current_flag, effective_from)
    SELECT 
        ROWNUM + NVL((SELECT MAX(provider_key) FROM dim_provider), 0),
        tp.provider_id,
        TRIM(tp.first_name || ' ' || tp.last_name),
        s.specialty_code,
        s.specialty_name,
        tp.license_number,
        tp.license_expiry_date,
        tp.hire_date,
        tp.is_active,
        'Y',
        TRUNC(SYSDATE)
    FROM test_providers tp
    JOIN test_specialties s ON tp.specialty_id = s.specialty_id
    WHERE NOT EXISTS (
        SELECT 1 FROM dim_provider dprov
        WHERE dprov.provider_id = tp.provider_id AND dprov.current_flag = 'Y'
    );
    
    v_record_count := SQL%ROWCOUNT;
    DBMS_OUTPUT.PUT_LINE('  DIM_PROVIDER: ' || v_record_count || ' rows inserted (SCD Type 2)');

    -- ========================================
    -- STEP 8: Load FACT_APPOINTMENTS (Transaction Fact)
    -- ========================================
    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'Step 8: Loading FACT_APPOINTMENTS...');
    
    INSERT INTO fact_appointments (appointment_key, appointment_id, date_key, patient_key, 
                                   provider_key, service_key, specialty_key, status_key,
                                   duration_minutes, is_completed, is_noshow, is_cancelled)
    SELECT 
        ta.appointment_id as appointment_key,
        ta.appointment_id,
        TO_NUMBER(TO_CHAR(ta.appointment_date, 'YYYYMMDD')) as date_key,
        dp.patient_key,
        dprov.provider_key,
        ds.service_key,
        dspec.specialty_key,
        dstatus.status_key,
        ROUND((CAST(ta.end_time AS DATE) - CAST(ta.start_time AS DATE)) * 24 * 60) as duration_minutes,
        CASE WHEN ta.status = 'COMPLETED' THEN 'Y' ELSE 'N' END,
        CASE WHEN ta.status = 'NO_SHOW' THEN 'Y' ELSE 'N' END,
        CASE WHEN ta.status = 'CANCELLED' THEN 'Y' ELSE 'N' END
    FROM test_appointments ta
    JOIN dim_patient dp ON ta.patient_id = dp.patient_id AND dp.current_flag = 'Y'
    JOIN dim_provider dprov ON ta.provider_id = dprov.provider_id AND dprov.current_flag = 'Y'
    JOIN dim_service ds ON ta.service_id = ds.service_id
    JOIN test_providers tprov ON ta.provider_id = tprov.provider_id
    JOIN test_specialties tspec ON tprov.specialty_id = tspec.specialty_id
    JOIN dim_specialty dspec ON tspec.specialty_id = dspec.specialty_id
    JOIN dim_appointment_status dstatus ON ta.status = dstatus.status_code
    WHERE NOT EXISTS (SELECT 1 FROM fact_appointments fa WHERE fa.appointment_id = ta.appointment_id);
    
    v_record_count := SQL%ROWCOUNT;
    DBMS_OUTPUT.PUT_LINE('  FACT_APPOINTMENTS: ' || v_record_count || ' rows inserted');

    -- ========================================
    -- STEP 9: Load FACT_VISITS (Transaction Fact)
    -- ========================================
    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'Step 9: Loading FACT_VISITS...');
    
    INSERT INTO fact_visits (visit_key, visit_id, appointment_id, date_key, patient_key, 
                             provider_key, service_key, specialty_key, insurance_key,
                             visit_duration_minutes, total_service_amount, has_diagnosis)
    SELECT 
        tv.visit_id as visit_key,
        tv.visit_id,
        tv.appointment_id,
        TO_NUMBER(TO_CHAR(tv.visit_date, 'YYYYMMDD')) as date_key,
        dp.patient_key,
        dprov.provider_key,
        COALESCE(MAX(ds.service_key), -1),
        dspec.specialty_key,
        COALESCE(di.insurance_key, -1),
        ROUND((CAST(tv.check_out_time AS DATE) - CAST(tv.check_in_time AS DATE)) * 24 * 60) as visit_duration_minutes,
        COALESCE(SUM(vs.unit_price * vs.quantity), 0) as total_service_amount,
        CASE WHEN EXISTS (SELECT 1 FROM test_visit_diagnoses tvd WHERE tvd.visit_id = tv.visit_id) THEN 'Y' ELSE 'N' END
    FROM test_visits tv
    JOIN dim_patient dp ON tv.patient_id = dp.patient_id AND dp.current_flag = 'Y'
    JOIN dim_provider dprov ON tv.provider_id = dprov.provider_id AND dprov.current_flag = 'Y'
    JOIN test_providers tprov ON tv.provider_id = tprov.provider_id
    JOIN test_specialties tspec ON tprov.specialty_id = tspec.specialty_id
    JOIN dim_specialty dspec ON tspec.specialty_id = dspec.specialty_id
    LEFT JOIN test_visit_services vs ON tv.visit_id = vs.visit_id
    LEFT JOIN dim_service ds ON vs.service_id = ds.service_id
    LEFT JOIN test_patient_insurance tpi ON tv.patient_id = tpi.patient_id AND tpi.is_primary = 'Y'
    LEFT JOIN dim_insurance di ON tpi.insurance_id = di.insurance_id
    WHERE NOT EXISTS (SELECT 1 FROM fact_visits fv WHERE fv.visit_id = tv.visit_id)
    GROUP BY tv.visit_id, tv.appointment_id, tv.visit_date, tv.patient_id, tv.provider_id, 
             dp.patient_key, dprov.provider_key, dspec.specialty_key, di.insurance_key,
             tv.check_out_time, tv.check_in_time;
    
    v_record_count := SQL%ROWCOUNT;
    DBMS_OUTPUT.PUT_LINE('  FACT_VISITS: ' || v_record_count || ' rows inserted');

    -- ========================================
    -- STEP 10: Load FACT_BILLS_MONTHLY (Snapshot Fact)
    -- ========================================
    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'Step 10: Loading FACT_BILLS_MONTHLY (Snapshot)...');
    
    INSERT INTO fact_bills_monthly (bill_key, year_month, date_key, patient_key, insurance_key,
                                    total_bills_count, total_bill_amount, total_insurance_covered,
                                    total_patient_responsibility, total_paid_amount, 
                                    bills_paid_count, bills_partial_count, bills_pending_count)
    SELECT 
        ROW_NUMBER() OVER (ORDER BY year_month, patient_key) + NVL((SELECT MAX(bill_key) FROM fact_bills_monthly), 0) as bill_key,
        year_month,
        date_key,
        patient_key,
        insurance_key,
        total_bills_count,
        total_bill_amount,
        total_insurance_covered,
        total_patient_responsibility,
        total_paid_amount,
        bills_paid_count,
        bills_partial_count,
        bills_pending_count
    FROM (
        SELECT 
            TO_CHAR(TRUNC(tb.bill_date, 'MM'), 'YYYY-MM') as year_month,
            TO_NUMBER(TO_CHAR(LAST_DAY(tb.bill_date), 'YYYYMMDD')) as date_key,
            dp.patient_key,
            COALESCE(di.insurance_key, -1) as insurance_key,
            COUNT(*) as total_bills_count,
            SUM(tb.total_amount) as total_bill_amount,
            SUM(tb.insurance_covered) as total_insurance_covered,
            SUM(tb.patient_responsibility) as total_patient_responsibility,
            SUM(tb.paid_amount) as total_paid_amount,
            SUM(CASE WHEN tb.bill_status = 'PAID' THEN 1 ELSE 0 END) as bills_paid_count,
            SUM(CASE WHEN tb.bill_status = 'PARTIAL' THEN 1 ELSE 0 END) as bills_partial_count,
            SUM(CASE WHEN tb.bill_status = 'PENDING' THEN 1 ELSE 0 END) as bills_pending_count
        FROM test_bills tb
        JOIN dim_patient dp ON tb.patient_id = dp.patient_id AND dp.current_flag = 'Y'
        LEFT JOIN test_patient_insurance tpi ON tb.patient_id = tpi.patient_id AND tpi.is_primary = 'Y'
        LEFT JOIN dim_insurance di ON tpi.insurance_id = di.insurance_id
        WHERE NOT EXISTS (
            SELECT 1 FROM fact_bills_monthly fbm 
            WHERE fbm.patient_key = dp.patient_key 
              AND fbm.year_month = TO_CHAR(TRUNC(tb.bill_date, 'MM'), 'YYYY-MM')
        )
        GROUP BY TO_CHAR(TRUNC(tb.bill_date, 'MM'), 'YYYY-MM'), 
                 TO_NUMBER(TO_CHAR(LAST_DAY(tb.bill_date), 'YYYYMMDD')), 
                 dp.patient_key, COALESCE(di.insurance_key, -1)
    );
    
    v_record_count := SQL%ROWCOUNT;
    DBMS_OUTPUT.PUT_LINE('  FACT_BILLS_MONTHLY: ' || v_record_count || ' rows inserted');

    -- ========================================
    -- STEP 11: Refresh Materialized Views
    -- ========================================
    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'Step 11: Refreshing Materialized Views...');
    
    BEGIN
        DBMS_MVIEW.REFRESH('mv_appt_by_provider_specialty', 'C');
        DBMS_OUTPUT.PUT_LINE('  Refreshed: mv_appt_by_provider_specialty');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('  Warning: Could not refresh mv_appt_by_provider_specialty');
    END;

    BEGIN
        DBMS_MVIEW.REFRESH('mv_patient_visits_monthly', 'C');
        DBMS_OUTPUT.PUT_LINE('  Refreshed: mv_patient_visits_monthly');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('  Warning: Could not refresh mv_patient_visits_monthly');
    END;

    -- ========================================
    -- Final Commit
    -- ========================================
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '========================================');
    DBMS_OUTPUT.PUT_LINE('ETL Load Completed Successfully');
    DBMS_OUTPUT.PUT_LINE('Duration: ' || ROUND(EXTRACT(DAY FROM (SYSTIMESTAMP - v_start_time)) * 24 * 60 + 
                         EXTRACT(HOUR FROM (SYSTIMESTAMP - v_start_time)) * 60 + 
                         EXTRACT(MINUTE FROM (SYSTIMESTAMP - v_start_time)) + 
                         EXTRACT(SECOND FROM (SYSTIMESTAMP - v_start_time)) / 60, 2) || ' minutes');
    DBMS_OUTPUT.PUT_LINE('========================================');

EXCEPTION WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ETL Load Failed with Error:');
    DBMS_OUTPUT.PUT_LINE(SQLCODE || ': ' || SQLERRM);
    RAISE;
END etl_load_healthcare;
/

SHOW ERRORS

PROMPT 'Procedure compilation completed - check for errors above'
