# security-tooling-landscape: what each tool catches, misses, and costs

Loaded at Tier 3 (Step 8). The companion to the manual OWASP walkthrough. The verification question for each category is "does the scanner run, run on the right code, and gate the right workflow." Tools are necessary for scale; they are not sufficient for hardening. Every tooling-only finding summary is a scanner-first-security signal; the skill refuses it.

**The load-bearing sentence from Section 4.14 of the research:** even a fully-deployed stack of these tools cannot replace adversarial review by a human who wants to break the app. The tools test what their rules know about; the attacker tests what the rules do not.

## SAST: Static Application Security Testing

**Catches.** Pattern-matched vulnerabilities in source code: SQL injection via dataflow, XSS with taint tracking, hardcoded secrets, insecure crypto primitives, deserialization sinks. Semgrep's dataflow reachability analysis reduces false-positive noise relative to pure pattern-match.

**Misses.** Business-logic bugs (BOLA, BOPLA, workflow abuse), authentication-vs-authorization confusion, any bug where the safe and unsafe versions are syntactically identical (an `authorize()` call that returns `true` too liberally). Races on authorization checks. Runtime-only misconfigurations.

**Options.**

- **Semgrep.** Open-core; free community rules. Dataflow reachability. [Semgrep vs CodeQL head-to-head](https://appsecsanta.com/sast-tools/semgrep-vs-codeql), [Semgrep vs Snyk](https://semgrep.dev/resources/semgrep-vs-snyk/).
- **CodeQL (GitHub).** Free for public repos since 2022; free with GitHub Advanced Security. Higher coverage, higher false positives, heavier setup. [Semgrep vs GHAS](https://semgrep.dev/resources/semgrep-vs-github/).
- **Snyk Code.** Proprietary hybrid-AI model. Pricing tiered; free for small teams, enterprise low-to-mid five figures annually.
- **SonarQube.** Open-core; broadly deployed for code quality with security rules. Weaker pure-security coverage than Semgrep/CodeQL.
- **Checkmarx, Veracode, Fortify (OpenText).** Enterprise SAST. Six-figure annual; deep coverage, heavy integration.
- **DryRun Security.** 2024-2026 AI-first entrant; competitive in recent comparisons [DryRun C# analysis](https://www.dryrun.security/blog/dryrun-security-vs-semgrep-sonarqube-codeql-and-snyk---c-security-analysis-showdown).

**Workflow verification point.** CI on every PR (Semgrep or CodeQL). Nightly deep scan (CodeQL). Release-blocking rule for criticals with explicit justification for overrides. SAST output blocks P0/P1 but does not define hardening-done.

**What to verify in Step 8.**

1. A SAST tool is configured and running (specific tool named).
2. The scan runs on every PR, not only on main.
3. The configuration includes custom rules for project-specific anti-patterns (tenant-scoped finds, forbidden deserialization libraries, LLM-output-as-SQL).
4. Blocking threshold is set (fail CI on Critical/High).
5. Override path exists with named risk owner and expiration date.
6. Tool findings are present in the harden-ready findings report; the scanner's "clean" state does not mean no findings were produced.

## DAST: Dynamic Application Security Testing

**Catches.** Runtime-visible vulnerabilities: reflected XSS, SQLi via error-based or timing probes, missing security headers, verbose error pages, directory listing, CSRF tokens missing, session cookie flags.

**Misses.** Logic bugs requiring multi-step authenticated interaction, IDOR/BOLA with specific object IDs, second-order injection, anything requiring business-model understanding. Unauthenticated DAST is approximately useless on modern SPA/JWT apps; authenticated DAST is required.

**Options.**

- **OWASP ZAP.** OSS, continuously maintained, Docker-first. [OWASP ZAP](https://www.zaproxy.org/).
- **Burp Suite Pro (PortSwigger).** Industry standard for manual web testing. ~$499/year per seat. [PortSwigger Web Security Academy](https://portswigger.net/web-security) is the free curriculum.
- **Acunetix, Invicti (formerly Netsparker), Rapid7 InsightAppSec.** Commercial scanners.
- **StackHawk.** CI-focused DAST; founder is former OWASP ZAP committer.

**Workflow verification point.** Nightly against staging with authenticated session. Pre-launch full scan of production-equivalent. Manual Burp session on every significant UI release.

**What to verify.**

1. DAST configured against staging or a production-equivalent target.
2. Authenticated session configuration in the scan (cookies, JWT, OAuth flow).
3. Scan cadence: monthly minimum; nightly on change-heavy codebases.
4. Scan output triaged; findings ingested into the report.

## SCA: Software Composition Analysis

**Catches.** Known-CVE dependency versions via manifest matching (`package-lock.json`, `requirements.txt`, `Cargo.lock`, `go.sum`). Increasingly: license policy, malicious-package indicators, maintainer-risk flags.

**Misses.** Zero-days in dependencies (xz-utils case). Application-code vulnerabilities. Transitive dependencies present but not declared.

**Options.**

- **Snyk.** Market leader; broad language coverage; SCA + Code + Container + IaC bundled. Free tier generous; enterprise scales.
- **Socket.** Supply-chain-reputation lane leader. Flags install-script behavior, maintainer-takeover signals, newly-published packages with suspicious characteristics. The slopsquatting-detection option. [Socket slopsquatting research](https://socket.dev/blog/slopsquatting-how-ai-hallucinations-are-fueling-a-new-class-of-supply-chain-attacks).
- **Dependabot (GitHub).** Free for public repos, included with GitHub. PR automation; no supply-chain reputation layer.
- **Renovate.** OSS alternative to Dependabot; more configurable.
- **OSV-Scanner (Google).** OSS. [OSV-Scanner](https://google.github.io/osv-scanner/).
- **Chainguard.** Hardened container images plus supply-chain attestation.
- **StackLok Minder.** OSS supply-chain policy engine.

**Workflow verification point.** Merge-blocking check on every PR for CVE policy. Periodic audit for transitive deps. Socket or equivalent for reputation. repo-ready installs this; harden-ready verifies it blocks merges.

**What to verify.**

1. SCA tool named and running in CI.
2. Lockfile is committed; CI uses hash-integrity install (`npm ci`, `pip install --require-hashes`).
3. CVE policy is enforced (threshold, exceptions tracked).
4. Supply-chain reputation is active for new dependencies (Socket or similar).
5. Slopsquatting defense: `pip install` and `npm install` lines are hand-verified against canonical registries for AI-assisted commits.

## IAST: Interactive Application Security Testing

**Catches.** Runtime taint tracking from instrumented app processes. Catches the specific sink-source path in production traffic.

**Misses.** Requires instrumentation; only runs where deployed. Not catch-ahead-of-time.

**Options.** Contrast Security (lane leader), Synopsys Seeker. Enterprise-priced. Adoption concentrated in Java and .NET shops.

**Recommendation.** Optional; Tier 3+ only. Most AI-generated apps do not carry the ops budget for IAST instrumentation. If present, harden-ready verifies IAST findings are in the report.

## Container scanning

**Catches.** Known CVEs in base images and packages; misconfigurations (running as root, exposed ports, image drift from baseline).

**Misses.** Application-level vulnerabilities inside the container. Runtime behavior.

**Options.**

- **Trivy (Aqua).** OSS; broadly adopted; fast. [Trivy](https://github.com/aquasecurity/trivy).
- **Grype (Anchore).** OSS; paired with Syft for SBOM.
- **Docker Scout.** Built-in to Docker Desktop; pulls GHSA and Snyk feeds.
- **Snyk Container, Aqua, Sysdig, Wiz.** Commercial; Wiz and Sysdig extend into runtime.

**Workflow verification.** Scan runs on every image build. Blocks push of images with Critical/High known CVEs unless explicitly approved. Base image update policy (monthly rebuild minimum).

## IaC scanning

**Catches.** Terraform, CloudFormation, Kubernetes YAML misconfigurations: public S3 buckets, overly permissive IAM, missing encryption, insecure defaults.

**Misses.** Drift between IaC and actual cloud state. Runtime reconfigurations not committed back.

**Options.**

- **Checkov (Prisma Cloud / Bridgecrew).** OSS. [Checkov](https://www.checkov.io/).
- **tfsec (Aqua).** OSS, Terraform-focused.
- **KICS (Checkmarx).** OSS; broad IaC coverage.
- **Snyk IaC.** Commercial.
- **CloudSploit, Prowler.** OSS cloud-posture scanners.

**Workflow verification.** IaC scan on every PR that modifies infrastructure. Policy-as-code enforcement (OPA, Sentinel) for high-risk changes. Drift detection between IaC and cloud state (AWS Config, Terraform plan).

## Secret scanning

**Catches.** Hardcoded secrets in source control and commits; high-entropy strings matching known formats (AWS keys, GitHub tokens, Stripe keys).

**Misses.** Secrets in environment files not committed. Secrets in logs. Secrets passed through prompts to LLMs (a 2025-specific concern per research Section 12).

**Options.**

- **GitGuardian.** Lane leader. Pricing tiered.
- **TruffleHog (Trufflesecurity).** OSS plus enterprise; strong historical-commit scanning.
- **git-secrets (AWS Labs).** Lightweight pre-commit hook.
- **GitHub Secret Scanning.** Built-in to GitHub; partner-issuer revocation for matched tokens.

**Workflow verification.** Pre-commit hook, pre-receive hook, periodic full-history scan. Rotation playbook exists for every credential type (named KMS keys, named API keys, known webhook secrets).

**Note on BloodHound.** [BloodHound](https://github.com/BloodHoundAD/BloodHound) is an Active Directory attack-path analysis tool, not a secret scanner. Useful for AD-heavy enterprises; out of scope for most harden-ready workflows.

## SBOM generation

**Catches.** The manifest question: what is in this build. Necessary for Log4Shell-class incident response (see `post-incident-hardening.md`).

**Options.**

- **Syft (Anchore).** OSS, broad ecosystem. Pairs with Grype. [Syft](https://github.com/anchore/syft).
- **CycloneDX.** OWASP project; standard SBOM format plus tools. [CycloneDX](https://cyclonedx.org/).
- **SPDX.** Linux Foundation format; often preferred for compliance.

**Workflow verification.** SBOM generated on every release. Committed or stored alongside the artifact. Queryable ("where is log4j 2.x used") in under 5 minutes.

## Runtime / EDR for applications

**Catches.** Anomalous process behavior, syscall patterns, file-system access deviating from a learned baseline.

**Misses.** Well-crafted attacks that masquerade as legitimate traffic (SUNBURST class).

**Options.**

- **Falco (CNCF).** OSS; rule-based runtime detection for containers and Kubernetes. [Falco](https://falco.org/).
- **Cilium Tetragon (CNCF).** eBPF-based runtime observability with enforcement. [Tetragon](https://tetragon.io/).
- **Datadog Cloud SIEM, Wiz Runtime.** Commercial.

**Workflow verification.** If runtime EDR is in use, rule set is audited (not the default, which alerts on everything and useful on nothing). Rules are triaged with on-call: who responds, in what time.

## WAF / bot / DDoS

**Catches.** L7 volumetric attacks, known exploit patterns (SQLi, XSS), bot traffic, credential stuffing at scale.

**Misses.** Logic bugs, anything requiring application understanding. A WAF is a blunt instrument; tuning is non-trivial.

**Options.**

- **Cloudflare.** WAF + bot + DDoS + DNS. Free tier adequate for startups.
- **Fastly (Signal Sciences acquired 2020).** WAF focus; developer-friendly.
- **AWS WAF.** Inside the AWS account; integrates with ALB, CloudFront, API Gateway.
- **Imperva, Akamai.** Enterprise.

**Workflow verification.** WAF rules tuned for the app (not only default OWASP CRS). Rate-limit rules mirror application-level limits (defense in depth). Bot detection enabled on auth endpoints.

## Pen-testing-as-a-service (PTaaS)

**Catches.** What humans catch that scanners do not: logic bugs, chained exploits, authentication flow flaws.

**Options.**

- **Cobalt.io.** Credit-based (1 credit = 8 testing hours). Starter packages $10K-$20K for focused app scope. Time-to-kickoff as fast as 24 hours. [Cobalt pricing](https://www.cobalt.io/pricing), [Cobalt: PTaaS cost metrics](https://www.cobalt.io/blog/cost-metrics-exploring-pentesting-as-a-service-prices).
- **HackerOne Pentest.** Fixed-fee through HackerOne platform.
- **Synack.** Invitation-only researcher pool.
- **Bugcrowd Next Gen Pen Test.** Researcher-backed.

See `pentest-prep.md` for engagement discipline.

## Bug bounty platforms

- **HackerOne.** Market leader; 1,950 programs, $81M paid in 12 months ending mid-2025.
- **Bugcrowd.** Strong enterprise presence.
- **Intigriti.** European origin, strong EU base.
- **YesWeHack.** French origin, strong EU/FR government.

See `responsible-disclosure.md` for economics and program-design.

## DSPM / CSPM

**Catches.** Misconfigured cloud resources, over-privileged IAM, exposed data stores, identity sprawl.

**Options.** Wiz (market leader, lane-dominant), Orca Security, Lacework, Prisma Cloud, Microsoft Defender for Cloud.

**Pricing.** Enterprise; Wiz has expanded mid-market offerings. Scales with cloud footprint. Not startup-friendly in raw pricing but often worth the investment at Series B.

## What the whole tooling stack still misses

Even a fully-deployed stack cannot replace:

- **Adversarial review by a human who wants to break the app.** No tool matches an experienced pen tester with two hours and Burp Suite.
- **Threat-model-driven hypothesis testing.** A tool tests only what its rules know about.
- **Business-logic bugs that look correct in isolation.** "Buy product A for $100; change shipping address to yours after order placement" does not match any CWE pattern.
- **Paper-trust-boundary violations.** The tool sees the code; it cannot know the design intent.

This is the scanner-first-security refusal point. Tools are necessary-not-sufficient.

## Verification checklist for Step 8

Ship a table in the findings report:

| Category | Tool in use | Running in CI/on schedule? | Gating threshold set? | Findings acknowledged in report? |
|---|---|---|---|---|
| SAST | Semgrep | Every PR | Critical/High block | Yes, 2 findings F-08, F-09 |
| DAST | ZAP | Weekly against staging | Critical block | Yes, 0 findings |
| SCA | Snyk + Socket | Every PR | Critical block; Socket flag = review | Yes, 1 finding F-10 (supply-chain reputation flag) |
| IAST | N/A | N/A | N/A | N/A |
| Container | Trivy | Every image build | Critical/High block | Yes, 0 findings |
| IaC | Checkov | Every infrastructure PR | High block | Yes, 0 findings |
| Secret scanning | GitGuardian + git-secrets pre-commit | Pre-commit + pre-receive + weekly full-history | Block on any hit | Yes, 0 findings |
| SBOM | Syft | Every release | N/A | SBOM committed in release artifacts |
| Runtime EDR | Falco | Always-on | Alert on anomaly | Rules tuned, owner named |
| WAF | Cloudflare | Always-on | OWASP CRS + custom rules | Rules reviewed 2026-03 |
| DSPM | N/A for now | N/A | N/A | Revisit at Series A |
| Pen-test | Scheduled Cobalt engagement 2026-06-15 | N/A | Retest mandatory | Engagement scope in .harden-ready/pentest/ |
| Bug bounty | VDP only (no bounty) | Intake via security@ | Triage SLA 72h | See responsible-disclosure.md |

Every "Yes" means tool findings are in the same findings report as the manual findings, not siloed in the scanner dashboard where nobody looks at them.

## The anti-pattern checklist

Refuse the pass if any of these appear:

- **"We ran Semgrep. Zero criticals."** Without manual OWASP walkthrough.
- **"Snyk dashboard is clean."** Without confirming Snyk scan runs on every PR and blocks merge.
- **"DAST scan is set up."** Without verifying it runs authenticated.
- **"Secret scanning is enabled."** Without pre-commit + pre-receive + historical.
- **"We have a WAF."** Without verifying rules are tuned beyond defaults.
- **"Cobalt will find everything."** Without retest discipline (see pentest-prep.md).

Each is a scanner-first-security signature. Tools report absence of findings; that is not evidence of security.
