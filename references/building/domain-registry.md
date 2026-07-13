# Domain Composition Registry

Domain guidance composes four independent axes:

1. **Project form:** web application, API or service, CLI or SDK, mobile or desktop, data or ML, infrastructure or IaC.
2. **Product archetype:** the product mechanics, such as SaaS, marketplace, developer platform, workflow automation, or internal tool.
3. **Industry overlay:** domain entities, operator expectations, and landmines.
4. **Regulatory overlay:** only evidenced jurisdictions, data classes, and control frameworks. Verify current obligations before committing.

Select form first through `references/building/product-form-router.md`. The registry maps every build-domain profile to one of the 12 stack profiles in `references/planning/domain-stacks.md`. A mapping selects candidate families, not a final stack. Run the current scoring, pairing, and freshness checks before choosing.

## Registry

| ID | Build-domain profile | Taxonomy role | Primary stack profile | Common project form |
|---|---|---|---|---|
| 1 | SaaS / Multi-tenant | Product archetype | SaaS / Multi-tenant | Web application, API or service |
| 2 | E-commerce / Retail | Product archetype and industry | E-commerce / Retail | Web application, mobile or desktop |
| 3 | CMS / Content / Blog | Product archetype | CMS / Content / Blog | Web application |
| 4 | Financial / Fintech / Accounting | Industry overlay | Fintech / Financial | Web application, API or service |
| 5 | Healthcare / Medical | Industry and regulatory overlay | Healthcare / Medical | Web application, mobile or desktop, API or service |
| 6 | Education / EdTech / LMS | Industry overlay | Education / LMS | Web application, mobile or desktop |
| 7 | Travel / Hospitality / Booking | Industry overlay | Marketplace / Two-sided | Web application, mobile or desktop |
| 8 | Sports / Fitness | Industry overlay | SaaS / Multi-tenant | Web application, mobile or desktop |
| 9 | Real Estate / Property Management | Industry overlay | SaaS / Multi-tenant | Web application, mobile or desktop |
| 10 | Logistics / Supply Chain / Fleet | Industry overlay | Internal Tools / Back-office | Web application, mobile or desktop, data or ML |
| 11 | HR / People / Payroll | Industry overlay | SaaS / Multi-tenant | Web application |
| 12 | Project Management / Collaboration | Product archetype | SaaS / Multi-tenant | Web application, mobile or desktop |
| 13 | Customer Support / Helpdesk | Product archetype | Customer Support / Helpdesk | Web application |
| 14 | Marketing / CRM / Sales | Product archetype | CRM / Sales / Marketing | Web application, API or service |
| 15 | IoT / Device Management | Industry overlay | Internal Tools / Back-office | Web application, API or service, infrastructure or IaC |
| 16 | Restaurant / Food Service | Industry overlay | E-commerce / Retail | Web application, mobile or desktop |
| 17 | Legal / Law Firm | Industry overlay | SaaS / Multi-tenant | Web application |
| 18 | Non-profit / Fundraising | Industry overlay | CRM / Sales / Marketing | Web application |
| 19 | Media / Streaming | Industry overlay | CMS / Content / Blog | Web application, mobile or desktop |
| 20 | Agriculture / Farm Management | Industry overlay | Internal Tools / Back-office | Mobile or desktop, data or ML |
| 21 | AI / ML / Chat | Product archetype | AI / ML / LLM products | Web application, API or service, data or ML |
| 22 | Entertainment / Events | Industry overlay | E-commerce / Retail | Web application, mobile or desktop |
| 23 | Gaming / Esports | Industry overlay | SaaS / Multi-tenant | Web application, API or service |
| 24 | Cybersecurity / SOC | Industry overlay | Analytics / BI / Dashboards | Web application, data or ML |
| 25 | Construction / Field Services | Industry overlay | Internal Tools / Back-office | Mobile or desktop, web application |
| 26 | Marketplace / Platform | Product archetype | Marketplace / Two-sided | Web application, mobile or desktop, API or service |
| 27 | Insurance / InsurTech | Industry overlay | Fintech / Financial | Web application, API or service |
| 28 | Telecommunications / ISP | Industry overlay | Internal Tools / Back-office | Web application, API or service, infrastructure or IaC |
| 29 | Energy / Utilities | Industry overlay | Analytics / BI / Dashboards | Web application, data or ML, infrastructure or IaC |
| 30 | Government / Public Sector | Industry and regulatory overlay | Internal Tools / Back-office | Web application, mobile or desktop |
| 31 | Recruiting / ATS | Product archetype and industry | SaaS / Multi-tenant | Web application |
| 32 | Co-working Space / Shared Office | Industry overlay | SaaS / Multi-tenant | Web application, mobile or desktop |
| 33 | Workflow Automation / Integration Platform | Product archetype | SaaS / Multi-tenant | Web application, API or service |
| 34 | Data / Analytics / BI | Product archetype | Analytics / BI / Dashboards | Data or ML, web application |
| 35 | Manufacturing / MES / Industrial Operations | Industry overlay | Internal Tools / Back-office | Web application, mobile or desktop, infrastructure or IaC |
| 36 | Developer Platform / API / SDK | Product archetype | SaaS / Multi-tenant | API or service, CLI or SDK, web application |
| 37 | Research / Lab / LIMS | Industry overlay | Internal Tools / Back-office | Web application, data or ML |

## Composition rules

- A developer platform is a product archetype, not an industry. Add the customer's industry only when the platform itself encodes that industry's rules.
- SaaS and marketplace are product mechanics. They can combine with healthcare, manufacturing, research, or other overlays.
- Analytics / BI may be the product archetype or a secondary capability. Do not force OLAP infrastructure onto a product with only modest operational reporting.
- Research / Lab / LIMS stays a separate industry overlay because sample custody, instrument provenance, and method versioning are stable domain constraints. Clinical research adds healthcare and applicable regulatory overlays.
- Regulatory text is a routing signal, not legal advice. Verify jurisdiction, applicability, effective date, and current vendor capabilities.
- When two stack profiles apply, score the primary profile first, then add only the hard constraints from the secondary profile. Do not average entire matrices.

## Added profile mappings

- Data / Analytics / BI maps directly to stack profile 11.
- Manufacturing / MES starts from Internal Tools / Back-office, then adds Analytics / BI for high-volume historian or quality analytics workloads.
- Developer Platform / API / SDK starts from SaaS / Multi-tenant for control-plane and commercial concerns, while project form supplies API and SDK delivery gates.
- Research / Lab / LIMS starts from Internal Tools / Back-office, then adds Analytics / BI for large instrument datasets and Healthcare only when PHI or clinical workflows are in scope.
