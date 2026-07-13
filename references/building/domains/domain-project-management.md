# 12. Project Management / Collaboration

This profile is a mechanical extraction from the original domain catalog. Its inherited domain guidance is preserved.

**Archetype:** Teams managing tasks, sprints, timelines, and resource allocation.

**Core entities:** Project, Task/Issue, Sprint/Iteration, Board/View, Milestone, Time Entry, Comment/Activity, Workflow Status

**Gotchas:**
- **Task dependencies create scheduling constraints** — finish-to-start, start-to-start, with lag/lead times. Changing one task's dates must cascade through the dependency graph (critical path). Circular dependencies must be detected.
- **Custom workflows per team are expected** — one team uses Kanban (3 statuses), another uses a 7-status workflow with approval gates and transition rules ("only QA can move to Done").
- **Time tracking has billing implications** — entries may be billable/non-billable, associated with a client, subject to approval. Rounding rules and overtime add complexity.
- **Permissions are project-scoped, not global** — admin on Project A, member on Project B, viewer on Project C. Guest/external collaborator access with limited visibility is common.
- **Activity feeds must be real-time** — every field change generates an event. Users expect WebSocket-driven updates. The activity log is also the audit trail.
- **Reporting requires cross-project aggregation** — portfolio health, resource utilization, burn-down charts, velocity. These are expensive queries needing materialized views.

**Compliance:** SOC 2 for enterprise, GDPR (right to deletion conflicts with audit trails).

**UX users expect:** Kanban board with drag-and-drop, Gantt chart with dependency arrows, sprint backlog with story points, inline time tracking, @-mentions with notifications, customizable views (list/board/calendar/timeline).

**Seed data shape:** 3 projects (1 active sprint, 1 planning, 1 completed). 60 tasks across all statuses with 10 dependency relationships (no circular). 2 custom workflows (3-status Kanban, 5-status with approvals). 8 team members with varied project-level roles. 100 time entries (70 billable, 30 non-billable). 200 activity feed events. 1 overdue milestone. Story point estimates on 80% of tasks. 5 tasks with file attachments.
