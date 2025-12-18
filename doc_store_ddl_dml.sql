-- ========================================
-- Healthcare Appointments System - Document Store (JSON)
-- Oracle 19c JSON Support
-- ========================================

-- ========================================
-- DROP EXISTING OBJECTS
-- ========================================

BEGIN
    FOR rec IN (SELECT table_name FROM user_tables 
                WHERE table_name IN ('test_visit_documents', 'test_doc_schema_registry')
                ORDER BY table_name DESC) LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || rec.table_name || ' CASCADE CONSTRAINTS';
    END LOOP;
END;
/

-- ========================================
-- SCHEMA REGISTRY: Track document versions and schemas
-- ========================================

CREATE TABLE test_doc_schema_registry (
    schema_id NUMBER PRIMARY KEY,
    schema_version VARCHAR2(10),
    schema_name VARCHAR2(100),
    created_date DATE DEFAULT SYSDATE,
    description VARCHAR2(500),
    is_active CHAR(1) DEFAULT 'Y'
);

INSERT INTO test_doc_schema_registry VALUES (1, '1.0', 'VisitDocument', SYSDATE, 
    'Complete medical visit with nested assessments, services, and procedures', 'Y');
INSERT INTO test_doc_schema_registry VALUES (2, '1.1', 'VisitDocumentExtended', SYSDATE, 
    'Enhanced visit document with treatment outcomes and follow-up tracking', 'Y');

COMMIT;

-- ========================================
-- DOCUMENT STORAGE: Visit Documents (JSON)
-- ========================================

CREATE TABLE test_visit_documents (
    document_id NUMBER PRIMARY KEY,
    visit_id NUMBER NOT NULL UNIQUE,
    patient_id NUMBER NOT NULL,
    provider_id NUMBER NOT NULL,
    document_version VARCHAR2(10),
    visit_document CLOB NOT NULL CONSTRAINT chk_visit_json CHECK (visit_document IS JSON),
    document_checksum VARCHAR2(32),
    created_date DATE DEFAULT SYSDATE,
    modified_date DATE DEFAULT SYSDATE,
    is_active CHAR(1) DEFAULT 'Y',
    CONSTRAINT fk_visdoc_visit FOREIGN KEY (visit_id) REFERENCES test_visits(visit_id),
    CONSTRAINT fk_visdoc_patient FOREIGN KEY (patient_id) REFERENCES test_patients(patient_id),
    CONSTRAINT fk_visdoc_provider FOREIGN KEY (provider_id) REFERENCES test_providers(provider_id)
);

CREATE INDEX idx_visdoc_visit ON test_visit_documents(visit_id);
CREATE INDEX idx_visdoc_patient ON test_visit_documents(patient_id);
CREATE INDEX idx_visdoc_provider ON test_visit_documents(provider_id);
CREATE INDEX idx_visdoc_date ON test_visit_documents(created_date);

-- JSON column index for query optimization
CREATE INDEX idx_visdoc_status ON test_visit_documents(
    JSON_VALUE(visit_document, '$.visitStatus')
);

-- ========================================
-- SAMPLE JSON DOCUMENTS: Visit Type 1 (Standard Visit)
-- ========================================

