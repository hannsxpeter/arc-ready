# dependency-graph.md

Step 3 (upstream ingestion) and Step 4 (sequencing) material. This file covers how to read an architecture dependency graph, perform topological sort for roadmap sequencing, match parallelism to team capacity, and run the Amdahl's law check.

## 1. Reading the architecture DAG

`architecture-ready` produces a dependency graph as part of its component breakdown. The canonical locations:

- `.architecture-ready/ARCH.md` section "Component breakdown": table of components with a "Dependencies" column per row.
- `.architecture-ready/ARCH.md` section "Integration architecture": integration edges between components and external systems.
- `.architecture-ready/HANDOFF.md` section "Component dependency graph" or "To roadmap-ready": often a Mermaid or ASCII DAG representation.

Extract the graph as a set of edges. Each edge is "A depends on B" meaning B must be stable (interface contract frozen) before A can be completed.

**Example (echo-service example).**

From `architecture-ready/dogfood/ARCH.md`:

```
echo-service component
  -> Fly platform (inherited, platform dependency)
  -> Honeycomb (external; async, degradable)
```

The DAG has one internal node (echo-service) and two external dependencies. Topological sort is trivial: echo-service can be built without waiting for anything the team controls.

**Example (nontrivial B2B SaaS).**

Suppose architecture-ready produced:

```
api-server -> postgres
api-server -> redis
webapp -> api-server
billing-worker -> postgres
billing-worker -> stripe (external)
notification-worker -> redis
notification-worker -> sendgrid (external)
admin-dashboard -> api-server
```

Topological sort (one valid order): postgres, redis, api-server, webapp, billing-worker, notification-worker, admin-dashboard. The stripe and sendgrid external dependencies sit outside the team's control.

The roadmap slices that build each component must respect this order. A slice building admin-dashboard cannot be scheduled before slices that build api-server.

## 2. Topological sort procedure

Given a DAG with edges as above:

1. Start with all nodes with no incoming edges (no dependencies).
2. Remove one such node from the graph; add it to the sorted output.
3. Repeat until the graph is empty. If the graph is non-empty and no nodes have zero incoming edges, there is a cycle; abort.

**Cycle detection implication.** If the architecture has a cycle, the roadmap cannot be coherently sequenced. Route back to architecture-ready: cycles are architecture problems, not roadmap problems.

**Multiple valid orders.** A DAG often admits multiple topological sorts (postgres could come before or after redis in the example above; neither depends on the other). Layer 2 (risk-driven) and layer 4 (capacity) break ties among valid orders.

## 3. Slice-level vs. component-level dependencies

Architecture-level DAG gives component dependencies. Slices within a component have their own ordering:

- **Interface-first.** Build the interface (API endpoints, database schema, event contracts) before the interior. Once the interface is stable, other components can begin against a stubbed implementation.
- **Happy-path first, error paths second.** The smallest working thing first; error handling and edge cases layered on.
- **Observability from day one.** OTel span emission on the first request handler, not bolted on after. Feeds observe-ready.

Slice-level ordering within a component is primarily a production-ready concern; the roadmap emits slices ordered at the slice level and production-ready decomposes further as needed.

## 4. Capacity matching

The roadmap's parallelism (concurrent tracks in a period) must not exceed the team-capacity input. This is the fictional-parallelism guard.

**Definitions.**

- **Team size.** Number of engineers available for roadmap work. Does NOT include on-call capacity, support rotation, or other non-roadmap time.
- **Engineer-weeks per cycle.** Team size * cycle length in weeks * utilization factor. Utilization is typically 0.7-0.8: engineers have meetings, reviews, context-switching, and 1-2 days of lost time per week.
- **Gross capacity.** Team size * cycle length, unadjusted.
- **Net capacity.** Gross capacity * utilization factor * (1 - serial-fraction allowance).

**Worked example.** Team of 4 engineers; Shape Up 6-week cycle.

- Gross: 4 * 6 = 24 engineer-weeks.
- Utilization: 0.75 (reasonable for a well-functioning team with normal meeting load).
- Net before Amdahl: 24 * 0.75 = 18 engineer-weeks.
- Serial fraction allowance: 0.15 (reviews, coordination, shared-service dependencies; see 5 below).
- Net after Amdahl: 18 * (1 - 0.15) = 15.3 engineer-weeks.

So this team's honest capacity per 6-week cycle is ~15 engineer-weeks. A plan that schedules 20 engineer-weeks of work is over by 33%.

**Big batch vs. small batch.**

- Big batch (6 weeks): 2-3 engineers working on one concerted effort. Accounts for ~12-18 engineer-weeks.
- Small batch (2 weeks): 1-2 engineers on a smaller effort. Accounts for ~2-4 engineer-weeks.

A 4-engineer team per 6-week cycle can run one big batch OR two small batches concurrently OR one big batch + one small batch if the big is 2-engineer not 3-engineer. The skill refuses plans that exceed this simple math.

## 5. Amdahl's law sanity check

Gene Amdahl, 1967. Speedup from parallelization is capped by the serial fraction:

```
Speedup = 1 / (s + p/N)

where:
  s = serial fraction of the work (cannot be parallelized)
  p = parallelizable fraction (p = 1 - s)
  N = number of parallel workers
```

Worked examples for a team of 10 engineers:

