CREATE TABLE test_patients (
    patient_id NUMBER PRIMARY KEY,
    first_name VARCHAR2(100) NOT NULL,
    last_name VARCHAR2(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender CHAR(1) CHECK (gender IN ('M', 'F', 'O')),
    email VARCHAR2(200) UNIQUE NOT NULL,
    phone VARCHAR2(20),
    city VARCHAR2(100),
    is_active CHAR(1) DEFAULT 'Y' CHECK (is_active IN ('Y', 'N'))
);

CREATE TABLE test_appointments (
    appointment_id NUMBER PRIMARY KEY,
    patient_id NUMBER NOT NULL,
    provider_id NUMBER NOT NULL,
    service_id NUMBER NOT NULL,
    appointment_date DATE NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    status VARCHAR2(20) DEFAULT 'SCHEDULED'
        CHECK (status IN ('SCHEDULED','CONFIRMED','CHECKED_IN','COMPLETED','CANCELLED','NO_SHOW')),
    CONSTRAINT fk_appt_patient FOREIGN KEY (patient_id) REFERENCES test_patients(patient_id),
    CONSTRAINT chk_appt_times CHECK (end_time > start_time)
);