# 5. Healthcare / Medical

This profile is a mechanical extraction from the original domain catalog. Its inherited domain guidance is preserved.

**Archetype:** Clinical or admin staff managing patients, encounters, diagnoses, prescriptions, and claims.

**Core entities:** Patient, Provider, Encounter/Visit, Diagnosis (ICD code), Procedure (CPT code), Medication/Prescription, Insurance Claim, Care Plan

**Gotchas:**
- **HIPAA is not optional and it's not just encryption** — it requires access controls, audit logging of every PHI access (who viewed what patient record when), minimum necessary access, Business Associate Agreements with every vendor, breach notification procedures, and regular risk assessments. Violations cost $50K-$1.8M per incident.
- **Patient identity matching is an unsolved hard problem** — patients lack universal IDs. Name + DOB matching creates duplicates, and merging duplicates is a complex workflow (which record's allergies win?).
- **Clinical data uses standardized code systems** — ICD-10 for diagnoses (~70,000 codes), CPT for procedures, LOINC for labs, RxNorm for medications. Free-text fields are not acceptable for these.
- **Interoperability standards are mandated** — HL7 FHIR is required for certified EHR systems. You will need to both consume and produce FHIR resources.
- **Consent management is granular and revocable** — a patient may consent to treatment but not to sharing data with a specific insurer. This is not a simple boolean.
- **Drug interactions and allergy checking are safety-critical** — prescribing workflows must check drug-drug interactions and contraindications. Getting this wrong can kill someone.

**Compliance:** HIPAA, HITECH Act, 21st Century Cures Act (information blocking), GDPR (EU health data is "special category"), FDA for clinical software, state-specific consent laws.

**UX users expect:** Problem/medication/allergy list always visible, clinical note templates (SOAP format), encounter timeline, medication reconciliation workflow, e-prescribing integration, patient portal with role-restricted views.

**Seed data shape:** 50 patients (diverse demographics, 3 with no encounters, 1 with revoked consent for a specific provider). 15 providers across 3 departments. 200 encounters spanning 6 months with ICD-10 and CPT codes. 10 active prescriptions with 2 known drug interactions seeded. 5 insurance claims (3 approved, 1 denied, 1 pending). Audit log with 500+ PHI access entries. 1 patient with a merged duplicate record.
