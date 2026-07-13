# 6. Education / EdTech / LMS

This profile is a mechanical extraction from the original domain catalog. Its inherited domain guidance is preserved.

**Archetype:** Instructors and admins managing courses, enrollments, grades, and student progress.

**Core entities:** Course, Module/Lesson, Assignment/Assessment, Enrollment, Grade/Score, Student, Instructor, Certificate

**Gotchas:**
- **Grading is not just a percentage** — letter grades, pass/fail, weighted categories (homework 30%, exams 40%), curved grades, dropped lowest scores, incomplete grades, grade overrides. The gradebook is a computation engine.
- **Academic calendar structures everything** — semesters, terms, registration periods, add/drop deadlines, grade submission deadlines create temporal boundaries that affect what actions are available when.
- **Student data has specific protections** — FERPA restricts who can see student records. Parents of minors have rights; parents of adults (18+) do not unless the student grants access.
- **Content sequencing and prerequisites are a DAG** — "complete Module 3 before Module 4" and "pass Course 101 before enrolling in 201" create dependency graphs enforced at enrollment and content access time.
- **Assessment integrity is a feature** — proctoring, time limits, randomized question pools, plagiarism detection, and lockdown browser integration are expected.
- **Accessibility is legally mandated** — ADA/Section 508 compliance is required for educational institutions. All content must work with screen readers, video must have captions.

**Compliance:** FERPA (US student records), COPPA (under-13), GDPR (EU students), ADA/Section 508 accessibility, state-specific K-12 data privacy laws.

**UX users expect:** Gradebook grid (students x assignments), progress tracker (completion %), assignment submission workflow with rubric, discussion forum threading, attendance tracker, certificate builder, student/parent/teacher portal views.

**Seed data shape:** 5 courses (2 active, 1 completed, 1 upcoming, 1 archived). 30 students and 4 instructors. 60 enrollments across courses. 8 assignments per active course with weighted grading categories. Grades for 80% of student-assignment pairs (leave some unsubmitted). 1 student with an "incomplete" grade. Prerequisites between 2 courses. 3 modules per course with sequential unlock. 1 certificate template with 5 issued certificates.
