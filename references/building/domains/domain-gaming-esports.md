# 23. Gaming / Esports

This profile is a mechanical extraction from the original domain catalog. Its inherited domain guidance is preserved.

**Archetype:** Game studio or platform managing players, matches, virtual economies, seasons, and competitive integrity.

**Core entities:** Player/Account, Match/Game Session, Leaderboard/Ranking, Virtual Item/Currency, Season/Battle Pass, Tournament/Bracket, Ban/Sanction, Achievement

**Gotchas:**
- **Virtual economies require fintech-level rigor** — in-game currency (earned and purchased), item trading, marketplace transactions. Use integer math for all currency. Duplication exploits (creating currency/items from nothing) are the #1 game-breaking bug. Transaction logs must be append-only and auditable.
- **Matchmaking is a real-time system with fairness constraints** — skill-based rating (Elo, Glicko-2, TrueSkill), queue times vs. match quality trade-offs, party/group matching, regional latency requirements, and smurf detection (high-skill players on new accounts).
- **Leaderboards at scale need specialized data structures** — sorted sets (Redis ZSET) or materialized views, not `ORDER BY score DESC LIMIT 100` on every page load. Real-time vs. periodic refresh. Per-region, per-season, per-mode leaderboards multiply the problem.
- **Season/battle pass progression is a time-bound engagement system** — XP accumulation, tier rewards, premium vs. free track, catch-up mechanics for late joiners, end-of-season reward distribution. Resetting and archiving season data while preserving rewards is a migration event.
- **Anti-cheat and ban management is an ongoing war** — detection signals (impossible stats, speed hacks, aimbot patterns), ban types (temporary, permanent, shadow ban, hardware ban), appeal workflows, and ban evasion detection (same hardware/IP with new account).
- **Loot box / gacha compliance varies by country** — Belgium and Netherlands ban paid loot boxes, Japan regulates "kompu gacha," China requires published drop rates, Apple/Google require disclosure. The same game may need different monetization per region.
- **Player data for minors triggers COPPA/GDPR-K** — under-13 accounts need parental consent, restricted chat, restricted spending, no behavioral advertising. Age gating must be real, not a "click yes" checkbox.
- **Real-time multiplayer state is not a database concern** — match state lives in game servers, not in PostgreSQL. The dashboard reads from match result records, player stats aggregations, and event streams. Don't try to query live match state from the admin panel.
- **Cross-platform account linking is an identity architecture problem** — a player has one identity but accounts on Steam, PSN, Xbox, Nintendo, Epic. Platform policies restrict data sharing (Sony historically blocked cross-progression). Purchased items may be platform-locked. Linking must be reversible. Data model: `Player` has many `PlatformLink` records.
- **Live service content pipeline has external blocking dependencies** — seasonal content goes through platform certification (Sony, Microsoft, Nintendo each certify separately, 1-5 business days, may reject). The dashboard needs: release calendar with certification status per platform, rollback capability, feature flags for gradual rollout.
- **Player behavioral analytics drive LiveOps** — churn risk scoring, engagement segments (whale/dolphin/minnow), content exhaustion detection, social graph health. This isn't just analytics — it drives automated interventions (re-engagement offers when churn probability exceeds threshold).
- **Guild/clan management is a social governance system** — creation, invitations, roles (leader/officer/member), shared resources/bank, guild progression, inter-guild competition, moderation, dissolution and asset distribution.

**Compliance:** COPPA (minors), GDPR (player data, right to deletion of accounts), loot box regulations (Belgium, Netherlands, Japan, China), ESRB/PEGI rating compliance, gambling regulations (if real-money is involved), platform ToS (Steam, PlayStation, Xbox, App Store policies).

**UX users expect:** Player lookup with match history, ban/moderation queue with evidence viewer, leaderboard browser by season/region/mode, virtual economy dashboard (currency in circulation, inflation metrics), tournament bracket editor, season pass progression analytics, report/appeal workflow, real-time concurrent player counts.

**Seed data shape:** 500 player accounts (400 active, 50 inactive, 30 banned — 5 permanent, 25 temporary). 2,000 match records across 2 game modes with Elo/MMR ratings. 3 seasons (1 current, 2 archived) with battle pass progression data. Virtual economy: 10 item types, 5,000 transactions (purchases, trades, drops), currency balances per player. 1 active tournament bracket (16 players, quarterfinal stage). 20 player reports with evidence (screenshots, replay IDs). 3 ban appeals pending review. Leaderboards for current season by region (NA, EU, APAC).
