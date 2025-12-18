-- ========================================
-- Healthcare Appointments System - KPI Report
-- Comprehensive Analytics and Key Performance Indicators
-- Oracle 19c Compatible
-- ========================================

SET DEFINE OFF
SET SERVEROUTPUT ON SIZE UNLIMITED

-- ========================================
-- REPORTING PROCEDURE: Comprehensive KPI Report
-- Parameters: report_month (YYYY-MM format), segment (specialty or 'ALL')
-- ========================================

CREATE OR REPLACE PROCEDURE generate_kpi_report(
    p_report_month VARCHAR2 DEFAULT TO_CHAR(TRUNC(SYSDATE, 'MM'), 'YYYY-MM'),
    p_segment VARCHAR2 DEFAULT 'ALL',
    p_report_title VARCHAR2 DEFAULT 'Healthcare Appointments System - KPI Report'
) IS
    -- Report metrics
    v_total_appointments NUMBER := 0;
    v_completed_appointments NUMBER := 0;
    v_cancelled_appointments NUMBER := 0;
    v_noshow_appointments NUMBER := 0;
    v_total_patients NUMBER := 0;
    v_active_patients NUMBER := 0;
    v_total_revenue NUMBER := 0;
    v_insurance_paid NUMBER := 0;
    v_patient_responsibility NUMBER := 0;
    v_completion_rate DECIMAL(5,2) := 0;
    v_cancellation_rate DECIMAL(5,2) := 0;
    v_noshow_rate DECIMAL(5,2) := 0;
    v_insurance_collection_rate DECIMAL(5,2) := 0;
    v_avg_visit_duration NUMBER := 0;
    v_total_visits NUMBER := 0;
    v_avg_visit_cost NUMBER := 0;
    v_avg_appt_duration NUMBER := 0;
    v_previous_month VARCHAR2(7);
    v_prev_appointments NUMBER := 0;
    v_prev_revenue NUMBER := 0;
    v_appt_trend DECIMAL(7,2) := 0;
    v_revenue_trend DECIMAL(7,2) := 0;