- If s = 0.10 (10% serial): max speedup = 1 / (0.10 + 0.90/10) = 1 / 0.19 = 5.26x.
- If s = 0.20 (20% serial): max speedup = 1 / (0.20 + 0.80/10) = 1 / 0.28 = 3.57x.
- If s = 0.50 (50% serial): max speedup = 1 / (0.50 + 0.50/10) = 1 / 0.55 = 1.82x.

**Applied to roadmap planning.** A team with a 20% serial fraction (common: code reviews, integration testing, cross-team dependency resolution, shared-service bottlenecks) gets at most 3.57x throughput from 10 engineers compared to 1 engineer. Doubling from 5 to 10 engineers does not double throughput; it increases from ~2.78x to ~3.57x.

**Practical implication.** Planning work "proportional to headcount" ignores Amdahl. A team that doubles from 5 to 10 engineers and plans to double throughput will miss the plan by ~22%. The skill reserves an Amdahl allowance in capacity calculation; teams with high coordination overhead reserve more (serial fraction 0.25-0.35); teams with extraordinarily independent work reserve less (0.10-0.15).

**Sources of serial fraction.**

- Code review and approval (1-2 reviewers per PR; time-sliced).
- Integration testing (serial before merge or deploy).
- Cross-team coordination (shared-service API changes, cross-repo refactors).
- Release coordination (deploy sequences, feature-flag rollouts).
- Dependency waits (external API rate limits, vendor approval processes).
- Meetings (standups, planning, retros, 1:1s).

A team's honest serial fraction is knowable from past cycles: what percent of engineer-hours went to coordination vs. individual contribution? If the team has not measured, default to 0.20 (a conservative middle estimate) and re-calibrate after two cycles.

## 6. Parallelism vs. dependency in sequencing

These interact. Even when the architecture DAG allows two components to be built in parallel, team capacity may mean they cannot be. The skill flags this explicitly:

- **Architecturally parallel, capacity-serial.** Components A and B have no architectural dependency, but the team has only one engineer who knows the domain; the work is effectively serial. Flag this as "capacity-serial" in the sequencing note.
- **Architecturally serial, capacity-parallel (rare).** The DAG says A depends on B, but the interface between A and B is stable enough that work on A can begin against a stubbed B. This is the "interface-first" pattern; slices of A and B can run in parallel after the interface slice lands.

Most real teams discover that their architectural parallelism exceeds their capacity parallelism. The skill's job is to surface this before engineering discovers it in a failed cycle.

## 7. Shared-service bottlenecks (invisible parallelism)

A common failure pattern. The roadmap draws N parallel tracks; each track has a dependency on a single shared service (auth, a central database, an SRE team, a legal review). The tracks appear parallel on the diagram; in practice they serialize at the bottleneck.

**Grep for the bottleneck.** For each period, list the items and their named dependencies. If three or more items share a dependency that is not already topologically resolved in the prior period, the parallelism is invisible.

**Fix.**

- Land the bottleneck work first, in a prior period (the "interface-first" approach).
- Reduce concurrent tracks to what the bottleneck can actually serve.
- Parallelize the bottleneck itself (bring more capacity to the shared service).

## 8. Amdahl's law illustrated for roadmap planning

An intuition pump. Suppose a team of 4 has this work in a 6-week cycle:

- Slice A: 6 engineer-weeks, no dependencies.
- Slice B: 6 engineer-weeks, depends on Slice A's interface (stable after week 2).
- Slice C: 4 engineer-weeks, depends on Slice B.
- Slice D: 2 engineer-weeks, no dependencies.

If the team could perfectly parallelize:

- Week 1-2: A (2 engineers) + D (1 engineer). A finishes week 2 with interface stable.
- Week 2-4: A continuing (2 engineers) + B starts against interface (1 engineer). A finishes week 3.
- Week 3-5: B (2 engineers) + prep C.
- Week 5-6: C (2 engineers).

Total engineer-weeks used: 6 + 6 + 4 + 2 = 18. With 4 engineers * 6 weeks = 24 gross capacity, this fits on paper.

In practice: A's "interface stable" is not a clean week-2 event; B's prep takes coordination; reviews add serial delay; C is waiting. A realistic schedule with serial-fraction 0.20 allows ~19.2 engineer-weeks of net work in 24 gross. The cycle is tight. Flag this.

## 9. Worked example: echo-service example dependency graph

From the architecture-ready dogfood:

- **echo-service** (single component): accepts POST /echo, validates JSON, emits span, returns response.
- Dependencies: Fly platform (inherited), Honeycomb (external, async).

Topological sort: trivial (one node). Parallelism: not applicable (solo-dogfood; capacity = 1 engineer).

Load-bearing-first slice order within the component (from architecture-ready HANDOFF to roadmap):

1. Base HTTP server plus `/healthz` (deploy-ready and observe-ready both need this first).
2. `/echo` with JSON validation (PRD R-01).
3. OTel instrumentation and Honeycomb export (PRD R-02).

Note: 1 and 2 could run concurrently on a bigger team. On a solo team, they serialize. The roadmap's Now column reflects the serial order.

## 10. Summary

The roadmap's sequencing obeys architecture. The roadmap's parallelism obeys capacity. Neither is negotiable. When they conflict, capacity wins (you cannot schedule work engineers do not have); when they do not conflict, the DAG dictates the order.