INSERT INTO test_visit_documents (document_id, visit_id, patient_id, provider_id, document_version, visit_document)
VALUES (1, 6000, 1000, 2000, '1.0', TO_CLOB('{
  "documentMetadata": {
    "documentId": "VDC-001",
    "version": "1.0",
    "documentType": "MedicalVisit",
    "createdTimestamp": "2025-11-17T09:00:00Z",
    "lastModified": "2025-11-17T09:25:00Z"
  },
  "visitHeader": {
    "visitId": 6000,
    "visitDate": "2025-11-17",
    "visitType": "ROUTINE_CHECKUP",
    "visitStatus": "COMPLETED",
    "duration": {
      "checkInTime": "09:00:00",
      "checkOutTime": "09:25:00",
      "durationMinutes": 25
    }
  },
  "patientInfo": {
    "patientId": 1000,
    "name": "John Smith",
    "dateOfBirth": "1965-03-15",
    "gender": "M",
    "age": 60,
    "insurancePrimary": "BHP-001"
  },
  "providerInfo": {
    "providerId": 2000,
    "name": "Sarah Mitchell",
    "specialty": "Cardiology",
    "licenseNumber": "LIC-001",
    "department": "Cardiology"
  },
  "clinicalAssessment": {
    "chiefComplaint": "Regular checkup",
    "vitalSigns": {
      "bloodPressure": "120/80",
      "heartRate": 72,
      "temperature": 98.6,
      "respiratoryRate": 16,
      "bmi": 24.5
    },
    "historyOfPresentIllness": "Patient reports feeling well. No new complaints.",
    "pastMedicalHistory": [
      {
        "condition": "Hypertension",
        "diagnosed": "2010-05-15",
        "status": "CONTROLLED",
        "medications": ["Lisinopril 10mg daily"]
      }
    ],
    "medications": [
      {
        "medicationName": "Lisinopril",
        "dose": "10mg",
        "frequency": "daily",
        "purpose": "Blood pressure control",
        "adherence": "GOOD"
      }
    ]
  },
  "assessmentAndPlan": {
    "assessment": "Patient is in good health. Vital signs normal. No acute concerns.",
    "diagnosisPrimary": {
      "icd10Code": "Z00.00",
      "description": "Encounter for general adult medical exam"
    },
    "treatmentPlan": "Continue current medications. Maintain healthy lifestyle.",
    "procedures": [
      {
        "procedureCode": "99213",
        "procedureName": "Office visit - established patient",
        "status": "COMPLETED",
        "result": "NORMAL"
      }
    ]
  },
  "services": [
    {
      "serviceId": 4000,
      "serviceName": "Routine Checkup",
      "quantity": 1,
      "unitPrice": 150.00,
      "discount": 10,
      "totalPrice": 135.00,
      "status": "COMPLETED"
    }
  ],
  "followUp": {
    "followUpRequired": true,
    "followUpDays": 365,
    "followUpType": "ANNUAL",
    "followUpInstructions": "Schedule annual checkup in one year. Continue current medications."
  },
  "documentNotes": {
    "clinicalNotes": "Patient education provided on cardiovascular health.",
    "internalNotes": "Patient compliance excellent.",
    "referrals": []
  },
  "statusHistory": [
    {
      "status": "IN_PROGRESS",
      "timestamp": "2025-11-17T09:00:00Z",
      "changedBy": "ADMIN"
    },
    {
      "status": "COMPLETED",
      "timestamp": "2025-11-17T09:25:00Z",
      "changedBy": "sarah.mitchell@hospital.com"
    }
  ]
}'));

COMMIT;

-- ========================================
-- DOCUMENT QUERIES
-- ========================================

-- ========================================
-- Query 1: Find all completed visits (filter by document attribute)
-- ========================================

CREATE OR REPLACE VIEW v_completed_visits AS
SELECT 
    d.document_id,
    d.visit_id,
    d.patient_id,
    JSON_VALUE(d.visit_document, '$.visitHeader.visitDate') as visit_date,
    JSON_VALUE(d.visit_document, '$.patientInfo.name') as patient_name,
    JSON_VALUE(d.visit_document, '$.providerInfo.name') as provider_name,
    JSON_VALUE(d.visit_document, '$.assessmentAndPlan.assessment') as assessment
FROM test_visit_documents d
WHERE JSON_VALUE(d.visit_document, '$.visitHeader.visitStatus') = 'COMPLETED';

-- ========================================
-- Query 2: Extract services from visit documents (nested array extraction)
-- ========================================

CREATE OR REPLACE VIEW v_visit_services_from_doc AS
SELECT 
    d.document_id,
    d.visit_id,
    JSON_VALUE(d.visit_document, '$.patientInfo.name') as patient_name,
    sv.SERVICE_NAME,
    sv.SERVICE_QUANTITY,
    sv.SERVICE_PRICE,
    sv.DISCOUNT,
    sv.TOTAL_PRICE,
    sv.STATUS
FROM test_visit_documents d,
     JSON_TABLE(d.visit_document, '$.services[*]'
        COLUMNS (
            SERVICE_NAME VARCHAR2(200) PATH '$.serviceName',
            SERVICE_QUANTITY NUMBER PATH '$.quantity',
            SERVICE_PRICE NUMBER PATH '$.unitPrice',
            DISCOUNT NUMBER PATH '$.discount',
            TOTAL_PRICE NUMBER PATH '$.totalPrice',
            STATUS VARCHAR2(20) PATH '$.status'
        )
     ) sv
WHERE JSON_EXISTS(d.visit_document, '$.services');

-- ========================================
-- Query 3: Find visits by patient name (document search)
-- ========================================

CREATE OR REPLACE VIEW v_visits_by_patient_name AS
SELECT 
    d.document_id,
    d.visit_id,
    JSON_VALUE(d.visit_document, '$.patientInfo.name') as patient_name,
    JSON_VALUE(d.visit_document, '$.providerInfo.name') as provider_name,
    JSON_VALUE(d.visit_document, '$.clinicalAssessment.chiefComplaint') as chief_complaint,
    JSON_VALUE(d.visit_document, '$.visitHeader.visitDate') as visit_date
FROM test_visit_documents d
WHERE JSON_VALUE(d.visit_document, '$.visitHeader.visitStatus') IN ('COMPLETED', 'IN_PROGRESS');

-- ========================================
-- Query 4: Join document data with relational OLTP data
-- ========================================

CREATE OR REPLACE VIEW v_visit_doc_with_bills AS
SELECT 
    d.visit_id,
    JSON_VALUE(d.visit_document, '$.patientInfo.name') as patient_name,
    JSON_VALUE(d.visit_document, '$.visitHeader.visitDate') as visit_date,
    JSON_VALUE(d.visit_document, '$.assessmentAndPlan.assessment') as assessment,
    b.bill_id,
    b.total_amount,
    b.bill_status,
    b.patient_responsibility
FROM test_visit_documents d
LEFT JOIN test_bills b ON d.visit_id = b.visit_id;

-- ========================================
-- Query 5: Extract patient vital signs from document (nested object)
-- ========================================

CREATE OR REPLACE VIEW v_patient_vital_signs AS
SELECT 
    d.visit_id,
    JSON_VALUE(d.visit_document, '$.patientInfo.name') as patient_name,
    JSON_VALUE(d.visit_document, '$.visitHeader.visitDate') as visit_date,
    JSON_VALUE(d.visit_document, '$.clinicalAssessment.vitalSigns.bloodPressure') as blood_pressure,
    JSON_VALUE(d.visit_document, '$.clinicalAssessment.vitalSigns.heartRate') as heart_rate,
    JSON_VALUE(d.visit_document, '$.clinicalAssessment.vitalSigns.temperature') as temperature,
    JSON_VALUE(d.visit_document, '$.clinicalAssessment.vitalSigns.bmi') as bmi
FROM test_visit_documents d;

-- ========================================
-- Query 6: Extract medications from document (array)
-- ========================================

CREATE OR REPLACE VIEW v_visit_medications AS
SELECT 
    d.visit_id,
    JSON_VALUE(d.visit_document, '$.patientInfo.name') as patient_name,
    m.MEDICATION_NAME,
    m.DOSE,
    m.FREQUENCY,
    m.PURPOSE,
    m.ADHERENCE
FROM test_visit_documents d,
     JSON_TABLE(d.visit_document, '$.clinicalAssessment.medications[*]'
        COLUMNS (
            MEDICATION_NAME VARCHAR2(100) PATH '$.medicationName',
            DOSE VARCHAR2(50) PATH '$.dose',
            FREQUENCY VARCHAR2(50) PATH '$.frequency',
            PURPOSE VARCHAR2(200) PATH '$.purpose',
            ADHERENCE VARCHAR2(20) PATH '$.adherence'
        )
     ) m;

PROMPT 'Document Store (JSON) created successfully'
PROMPT 'Created:'
PROMPT '  - test_visit_documents table with JSON validation'
PROMPT '  - 1 sample visit document'
PROMPT '  - 6 views for document queries and joins with OLTP data'