BEGIN
    -- Calculate previous month for trend analysis
    v_previous_month := TO_CHAR(TRUNC(ADD_MONTHS(TO_DATE(p_report_month, 'YYYY-MM'), -1), 'MM'), 'YYYY-MM');

    -- ========================================
    -- HEADER SECTION
    -- ========================================
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 100, '='));
    DBMS_OUTPUT.PUT_LINE(RPAD(' ', 25) || p_report_title);
    DBMS_OUTPUT.PUT_LINE(RPAD(' ', 30) || 'Report Period: ' || p_report_month);
    DBMS_OUTPUT.PUT_LINE(RPAD(' ', 25) || 'Report Generated: ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS'));
    IF p_segment = 'ALL' THEN
        DBMS_OUTPUT.PUT_LINE(RPAD(' ', 35) || 'Segment: All Specialties');
    ELSE
        DBMS_OUTPUT.PUT_LINE(RPAD(' ', 35) || 'Segment: ' || p_segment);
    END IF;
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 100, '='));

    -- ========================================
    -- SECTION 1: APPOINTMENT VOLUME KPIs
    -- ========================================
    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'SECTION 1: APPOINTMENT VOLUME & COMPLETION METRICS');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 100, '-'));

    BEGIN
        SELECT COUNT(*) INTO v_total_appointments
        FROM fact_appointments fa
        JOIN dim_date dd ON fa.date_key = dd.date_key
        WHERE TO_CHAR(dd.calendar_date, 'YYYY-MM') = p_report_month
          AND (p_segment = 'ALL' OR EXISTS (
              SELECT 1 FROM dim_specialty ds WHERE ds.specialty_key = fa.specialty_key AND ds.specialty_code = p_segment
          ));
    EXCEPTION WHEN OTHERS THEN v_total_appointments := 0;
    END;

    BEGIN
        SELECT COUNT(*) INTO v_completed_appointments
        FROM fact_appointments fa
        JOIN dim_date dd ON fa.date_key = dd.date_key
        WHERE TO_CHAR(dd.calendar_date, 'YYYY-MM') = p_report_month
          AND fa.is_completed = 'Y'
          AND (p_segment = 'ALL' OR EXISTS (
              SELECT 1 FROM dim_specialty ds WHERE ds.specialty_key = fa.specialty_key AND ds.specialty_code = p_segment
          ));
    EXCEPTION WHEN OTHERS THEN v_completed_appointments := 0;
    END;

    BEGIN
        SELECT COUNT(*) INTO v_cancelled_appointments
        FROM fact_appointments fa
        JOIN dim_date dd ON fa.date_key = dd.date_key
        WHERE TO_CHAR(dd.calendar_date, 'YYYY-MM') = p_report_month
          AND fa.is_cancelled = 'Y'
          AND (p_segment = 'ALL' OR EXISTS (
              SELECT 1 FROM dim_specialty ds WHERE ds.specialty_key = fa.specialty_key AND ds.specialty_code = p_segment
          ));
    EXCEPTION WHEN OTHERS THEN v_cancelled_appointments := 0;
    END;

    BEGIN
        SELECT COUNT(*) INTO v_noshow_appointments
        FROM fact_appointments fa
        JOIN dim_date dd ON fa.date_key = dd.date_key
        WHERE TO_CHAR(dd.calendar_date, 'YYYY-MM') = p_report_month
          AND fa.is_noshow = 'Y'
          AND (p_segment = 'ALL' OR EXISTS (
              SELECT 1 FROM dim_specialty ds WHERE ds.specialty_key = fa.specialty_key AND ds.specialty_code = p_segment
          ));
    EXCEPTION WHEN OTHERS THEN v_noshow_appointments := 0;
    END;

    -- Calculate rates
    IF v_total_appointments > 0 THEN
        v_completion_rate := ROUND(100.0 * v_completed_appointments / v_total_appointments, 2);
        v_cancellation_rate := ROUND(100.0 * v_cancelled_appointments / v_total_appointments, 2);
        v_noshow_rate := ROUND(100.0 * v_noshow_appointments / v_total_appointments, 2);
    END IF;

    DBMS_OUTPUT.PUT_LINE('Total Appointments:        ' || LPAD(v_total_appointments, 10) || '  appointments');
    DBMS_OUTPUT.PUT_LINE('Completed Appointments:    ' || LPAD(v_completed_appointments, 10) || '  appointments');
    DBMS_OUTPUT.PUT_LINE('Cancelled Appointments:    ' || LPAD(v_cancelled_appointments, 10) || '  appointments');
    DBMS_OUTPUT.PUT_LINE('No-Show Appointments:      ' || LPAD(v_noshow_appointments, 10) || '  appointments');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('KPI-001: Appointment Completion Rate      ' || LPAD(v_completion_rate || '%', 10));
    DBMS_OUTPUT.PUT_LINE('KPI-002: Appointment Cancellation Rate    ' || LPAD(v_cancellation_rate || '%', 10));
    DBMS_OUTPUT.PUT_LINE('KPI-003: Appointment No-Show Rate         ' || LPAD(v_noshow_rate || '%', 10));

    -- ========================================
    -- SECTION 2: FINANCIAL METRICS
    -- ========================================
    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'SECTION 2: FINANCIAL METRICS');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 100, '-'));

    BEGIN
        SELECT 
            NVL(SUM(total_bill_amount), 0),
            NVL(SUM(total_insurance_covered), 0),
            NVL(SUM(total_patient_responsibility), 0)
        INTO v_total_revenue, v_insurance_paid, v_patient_responsibility
        FROM fact_bills_monthly
        WHERE year_month = p_report_month;
    EXCEPTION WHEN OTHERS THEN
        v_total_revenue := 0;
        v_insurance_paid := 0;
        v_patient_responsibility := 0;
    END;

    IF v_total_revenue > 0 THEN
        v_insurance_collection_rate := ROUND(100.0 * v_insurance_paid / v_total_revenue, 2);
    END IF;

    DBMS_OUTPUT.PUT_LINE('Total Revenue Billed:      $' || LPAD(ROUND(v_total_revenue, 2), 12, ' '));
    DBMS_OUTPUT.PUT_LINE('Insurance Coverage:        $' || LPAD(ROUND(v_insurance_paid, 2), 12, ' '));
    DBMS_OUTPUT.PUT_LINE('Patient Responsibility:    $' || LPAD(ROUND(v_patient_responsibility, 2), 12, ' '));
    DBMS_OUTPUT.PUT_LINE('');
    IF v_total_appointments > 0 THEN
        DBMS_OUTPUT.PUT_LINE('KPI-004: Revenue per Appointment          $' || LPAD(ROUND(v_total_revenue / v_total_appointments, 2), 10, ' '));
    ELSE
        DBMS_OUTPUT.PUT_LINE('KPI-004: Revenue per Appointment          $' || LPAD('0.00', 10, ' '));
    END IF;
    DBMS_OUTPUT.PUT_LINE('KPI-005: Insurance Collection Rate        ' || LPAD(v_insurance_collection_rate || '%', 10));
    DBMS_OUTPUT.PUT_LINE('KPI-006: Patient Out-of-Pocket %          ' || LPAD(ROUND(100.0 - v_insurance_collection_rate, 2) || '%', 10));

    -- ========================================
    -- SECTION 3: VISIT & CLINICAL METRICS
    -- ========================================
    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'SECTION 3: VISIT & CLINICAL METRICS');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 100, '-'));

    BEGIN
        SELECT 
            COUNT(*),
            ROUND(AVG(visit_duration_minutes), 2),
            ROUND(AVG(total_service_amount), 2)
        INTO v_total_visits, v_avg_visit_duration, v_avg_visit_cost
        FROM fact_visits fv
        JOIN dim_date dd ON fv.date_key = dd.date_key
        WHERE TO_CHAR(dd.calendar_date, 'YYYY-MM') = p_report_month
          AND (p_segment = 'ALL' OR EXISTS (
              SELECT 1 FROM dim_specialty ds WHERE ds.specialty_key = fv.specialty_key AND ds.specialty_code = p_segment
          ));
    EXCEPTION WHEN OTHERS THEN
        v_total_visits := 0;
        v_avg_visit_duration := 0;
        v_avg_visit_cost := 0;
    END;

    DBMS_OUTPUT.PUT_LINE('Total Completed Visits:    ' || LPAD(v_total_visits, 10) || '  visits');
    DBMS_OUTPUT.PUT_LINE('Average Visit Duration:    ' || LPAD(v_avg_visit_duration || ' min', 10));
    DBMS_OUTPUT.PUT_LINE('Average Visit Cost:        $' || LPAD(ROUND(v_avg_visit_cost, 2), 10, ' '));
    DBMS_OUTPUT.PUT_LINE('');
    
    BEGIN
        SELECT ROUND(AVG(duration_minutes), 2) INTO v_avg_appt_duration
        FROM fact_appointments fa
        JOIN dim_date dd ON fa.date_key = dd.date_key
        WHERE TO_CHAR(dd.calendar_date, 'YYYY-MM') = p_report_month;
    EXCEPTION WHEN OTHERS THEN v_avg_appt_duration := 0;
    END;
    
    DBMS_OUTPUT.PUT_LINE('KPI-007: Average Appointment Duration     ' || LPAD(v_avg_appt_duration || ' min', 10));

    -- ========================================
    -- SECTION 4: PATIENT ENGAGEMENT
    -- ========================================
    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'SECTION 4: PATIENT ENGAGEMENT METRICS');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 100, '-'));

    BEGIN
        SELECT COUNT(DISTINCT patient_key) INTO v_total_patients
        FROM fact_appointments fa
        JOIN dim_date dd ON fa.date_key = dd.date_key
        WHERE TO_CHAR(dd.calendar_date, 'YYYY-MM') = p_report_month
          AND (p_segment = 'ALL' OR EXISTS (
              SELECT 1 FROM dim_specialty ds WHERE ds.specialty_key = fa.specialty_key AND ds.specialty_code = p_segment
          ));
    EXCEPTION WHEN OTHERS THEN v_total_patients := 0;
    END;

    BEGIN
        SELECT COUNT(*) INTO v_active_patients
        FROM dim_patient
        WHERE is_active = 'Y' AND current_flag = 'Y';
    EXCEPTION WHEN OTHERS THEN v_active_patients := 0;
    END;

    DBMS_OUTPUT.PUT_LINE('Unique Patients Treated:   ' || LPAD(v_total_patients, 10) || '  patients');
    DBMS_OUTPUT.PUT_LINE('Total Active Patients:     ' || LPAD(v_active_patients, 10) || '  patients');
    DBMS_OUTPUT.PUT_LINE('');
    IF v_total_patients > 0 THEN
        DBMS_OUTPUT.PUT_LINE('KPI-008: Patient Appointment Frequency    ' || LPAD(ROUND(v_total_appointments / v_total_patients, 2), 10));
    ELSE
        DBMS_OUTPUT.PUT_LINE('KPI-008: Patient Appointment Frequency    ' || LPAD('0.00', 10));
    END IF;
    IF v_active_patients > 0 THEN
        DBMS_OUTPUT.PUT_LINE('KPI-009: Active Patient Utilization Rate  ' || LPAD(ROUND(100.0 * v_total_patients / v_active_patients, 2) || '%', 10));
    ELSE
        DBMS_OUTPUT.PUT_LINE('KPI-009: Active Patient Utilization Rate  ' || LPAD('0.00%', 10));
    END IF;

    -- ========================================
    -- SECTION 5: TREND ANALYSIS (vs Previous Month)
    -- ========================================
    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'SECTION 5: TREND ANALYSIS (vs Previous Month: ' || v_previous_month || ')');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 100, '-'));

    BEGIN
        SELECT COUNT(*) INTO v_prev_appointments
        FROM fact_appointments fa
        JOIN dim_date dd ON fa.date_key = dd.date_key
        WHERE TO_CHAR(dd.calendar_date, 'YYYY-MM') = v_previous_month;
    EXCEPTION WHEN OTHERS THEN v_prev_appointments := 0;
    END;

    BEGIN
        SELECT NVL(SUM(total_bill_amount), 0) INTO v_prev_revenue
        FROM fact_bills_monthly
        WHERE year_month = v_previous_month;
    EXCEPTION WHEN OTHERS THEN v_prev_revenue := 0;
    END;

    -- Calculate trend percentages
    IF v_prev_appointments > 0 THEN
        v_appt_trend := ROUND(100.0 * (v_total_appointments - v_prev_appointments) / v_prev_appointments, 2);
    ELSE
        v_appt_trend := 0;
    END IF;

    IF v_prev_revenue > 0 THEN
        v_revenue_trend := ROUND(100.0 * (v_total_revenue - v_prev_revenue) / v_prev_revenue, 2);
    ELSE
        v_revenue_trend := 0;
    END IF;

    IF v_appt_trend > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Appointments Trend:       ' || LPAD(v_appt_trend || '%', 10) || '  Increase');
    ELSIF v_appt_trend < 0 THEN
        DBMS_OUTPUT.PUT_LINE('Appointments Trend:       ' || LPAD(v_appt_trend || '%', 10) || '  Decrease');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Appointments Trend:       ' || LPAD(v_appt_trend || '%', 10) || '  Stable');
    END IF;
    
    IF v_revenue_trend > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Revenue Trend:            ' || LPAD(v_revenue_trend || '%', 10) || '  Increase');
    ELSIF v_revenue_trend < 0 THEN
        DBMS_OUTPUT.PUT_LINE('Revenue Trend:            ' || LPAD(v_revenue_trend || '%', 10) || '  Decrease');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Revenue Trend:            ' || LPAD(v_revenue_trend || '%', 10) || '  Stable');
    END IF;

    -- ========================================
    -- SECTION 6: TOP PERFORMERS
    -- ========================================
    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'SECTION 6: TOP PERFORMERS (Top 5)');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 100, '-'));

    DBMS_OUTPUT.PUT_LINE('Top Providers by Appointments:');
    FOR rec IN (
        SELECT ROWNUM as rank, provider_name, appt_count
        FROM (
            SELECT dp.provider_name, COUNT(*) as appt_count
            FROM fact_appointments fa
            JOIN dim_provider dp ON fa.provider_key = dp.provider_key
            JOIN dim_date dd ON fa.date_key = dd.date_key
            WHERE TO_CHAR(dd.calendar_date, 'YYYY-MM') = p_report_month
              AND dp.current_flag = 'Y'
            GROUP BY dp.provider_name
            ORDER BY COUNT(*) DESC
        )
        WHERE ROWNUM <= 5
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('  ' || rec.rank || '. ' || RPAD(rec.provider_name, 30) || ' - ' || rec.appt_count || ' appointments');
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'Top Specialties by Revenue:');
    FOR rec IN (
        SELECT ROWNUM as rank, specialty_name, total_revenue
        FROM (
            SELECT ds.specialty_name, SUM(fbm.total_bill_amount) as total_revenue
            FROM fact_bills_monthly fbm
            JOIN dim_patient dp ON fbm.patient_key = dp.patient_key
            JOIN fact_appointments fa ON dp.patient_key = fa.patient_key
            JOIN dim_specialty ds ON fa.specialty_key = ds.specialty_key
            WHERE fbm.year_month = p_report_month
            GROUP BY ds.specialty_name
            ORDER BY SUM(fbm.total_bill_amount) DESC
        )
        WHERE ROWNUM <= 5
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('  ' || rec.rank || '. ' || RPAD(rec.specialty_name, 30) || ' - $' || ROUND(rec.total_revenue, 2));
    END LOOP;

    -- ========================================
    -- SECTION 7: DATA QUALITY METRICS
    -- ========================================
    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'SECTION 7: DATA QUALITY & VALIDATION');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 100, '-'));

    DECLARE
        v_orphan_bills NUMBER := 0;
        v_bills_no_diagnosis NUMBER := 0;
        v_active_with_no_appts NUMBER := 0;
    BEGIN
        -- Check for bills without visit reference
        SELECT COUNT(*) INTO v_orphan_bills
        FROM test_bills b
        WHERE b.visit_id IS NULL OR NOT EXISTS (SELECT 1 FROM test_visits v WHERE v.visit_id = b.visit_id);

        -- Check for visits without diagnoses
        SELECT COUNT(*) INTO v_bills_no_diagnosis
        FROM test_visits v
        WHERE NOT EXISTS (SELECT 1 FROM test_visit_diagnoses vd WHERE vd.visit_id = v.visit_id);

        -- Check for active patients with no appointments in last year
        SELECT COUNT(*) INTO v_active_with_no_appts
        FROM test_patients p
        WHERE p.is_active = 'Y'
          AND NOT EXISTS (
              SELECT 1 FROM test_appointments a 
              WHERE a.patient_id = p.patient_id 
                AND a.appointment_date >= TRUNC(SYSDATE) - 365
          );

        DBMS_OUTPUT.PUT_LINE('KPI-010: Data Integrity Issues');
        DBMS_OUTPUT.PUT_LINE('  Orphan Bills (no visit):   ' || LPAD(v_orphan_bills, 10));
        DBMS_OUTPUT.PUT_LINE('  Visits without Diagnosis:  ' || LPAD(v_bills_no_diagnosis, 10));
        DBMS_OUTPUT.PUT_LINE('  Active Patients (no visits/1yr): ' || LPAD(v_active_with_no_appts, 10));
        
        IF v_orphan_bills = 0 AND v_bills_no_diagnosis = 0 THEN
            DBMS_OUTPUT.PUT_LINE('');
            DBMS_OUTPUT.PUT_LINE('  ✓ Data quality is GOOD - No critical issues detected');
        ELSE
            DBMS_OUTPUT.PUT_LINE('');
            DBMS_OUTPUT.PUT_LINE('  ⚠ Data quality ISSUES detected - Review recommended');
        END IF;
    END;

    -- ========================================
    -- FOOTER SECTION
    -- ========================================
    DBMS_OUTPUT.PUT_LINE(CHR(10) || RPAD('=', 100, '='));
    DBMS_OUTPUT.PUT_LINE('Report Notes:');
    DBMS_OUTPUT.PUT_LINE('  - KPI data is computed from OLAP schema for optimal performance');
    DBMS_OUTPUT.PUT_LINE('  - All monetary values are in USD');
    DBMS_OUTPUT.PUT_LINE('  - Percentage rates are calculated to 2 decimal places');
    DBMS_OUTPUT.PUT_LINE('  - Trends show month-over-month changes (0% if no previous data)');
    DBMS_OUTPUT.PUT_LINE('  - Report includes data quality checks for completeness');
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 100, '='));
    DBMS_OUTPUT.PUT_LINE('End of Report: ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS'));

EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Report generation failed with error:');
    DBMS_OUTPUT.PUT_LINE(SQLCODE || ': ' || SQLERRM);
END generate_kpi_report;
/

-- ========================================
-- EXECUTE SAMPLE KPI REPORTS
-- ========================================

SET FEEDBACK ON
SET ECHO ON
SET SERVEROUTPUT ON SIZE UNLIMITED

-- Report for current month, all specialties
BEGIN
    DBMS_OUTPUT.ENABLE(50000);
    generate_kpi_report(TO_CHAR(TRUNC(SYSDATE, 'MM'), 'YYYY-MM'), 'ALL');
END;
/

PROMPT 'KPI Report procedure created and executed'
