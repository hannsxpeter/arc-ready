#!/usr/bin/env bash
# arc-check: the disk-backed ledger, tier gates, and pre-publication gate for
# arc-ready. Agents run this instead of grading their own work.
# Bash 3.2 compatible. Needs only POSIX tools plus shasum or sha256sum.
# Checks fail closed: when the script cannot read what it needs, it blocks.

set -u
LC_ALL=C
export LC_ALL

ARC_CHECK_VERSION="2.0.0"
LEDGER=".arc-ready/PROGRESS.md"
PREPUB=".launch-ready/PREPUBLICATION.md"
FINDINGS=".harden-ready/FINDINGS.md"
HARDEN_STATE=".harden-ready/STATE.md"
TIERS="0 1.1 1.2 1.3 1.4 2.1 2.2 3.1 3.2 3.3 3.4"
WORK_TIERS="1.1 1.2 1.3 1.4 2.1 2.2 3.1 3.2 3.3 3.4"
STATUSES="pending in-flight done skipped imported failed re-invoked"
RESOLVED="fixed resolved closed verified mitigated remediated false-positive duplicate done"
FLIP_RE='flip point|would (flip|reverse|revisit)|revisit (if|when)|reverse (if|when)|reversal|re-?evaluate (if|when)'
SCAN_RE='(#|//|/\*|<!--|--|\*|;)[[:space:]]*(TODO|FIXME|XXX|HACK)([^A-Za-z]|$)|[Ll]orem [Ii]psum|faker\.|fake_data|fakeData|mock_data|mockData|hardcoded_response|NotImplementedError|[Nn]ot yet implemented|unimplemented!\(|todo!\('
MARKER_RE='^[[:space:]>*+-]*(TODO|FIXME)([^A-Za-z]|$)|(TODO|FIXME)[[:space:]]*[:(]|[Ll]orem [Ii]psum'
CODE_EXT='py|js|jsx|mjs|cjs|ts|tsx|go|rs|rb|java|kt|kts|swift|c|cc|cpp|h|hpp|cs|php|ex|exs|scala|vue|svelte|dart|lua|sh|sql|tf|html|htm|css|scss|sass|less|erb|ejs|hbs|njk|twig|liquid|astro'
SCAN_EXCLUDE='(^|/)(tests?|__tests__|spec|specs|fixtures?|__mocks__|mocks?|examples?|docs?|vendor|node_modules|dist|build|coverage)/|(^|/)\.[A-Za-z0-9_-]+/|(_test|\.test|\.spec|_spec|\.stories)\.[A-Za-z]+$|(^|/)test_[^/]*$|(^|/)conftest\.py$'
TIERS_HEADING='^##[ \t]+(tiers|tier ledger|step ledger)([ \t(:]|$)'
NL='
'
ROOT=""

usage() {
  cat <<'EOF'
arc-check 2.0.0: disk-backed state and gates for arc-ready

Usage: arc-check.sh [-C DIR] <command> [args]

Commands:
  init [--mode A|B|C|D] [--guided]   create .arc-ready/PROGRESS.md with every tier pending
  status                             verify the ledger against disk; print drift and the next tier
  mark TIER STATUS [--reason TEXT] [--override TEXT]
                                     record a status; done is refused until the tier gate passes
  gate TIER                          run the mechanical checks for one tier
  pillars [--name NAME]              write the Pillars loader and floor pillars when absent
  prepublish [--verify]              public-release gate; writes .launch-ready/PREPUBLICATION.md
  accept FINDING --owner NAME --expires YYYY-MM-DD --justification TEXT
                                     record a risk acceptance; a person must run it at a terminal
  scan [PATH...]                     find placeholders and fake data in source files
  version                            print the version

TIER is 0, 1.1-1.4, 2.1, 2.2, 3.1-3.4, or a name: prd, arch, roadmap, stack,
repo, build, deploy, observe, launch, harden.
STATUS is one of: pending in-flight done skipped imported failed re-invoked.

Exit codes: 0 ok, 1 check failed or refused, 2 usage error, 3 no ledger.
EOF
}

now() { date -u +%Y-%m-%dT%H:%M:%SZ; }
today() { date -u +%Y-%m-%d; }
lower() { printf '%s' "$1" | tr 'A-Z' 'a-z'; }
die() { printf 'arc-check: %s\n' "$1" >&2; exit "${2:-2}"; }

tier_name() {
  case "$1" in
    0) echo ARC ;; 1.1) echo PRD ;; 1.2) echo ARCH ;; 1.3) echo ROADMAP ;; 1.4) echo STACK ;;
    2.1) echo REPO ;; 2.2) echo PRODUCTION ;; 3.1) echo DEPLOY ;; 3.2) echo OBSERVE ;;
    3.3) echo LAUNCH ;; 3.4) echo HARDEN ;;
  esac
}

tier_path() {
  case "$1" in
    0) echo .arc-ready/PROGRESS.md ;; 1.1) echo .prd-ready/PRD.md ;;
    1.2) echo .architecture-ready/ARCH.md ;; 1.3) echo .roadmap-ready/ROADMAP.md ;;
    1.4) echo .stack-ready/STACK.md ;; 2.1) echo .repo-ready/SCAFFOLD.md ;;
    2.2) echo .production-ready/STATE.md ;; 3.1) echo .deploy-ready/DEPLOY.md ;;
    3.2) echo .observe-ready/OBSERVE.md ;; 3.3) echo .launch-ready/STATE.md ;;
    3.4) echo .harden-ready/FINDINGS.md ;;
  esac
}

# Alternates accepted from 1.x projects, checked after the canonical path.
tier_alt_paths() {
  case "$1" in
    1.4) echo .stack-ready/DECISION.md ;;
    2.1) echo .repo-ready/AUDIT-REPORT.md ;;
    3.1) echo .deploy-ready/STATE.md ;;
    3.2) echo .observe-ready/STATE.md ;;
  esac
}

normalize_tier() {
  case "$(lower "$1")" in
    0|arc|kickoff|arc-ready|kickoff-ready) echo 0 ;;
    1.1|prd|prd-ready) echo 1.1 ;;
    1.2|arch|architecture|architecture-ready) echo 1.2 ;;
    1.3|roadmap|roadmap-ready) echo 1.3 ;;
    1.4|stack|stack-ready) echo 1.4 ;;
    2.1|repo|repo-ready) echo 2.1 ;;
    2.2|production|build|app|production-ready) echo 2.2 ;;
    3.1|deploy|deploy-ready) echo 3.1 ;;
    3.2|observe|observe-ready) echo 3.2 ;;
    3.3|launch|launch-ready) echo 3.3 ;;
    3.4|harden|harden-ready) echo 3.4 ;;
    *) return 1 ;;
  esac
}

# Tiers that must be complete before TIER may start. Launch and harden run in parallel.
tier_upstream() {
  case "$1" in
    0|1.1) echo "" ;;
    1.2) echo "1.1" ;;
    1.3) echo "1.1 1.2" ;;
    1.4) echo "1.1 1.2 1.3" ;;
    2.1) echo "1.1 1.2 1.3 1.4" ;;
    2.2) echo "1.1 1.2 1.3 1.4 2.1" ;;
    3.1) echo "1.1 1.2 1.3 1.4 2.1 2.2" ;;
    3.2) echo "1.1 1.2 1.3 1.4 2.1 2.2 3.1" ;;
    3.3|3.4) echo "1.1 1.2 1.3 1.4 2.1 2.2 3.1 3.2" ;;
  esac
}

is_complete() { case "$1" in done|imported|skipped) return 0 ;; esac; return 1; }
valid_status() { case " $STATUSES " in *" $1 "*) return 0 ;; esac; return 1; }
is_resolved() { case " $RESOLVED " in *" $1 "*) return 0 ;; esac; return 1; }

# True when $1 is a real calendar date in YYYY-MM-DD form.
valid_date() {
  case "$1" in [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;; *) return 1 ;; esac
  printf '%s\n' "$1" | awk -F- '{
    y = $1 + 0; m = $2 + 0; d = $3 + 0
    if (m < 1 || m > 12 || d < 1) exit 1
    split("31 28 31 30 31 30 31 31 30 31 30 31", len, " ")
    max = len[m]
    if (m == 2 && ((y % 4 == 0 && y % 100 != 0) || y % 400 == 0)) max = 29
    exit (d <= max) ? 0 : 1
  }'
}

# Rejects text that would break a ledger line.
check_text() {
  case "$1" in *"|"*|*"$NL"*) die "$2 cannot contain | or a line break" ;; esac
}

# ---------- safe writes ----------

# Refuses to write through a symlink or anywhere outside the project directory.
guard_write() {
  if [ -L "$1" ]; then die "refused: $1 is a symlink; arc-check writes only regular files inside the project" 1; fi
  gw_dir=$(dirname "$1")
  gw_phys=$(cd "$gw_dir" 2>/dev/null && pwd -P) || die "refused: cannot resolve $gw_dir" 1
  case "$gw_phys/" in
    "$ROOT"/*) ;;
    *) die "refused: $1 resolves outside the project ($gw_phys)" 1 ;;
  esac
}

safe_mkdir() {
  if [ -L "$1" ]; then die "refused: $1 is a symlink; arc-check will not write through it" 1; fi
  mkdir -p "$1" || die "cannot create $1" 1
  sm_phys=$(cd "$1" 2>/dev/null && pwd -P) || die "refused: cannot resolve $1" 1
  case "$sm_phys/" in
    "$ROOT"/*) ;;
    *) die "refused: $1 resolves outside the project" 1 ;;
  esac
}

artifact_for() {
  for p in $(tier_path "$1") $(tier_alt_paths "$1"); do
    if [ -f "$p" ]; then echo "$p"; return 0; fi
  done
  return 1
}

# Prints why FILE is not a real artifact, or nothing when it is.
artifact_problem() {
  if [ ! -f "$1" ]; then echo "missing"; return; fi
  if [ ! -r "$1" ]; then echo "unreadable"; return; fi
  if [ ! -s "$1" ]; then echo "empty"; return; fi
  size=$(wc -c < "$1" | tr -d ' ')
  if [ "$size" -lt 200 ]; then echo "only $size bytes"; return; fi
  if grep -Eq '(^|[^$])\{\{' "$1"; then echo "unfilled template placeholders"; return; fi
  if grep -qi '(stub)' "$1"; then echo "still marked (stub)"; return; fi
}

# ---------- ledger ----------

# Prints "tier status override" for every tier the ledger mentions. Reads the
# 2.x list format and the 1.x list, named, and table formats. 2.x lines win and
# the last line for a tier wins. When the ledger has a Tiers section (or the
# 1.x Tier ledger or Step ledger), only lines inside it count.
ledger_pairs() {
  [ -f "$LEDGER" ] || return 0
  TH="$TIERS_HEADING" awk '
    function istiers(l) { l = tolower(l); return l ~ ENVIRON["TH"] }
    function norm(n) {
      n = tolower(n); gsub(/^[ \t]+|[ \t]+$/, "", n)
      if (n ~ /^(kickoff|arc)(-ready)?$/) return "0"
      if (n ~ /^prd(-ready)?$/) return "1.1"
      if (n ~ /^arch(itecture)?(-ready)?$/) return "1.2"
      if (n ~ /^roadmap(-ready)?$/) return "1.3"
      if (n ~ /^stack(-ready)?$/) return "1.4"
      if (n ~ /^repo(-ready)?$/) return "2.1"
      if (n ~ /^production(-ready)?$/) return "2.2"
      if (n ~ /^deploy(-ready)?$/) return "3.1"
      if (n ~ /^observe(-ready)?$/) return "3.2"
      if (n ~ /^launch(-ready)?$/) return "3.3"
      if (n ~ /^harden(-ready)?$/) return "3.4"
      return ""
    }
    function firstword(s,   a, n, i) { s = tolower(s); n = split(s, a, /[^a-z0-9-]+/); for (i = 1; i <= n; i++) if (a[i] != "") return a[i]; return "" }
    NR == FNR { l = $0; sub(/\r$/, "", l); if (istiers(l)) has = 1; next }
    {
      line = $0; sub(/\r$/, "", line)
      if (line ~ /^##[ \t]/) { inside = istiers(line); next }
      if (has && !inside) next
      if (line ~ /^[ \t]*\|/) {
        n = split(line, c, "|")
        if (n >= 4) { t = norm(c[3]); if (t != "") legacy[t] = firstword(c[4]) }
        next
      }
      if (line !~ /^[ \t]*[-*][ \t]+/) next
      sub(/^[ \t]*[-*][ \t]+/, "", line)
      if (match(line, /^(0|[123]\.[1-4])([ \t]+\([A-Za-z]+\))?[ \t]*:/)) {
        t = line; sub(/[ \t(:].*$/, "", t)
        canon[t] = firstword(substr(line, RLENGTH + 1))
        over[t] = (tolower(line) ~ /\|[ \t]*override:/) ? 1 : 0
        next
      }
      if (match(line, /^[a-z]+-ready[ \t]*:/)) {
        t = norm(substr(line, 1, index(line, ":") - 1))
        if (t != "") legacy[t] = firstword(substr(line, RLENGTH + 1))
      }
    }
    END {
      for (t in canon) print t, canon[t], over[t]
      for (t in legacy) if (!(t in canon)) print t, legacy[t], 0
    }' "$LEDGER" "$LEDGER"
}

pair_status() { printf '%s\n' "$1" | awk -v t="$2" '$1 == t { print $2; exit }'; }
pair_override() { printf '%s\n' "$1" | awk -v t="$2" '$1 == t { print $3; exit }'; }

# Value of KEY on TIER's current 2.x line, for example the recorded override reason.
tier_line_field() {
  [ -f "$LEDGER" ] || return 0
  TH="$TIERS_HEADING" TL_TIER="$1" TL_KEY="$2" awk '
    function istiers(l) { l = tolower(l); return l ~ ENVIRON["TH"] }
    NR == FNR { l = $0; sub(/\r$/, "", l); if (istiers(l)) has = 1; next }
    {
      line = $0; sub(/\r$/, "", line)
      if (line ~ /^##[ \t]/) { inside = istiers(line); next }
      if (has && !inside) next
      if (line !~ /^[ \t]*[-*][ \t]+/) next
      sub(/^[ \t]*[-*][ \t]+/, "", line)
      if (index(line, ENVIRON["TL_TIER"] " (") != 1) next
      val = ""
      n = split(line, f, "|")
      for (i = 2; i <= n; i++) {
        kv = f[i]; sub(/^[ \t]+/, "", kv)
        if (index(kv, ENVIRON["TL_KEY"] ":") == 1) { v = substr(kv, length(ENVIRON["TL_KEY"]) + 2); sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v); val = v }
      }
      last = val
    }
    END { if (last != "") print last }' "$LEDGER" "$LEDGER"
}

# Last value of a "key: value" line in the ledger.
ledger_field() {
  [ -f "$LEDGER" ] || return 0
  LF_KEY=$(lower "$1") awk '
    {
      line = $0; sub(/\r$/, "", line); line = tolower(line)
      gsub(/\*\*|__|`/, "", line); sub(/^[#> \t*-]+/, "", line)
      k = ENVIRON["LF_KEY"]
      if (index(line, k ":") == 1) {
        n = split(substr(line, length(k) + 2), a, /[^a-z0-9_.-]+/)
        for (i = 1; i <= n; i++) if (a[i] != "") { last = a[i]; break }
      }
    }
    END { if (last != "") print last }' "$LEDGER"
}

# The strictest policy wins: any "gate-launch-on-hardening: hard" line applies.
policy_is_hard() {
  [ -f "$LEDGER" ] || return 1
  awk '
    {
      line = $0; sub(/\r$/, "", line); line = tolower(line)
      gsub(/\*\*|__|`/, "", line); sub(/^[#> \t*-]+/, "", line)
      if (index(line, "gate-launch-on-hardening:") == 1 && substr(line, 26) ~ /^[ \t]*hard([^a-z]|$)/) hard = 1
    }
    END { exit hard ? 0 : 1 }' "$LEDGER"
}

arc_mode() {
  am=$(ledger_field arc_mode)
  [ -n "$am" ] || am=$(ledger_field mode)
  printf '%s' "$am"
}

# Replaces every occurrence of KEY with one "KEY: VALUE" line after arc_mode.
set_ledger_field() {
  guard_write "$LEDGER"
  tmp="$LEDGER.tmp.$$"
  SF_KEY="$1" SF_VAL="$2" awk '
    BEGIN { k = tolower(ENVIRON["SF_KEY"]) ":" }
    {
      probe = $0; sub(/\r$/, "", probe); probe = tolower(probe)
      gsub(/\*\*|__|`/, "", probe); sub(/^[#> \t*-]+/, "", probe)
      if (index(probe, k) == 1) next
      print
      if (!done && probe ~ /^arc_mode:/) { print ENVIRON["SF_KEY"] ": " ENVIRON["SF_VAL"]; done = 1 }
    }
    END { if (!done) print ENVIRON["SF_KEY"] ": " ENVIRON["SF_VAL"] }' "$LEDGER" > "$tmp" && mv "$tmp" "$LEDGER" || die "could not update $LEDGER" 1
}

# Replaces TIER's last line inside the Tiers section (or anywhere, for a 1.x
# ledger without one), or adds the line at the end of that section.
write_tier_line() {
  guard_write "$LEDGER"
  tmp="$LEDGER.tmp.$$"
  TH="$TIERS_HEADING" WT_TIER="$1" WT_LINE="$2" awk '
    function istiers(l) { l = tolower(l); return l ~ ENVIRON["TH"] }
    function matches(l,   s, t) {
      t = ENVIRON["WT_TIER"]; s = l
      if (s !~ /^[ \t]*[-*][ \t]+/) return 0
      sub(/^[ \t]*[-*][ \t]+/, "", s)
      return (index(s, t " (") == 1 || index(s, t ":") == 1)
    }
    NR == FNR {
      l = $0; sub(/\r$/, "", l)
      if (l ~ /^##[ \t]/) {
        if (istiers(l)) { has = 1; inside = 1 } else { if (inside && !secend) secend = FNR; inside = 0 }
        next
      }
      if (matches(l)) { lastany = FNR; if (inside) lastin = FNR }
      next
    }
    FNR == 1 { target = has ? lastin : lastany }
    {
      if (FNR == target) { print ENVIRON["WT_LINE"]; done = 1; next }
      if (!target && has && !done && secend && FNR == secend) { print ENVIRON["WT_LINE"]; print ""; done = 1 }
      print
    }
    END { if (!done) print ENVIRON["WT_LINE"] }' "$LEDGER" "$LEDGER" > "$tmp" && mv "$tmp" "$LEDGER" || die "could not update $LEDGER" 1
}

log_event() {
  guard_write "$LEDGER"
  grep -q '^## Log' "$LEDGER" || printf '\n## Log\n\n' >> "$LEDGER"
  printf -- '- %s: %s\n' "$(now)" "$1" >> "$LEDGER" || die "could not update $LEDGER" 1
}

hash_stdin() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 | awk '{ print "sha256:" $1 }'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum | awk '{ print "sha256:" $1 }'
  else
    cksum | awk '{ print "cksum:" $1 "-" $2 }'
  fi
}

hash_text() { printf '%s' "$1" | hash_stdin | cut -d: -f2 | cut -c1-16; }

# ---------- files ----------

# Lists project files without running project-configured git commands.
project_files() {
  if command -v git >/dev/null 2>&1 && git -c core.fsmonitor=false rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -c core.fsmonitor=false -c core.quotepath=off ls-files -z --cached --others --exclude-standard 2>/dev/null | tr '\0' '\n'
  else
    find . -type f 2>/dev/null | sed 's|^\./||'
  fi
}

scan_files() {
  if [ "$#" -gt 0 ]; then
    for p in "$@"; do
      if [ -d "$p" ]; then find "$p" -type f; elif [ -f "$p" ]; then printf '%s\n' "$p"; fi
    done
  else
    project_files
  fi | grep -Ei "\.($CODE_EXT)$" | grep -Ev "$SCAN_EXCLUDE"
}

# Prints matches and returns 1 when shipped source holds placeholders or fake data.
run_scan() {
  list=$(scan_files "$@")
  if [ -z "$list" ]; then echo "  [warn] no source files found to scan"; return 2; fi
  count=$(printf '%s\n' "$list" | wc -l | tr -d ' ')
  hits=$(printf '%s\n' "$list" | while IFS= read -r file; do
      [ -f "$file" ] || continue
      grep -anE "$SCAN_RE" "$file" 2>/dev/null | while IFS= read -r hit; do printf '%s:%s\n' "$file" "$hit"; done
    done)
  if [ -n "$hits" ]; then
    printf '%s\n' "$hits" | head -20 | sed 's/^/  [hit] /'
    return 1
  fi
  echo "  [ok] $count source files, no placeholders or fake data"
  return 0
}

# ---------- findings and acceptances ----------

# Prints "id<TAB>severity<TAB>status<TAB>kind" per finding. Reads key-value
# findings (id:, severity:, status: lines, in any order, bounded by headings or
# the next finding) and tables with Severity and Status columns. kind is
# explicit, heading, table, or generated; a generated id cannot be accepted.
parse_findings() {
  awk '
    function clean(s) { sub(/\r$/, "", s); gsub(/\*\*|__|`/, "", s); return s }
    function firsttok(s,   a, n, i) { s = tolower(s); n = split(s, a, /[^a-z0-9-]+/); for (i = 1; i <= n; i++) if (a[i] != "") return a[i]; return "" }
    function level(s,   a, n, i) {
      s = tolower(s); n = split(s, a, /[^a-z]+/)
      for (i = 1; i <= n; i++) {
        if (a[i] == "moderate") return "medium"
        if (a[i] ~ /^(critical|high|medium|low|info|informational|none)$/) return a[i]
      }
      return "unknown"
    }
    function idtok(s,   a, n, i) { n = split(s, a, /[^A-Za-z0-9._-]+/); for (i = 1; i <= n; i++) if (a[i] ~ /^[A-Za-z0-9]/) return a[i]; return "" }
    function value(s) { sub(/^[^:]*:[ \t]*/, "", s); return s }
    function emit(   st2) {
      if (sev != "") {
        n++; st2 = (st == "" ? "unknown" : st)
        if (fid != "") print fid "\t" sev "\t" st2 "\t" fkind
        else print "finding-" n "\t" sev "\t" st2 "\tgenerated"
      }
      sev = ""; st = ""
    }
    { line = clean($0) }
    line ~ /^[ \t]*\|/ {
      emit(); fid = ""; fkind = ""
      nc = split(line, c, "|")
      if (!intable) {
        sevc = 0; stc = 0; idc = 0
        for (i = 2; i <= nc; i++) {
          h = tolower(c[i]); gsub(/^[ \t]+|[ \t]+$/, "", h)
          if (h ~ /^severity/) sevc = i
          else if (h ~ /^(status|state)/) stc = i
          else if (h ~ /^(id|finding|finding id|ref|#)$/) idc = i
        }
        intable = (sevc && stc) ? 1 : 2
        next
      }
      if (intable != 1) next
      sepcheck = line; gsub(/[| \t:-]/, "", sepcheck)
      if (sepcheck == "") next
      n++
      rsev = level(c[sevc]); rst = firsttok(c[stc]); if (rst == "") rst = "unknown"
      rid = (idc ? idtok(c[idc]) : "")
      if (rid == "") print "finding-" n "\t" rsev "\t" rst "\tgenerated"
      else print rid "\t" rsev "\t" rst "\ttable"
      next
    }
    { intable = 0 }
    line ~ /^#+[ \t]/ {
      emit(); hid = ""
      if (match(line, /[A-Za-z][A-Za-z0-9]*-[0-9]+/)) hid = substr(line, RSTART, RLENGTH)
      fid = hid; fkind = (hid != "" ? "heading" : "")
      next
    }
    {
      kv = line
      sub(/^[ \t>]*/, "", kv)
      sub(/^([-*+]|[0-9]+[.)])[ \t]+/, "", kv)
      sub(/^\[[ xX]\][ \t]+/, "", kv)
      low = tolower(kv)
      if (low ~ /^(finding[ -])?id[ \t]*:/) {
        if (sev != "") emit()
        fid = idtok(value(kv)); fkind = (fid != "" ? "explicit" : "")
        next
      }
      if (low ~ /^severity[ \t]*(\([^)]*\))?[ \t]*:/) {
        if (sev != "") { emit(); fid = hid; fkind = (hid != "" ? "heading" : "") }
        sev = level(value(kv))
        next
      }
      if (low ~ /^(status|state)[ \t]*(\([^)]*\))?[ \t]*:/) {
        if (st == "") { st = firsttok(value(kv)); if (st == "") st = "unknown" }
        next
      }
    }
    END { emit() }' "$1"
}

# Prints the line numbers of Critical mentions that no readable finding
# explains. Explained: a severity line, a row of a findings table, a heading
# whose section holds a severity line, an explicit "critical findings: none",
# or a one-line "No critical findings." statement.
critical_mentions() {
  awk '
    function clean(s) { sub(/\r$/, "", s); gsub(/\*\*|__|`/, "", s); return tolower(s) }
    function mentions(s) { return s ~ /(^|[^a-z-])critical([^a-z-]|$)/ }
    function mark_seen(   i) { for (i = 1; i <= nh; i++) hseen[i] = 1 }
    function close_to(level,   i) {
      for (i = nh; i >= 1; i--) {
        if (hlev[i] < level) break
        if (!hseen[i]) print hline[i]
        nh--
      }
    }
    {
      low = clean($0)
      if (low ~ /^[ \t]*\|/) {
        nc = split(low, c, "|")
        if (!intable) {
          sevc = 0; stc = 0
          for (i = 2; i <= nc; i++) { h = c[i]; gsub(/^[ \t]+|[ \t]+$/, "", h); if (h ~ /^severity/) sevc = i; else if (h ~ /^(status|state)/) stc = i }
          intable = (sevc && stc) ? 1 : 2
          if (intable == 2 && mentions(low)) print FNR
          next
        }
        if (intable == 1) { mark_seen(); next }
        if (mentions(low)) print FNR
        next
      }
      intable = 0
      if (low ~ /^#+[ \t]/) {
        match(low, /^#+/); lv = RLENGTH
        close_to(lv)
        if (mentions(low)) { nh++; hlev[nh] = lv; hline[nh] = FNR; hseen[nh] = 0 }
        next
      }
      kv = low; sub(/^[ \t>]*/, "", kv); sub(/^([-*+]|[0-9]+[.)])[ \t]+/, "", kv); sub(/^\[[ x]\][ \t]+/, "", kv)
      if (kv ~ /^severity[ \t]*(\([^)]*\))?[ \t]*:/) { mark_seen(); next }
      if (!mentions(low)) next
      if (kv ~ /critical([ \t]+(findings?|issues?|risks?|vulnerabilities))?[ \t]*:[ \t]*(none|0|zero)([^a-z0-9]|$)/) next
      if (kv ~ /^(there (are|were) )?(no|0|zero) (open |unresolved |remaining )?critical (findings?|issues?|risks?|vulnerabilities)( (remain|remaining|open|found))?[ \t]*\.?[ \t]*$/) next
      print FNR
    }
    END { close_to(0) }' "$1"
}

findings_none_declared() {
  grep -Eiq '^[[:space:]>*_-]*findings[*_]*[[:space:]]*:[[:space:]]*[*_]*none([^a-z]|$)' "$1"
}

acceptance_check() { hash_text "$(lower "$1")|$2|$3|$4|$5|$6"; }

# Prints "id|severity|owner|accepted|expires|justification|check|fresh" for
# every acceptance line in the ledger; fresh is 1 when the expiry is today or later.
acceptance_rows() {
  [ -f "$LEDGER" ] || return 0
  awk -v today="$(today)" '
    function valid(s,   p, y, m, d, len, max) {
      if (s !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) return 0
      split(s, p, "-"); y = p[1] + 0; m = p[2] + 0; d = p[3] + 0
      if (m < 1 || m > 12 || d < 1) return 0
      split("31 28 31 30 31 30 31 31 30 31 30 31", len, " "); max = len[m]
      if (m == 2 && ((y % 4 == 0 && y % 100 != 0) || y % 400 == 0)) max = 29
      return d <= max
    }
    { line = $0; sub(/\r$/, "", line) }
    tolower(line) ~ /finding:/ {
      n = split(line, f, "|"); id = ""; sev = ""; owner = ""; just = ""; acc = ""; expd = ""; chk = ""
      for (i = 1; i <= n; i++) {
        kv = f[i]; sub(/^[ \t*-]+/, "", kv)
        if (index(kv, ":") == 0) continue
        k = tolower(kv); sub(/:.*$/, "", k); gsub(/[ \t]/, "", k)
        v = kv; sub(/^[^:]*:[ \t]*/, "", v); sub(/[ \t]+$/, "", v)
        if (k == "finding") id = v; else if (k == "severity") sev = tolower(v); else if (k == "owner") owner = v
        else if (k == "justification") just = v; else if (k == "accepted") acc = v
        else if (k == "expires") expd = v; else if (k == "check") chk = v
      }
      fresh = (valid(expd) && expd >= today) ? 1 : 0
      if (id != "") print id "|" sev "|" owner "|" acc "|" expd "|" just "|" chk "|" fresh
    }' "$LEDGER"
}

# Prints "id|severity" (id lowercase) for each acceptance that `accept`
# recorded, that has not been edited since, and that has not expired.
valid_acceptances() {
  va_rows=$(acceptance_rows)
  [ -n "$va_rows" ] || return 0
  while IFS='|' read -r va_id va_sev va_owner va_acc va_exp va_just va_chk va_fresh; do
    [ -n "$va_id" ] && [ -n "$va_sev" ] && [ -n "$va_owner" ] && [ -n "$va_acc" ] && [ -n "$va_just" ] && [ "$va_fresh" = 1 ] || continue
    if [ "$va_chk" = "$(acceptance_check "$va_id" "$va_sev" "$va_owner" "$va_acc" "$va_exp" "$va_just")" ]; then
      printf '%s|%s\n' "$(lower "$va_id")" "$va_sev"
    fi
  done <<EOF
$va_rows
EOF
}

# Hash of everything the release decision depends on: findings, hardening
# state, acceptance lines (including whether each has expired), and policy.
hardening_revision() {
  if [ ! -f "$FINDINGS" ]; then echo none; return; fi
  {
    cat "$FINDINGS"
    [ -f "$HARDEN_STATE" ] && cat "$HARDEN_STATE"
    echo "--- acceptances"
    acceptance_rows
    echo "--- policy"
    if policy_is_hard; then echo hard; else echo default; fi
  } | hash_stdin
}

pp_reason() { PP_REASONS="$PP_REASONS- $1$NL"; }

# Sets PP_VERDICT, PP_REV, PP_POLICY, PP_TOTAL, PP_ACCEPTED, PP_UNRESOLVED, and
# PP_REASONS. Anything it cannot read counts against publication.
evaluate_prepublish() {
  PP_REASONS=""; PP_TOTAL=0; PP_ACCEPTED=0; PP_UNRESOLVED=0
  if policy_is_hard; then PP_POLICY=hard; else PP_POLICY=default; fi
  PP_REV=$(hardening_revision)
  if [ ! -e "$FINDINGS" ] && [ ! -L "$FINDINGS" ]; then
    pp_reason "no hardening findings at $FINDINGS; hardening has not run, and a skip cannot authorize a public release"
    PP_UNRESOLVED=1
  elif [ ! -f "$FINDINGS" ] || [ ! -r "$FINDINGS" ]; then
    pp_reason "cannot read $FINDINGS"
    PP_UNRESOLVED=1
  else
    pp_rows=$(parse_findings "$FINDINGS") || { pp_reason "could not parse $FINDINGS"; PP_UNRESOLVED=1; pp_rows=""; }
    if [ -z "$pp_rows" ]; then
      if ! findings_none_declared "$FINDINGS"; then
        pp_reason "no findings could be read from $FINDINGS; give each finding id:, severity:, and status: lines (or a table with Severity and Status columns), or write findings: none"
        PP_UNRESOLVED=$((PP_UNRESOLVED + 1))
      fi
    else
      pp_dups=$(printf '%s\n' "$pp_rows" | cut -f1 | tr 'A-Z' 'a-z' | sort | uniq -d | tr '\n' ' ')
      if [ -n "$pp_dups" ]; then
        pp_reason "duplicate finding ids: ${pp_dups}(give every finding its own id: line)"
        PP_UNRESOLVED=$((PP_UNRESOLVED + 1))
      fi
      pp_accepted=$(valid_acceptances)
      while IFS='	' read -r pp_id pp_sev pp_st pp_kind; do
        [ -n "$pp_id" ] || continue
        if [ "$pp_sev" = unknown ]; then
          pp_reason "$pp_id: severity could not be read; write severity: critical, high, medium, or low"
          PP_UNRESOLVED=$((PP_UNRESOLVED + 1))
          continue
        fi
        [ "$pp_sev" = critical ] || continue
        PP_TOTAL=$((PP_TOTAL + 1))
        is_resolved "$pp_st" && continue
        if [ "$PP_POLICY" = default ] && printf '%s\n' "$pp_accepted" | grep -Fqx -- "$(lower "$pp_id")|critical"; then
          PP_ACCEPTED=$((PP_ACCEPTED + 1))
        else
          PP_UNRESOLVED=$((PP_UNRESOLVED + 1))
          pp_reason "$pp_id: critical, status $pp_st, no current risk acceptance recorded with arc-check.sh accept"
          if acceptance_rows | AR_ID="$(lower "$pp_id")" awk -F'|' 'tolower($1) == ENVIRON["AR_ID"] { f = 1 } END { exit f ? 0 : 1 }'; then
            pp_reason "$pp_id: ignored an acceptance line that was written or edited by hand, is incomplete, has expired, or names another severity"
          fi
        fi
      done <<EOF
$pp_rows
EOF
    fi
    pp_lines=$(critical_mentions "$FINDINGS" | head -5 | tr '\n' ' ')
    if [ -n "$pp_lines" ]; then
      pp_reason "$FINDINGS mentions Critical outside a readable finding (line ${pp_lines% }); give it id:, severity:, and status: lines, or write critical findings: none"
      PP_UNRESOLVED=$((PP_UNRESOLVED + 1))
    fi
    pp_h=$(pair_status "$(ledger_pairs)" 3.4)
    case "$pp_h" in
      done|imported) ;;
      *) pp_reason "warning: hardening (3.4) is ${pp_h:-unrecorded}; a later finding invalidates this pass" ;;
    esac
  fi
  if [ "$PP_UNRESOLVED" -eq 0 ]; then PP_VERDICT=pass; else PP_VERDICT=block; fi
}

# ---------- gate helpers ----------

GATE_FAILS=0
g_ok() { printf '  [ok] %s\n' "$1"; }
g_warn() { printf '  [warn] %s\n' "$1"; }
g_fail() { printf '  [fail] %s\n' "$1"; GATE_FAILS=$((GATE_FAILS + 1)); }

has() { [ -f "$1" ] && grep -Eiq "$2" "$1"; }

# True when FILE has a heading (or bold label) whose text matches the lowercase ERE.
has_section() {
  [ -f "$1" ] || return 1
  HS_RE="$2" awk '
    {
      line = tolower($0); re = ENVIRON["HS_RE"]
      if (line ~ /^#+[ \t]/ && line ~ re) { found = 1; exit }
      if (line ~ /^[ \t]*(\*\*|__)/) { sub(/^[ \t]*(\*\*|__)/, "", line); if (line ~ ("^(" re ")")) { found = 1; exit } }
    }
    END { exit found ? 0 : 1 }' "$1"
}

# Body of the first heading section matching the lowercase ERE, up to the next
# heading of the same or higher level.
section_body() {
  [ -f "$1" ] || return 0
  SB_RE="$2" awk '
    /^#+[ \t]/ {
      level_here = match($0, /[^#]/) - 1
      if (inside && level_here <= level) exit
      if (!inside && tolower($0) ~ ENVIRON["SB_RE"]) { inside = 1; level = level_here; next }
    }
    inside { print }' "$1"
}

common_artifact_checks() {
  f="$1"
  prob=$(artifact_problem "$f")
  if [ -n "$prob" ]; then g_fail "$f: $prob"; return 1; fi
  g_ok "$f exists and is not a template"
  if grep -Eq "$MARKER_RE" "$f"; then
    g_fail "$f contains TODO or FIXME markers or lorem ipsum (make them open questions)"
  fi
  if grep -Eq '(^|[^A-Za-z])TBD([^A-Za-z]|$)' "$f"; then
    g_warn "$f contains TBD; make each one an open question with an owner and a date"
  fi
  return 0
}

gate_prd() {
  f=$(tier_path 1.1)
  common_artifact_checks "$f" || return
  if has_section "$f" 'problem|pain'; then g_ok "problem section"; else g_fail "no problem section (frame the problem before the solution)"; fi
  if has_section "$f" 'user|persona|customer|audience|who '; then g_ok "target user section"; else g_fail "no target user section"; fi
  body=$(section_body "$f" 'success|metric|measure|outcome|kpi')
  if [ -z "$body" ]; then body=$(grep -Ei 'success|metric|kpi|outcome' "$f"); fi
  if printf '%s\n' "$body" | grep -q '[0-9]'; then g_ok "success criteria carry numbers"; else g_fail "no measurable success criteria (thresholds with numbers)"; fi
  must=$(grep -cE "\((Must|MUST)\)|\[(Must|MUST)\]|\|[[:space:]]*(Must|MUST)[[:space:]]*\||(^|[^A-Za-z])(Must|MUST)(-have| have)?:|Must-have|MUST-HAVE|(^|[^A-Za-z0-9])P0([^0-9]|$)" "$f")
  all=$(grep -cE "\((Must|MUST|Should|SHOULD|Could|COULD|Won't|WON'T|Wont)\)|\[(Must|MUST|Should|SHOULD|Could|COULD|Won't|WON'T|Wont)\]|\|[[:space:]]*(Must|MUST|Should|SHOULD|Could|COULD|Won't|WON'T|Wont)[[:space:]]*\||(^|[^A-Za-z])(Must|MUST|Should|SHOULD|Could|COULD|Won't|WON'T|Wont)(-have| have)?:|(Must|Should|Could|Won't)-have|(^|[^A-Za-z0-9])P[0-3]([^0-9]|$)" "$f")
  if [ "$all" -eq 0 ]; then
    g_fail "requirements carry no priorities (feature laundry list)"
  elif [ "$all" -ge 4 ] && [ $((must * 2)) -gt "$all" ]; then
    g_fail "more than half of prioritized items are Must ($must of $all); draw a cut line"
  else
    g_ok "requirements prioritized ($must Must of $all)"
  fi
  if has_section "$f" 'out[- ]of[- ]scope|non[- ]goals|not in scope|no[- ]gos|not doing|exclusions|won.t (do|build|have)|scope boundar'; then g_ok "scope boundary section"; else g_fail "no out-of-scope or non-goals section"; fi
  if has_section "$f" 'open question'; then g_ok "open questions section"; else g_warn "no open questions section"; fi
}

gate_arch() {
  f=$(tier_path 1.2)
  common_artifact_checks "$f" || return
  if has "$f" "$FLIP_RE"; then g_ok "decisions name flip points"; else g_fail "no flip point on any decision"; fi
  if has "$f" 'trust boundar'; then g_ok "trust boundaries"; else g_fail "no trust boundaries"; fi
  if [ -s .architecture-ready/HANDOFF.md ] || has "$f" 'dependency (graph|order)|build order|topolog'; then
    g_ok "component dependency graph for the roadmap"
  else
    g_fail "no component dependency graph (.architecture-ready/HANDOFF.md)"
  fi
  if has "$f" '[0-9]+ ?(ms|rps|req/s|qps|users|seats|tps|gb|tb|mb|%)'; then g_ok "numbers present for scale or performance"; else g_warn "no scale or performance numbers (\"scalable\" needs a threshold)"; fi
  if [ -d .architecture-ready/adr ] || has "$f" 'adr'; then g_ok "ADRs present"; else g_warn "no ADRs"; fi
}

gate_roadmap() {
  f=$(tier_path 1.3)
  common_artifact_checks "$f" || return
  if grep -Ei 'team size|engineers?|capacity|developers?|people|fte|engineer-weeks|person-weeks' "$f" | grep -q '[0-9]'; then
    g_ok "capacity input"
  else
    g_fail "no capacity input (engineers and available weeks)"
  fi
  if has "$f" 'now|next|later|milestone|phase|cycle|slice|horizon'; then g_ok "horizons or milestones"; else g_fail "no horizons, milestones, or slices"; fi
  later=$(section_body "$f" 'later')
  if printf '%s\n' "$later" | grep -Eq '20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]'; then g_warn "exact dates in the Later horizon (fictional precision)"; fi
  team=$(grep -Ei '^[^|]*team size[^0-9]*[0-9]+' "$f" | head -1 | grep -Eo '[0-9]+' | head -1)
  tracks=$(grep -Ei 'parallel tracks?[^0-9]*[0-9]+' "$f" | grep -Eo '[0-9]+' | sort -n | tail -1)
  if [ -n "$team" ] && [ -n "$tracks" ] && [ "$tracks" -gt "$team" ]; then g_fail "more parallel tracks ($tracks) than team size ($team)"; fi
  if has "$f" 'R-?[0-9]+|FR-?[0-9]+|ADR|PRD|ARCH|component'; then g_ok "rows cite upstream artifacts"; else g_warn "no upstream references (speculative roadmap)"; fi
}

gate_stack() {
  f=$(artifact_for 1.4 || tier_path 1.4)
  common_artifact_checks "$f" || return
  if has "$f" 'weight'; then g_ok "weighted criteria"; else g_fail "no stated weights (unweighted recommendation)"; fi
  if has "$f" "$FLIP_RE"; then g_ok "flip points"; else g_fail "no flip point on the recommendation"; fi
  if has "$f" 'migrat|exit (path|plan|cost)|lock-?in'; then g_ok "exit or migration path"; else g_fail "no migration or exit path"; fi
  if has "$f" '(as of|checked|verified|retrieved|accessed)[^0-9]*20[0-9][0-9]'; then g_ok "freshness date recorded"; else g_warn "no date recorded for version, price, or vendor checks"; fi
}

gate_repo() {
  f=$(artifact_for 2.1 || tier_path 2.1)
  common_artifact_checks "$f" || true
  if [ -f README.md ] && [ "$(wc -c < README.md | tr -d ' ')" -ge 200 ] && ! grep -Eq "$MARKER_RE" README.md; then
    g_ok "project README"
  else
    g_fail "README.md missing, too short, or holding placeholders"
  fi
  ci=""
  for c in .github/workflows/*.yml .github/workflows/*.yaml .gitlab-ci.yml .circleci/config.yml azure-pipelines.yml Jenkinsfile bitbucket-pipelines.yml .buildkite/pipeline.yml; do
    if [ -s "$c" ]; then ci="$c"; break; fi
  done
  if [ -n "$ci" ]; then g_ok "CI config ($ci); confirm it passes on a fresh clone"; else g_fail "no CI configuration"; fi
  pillars=$(ledger_field pillars)
  if [ -f AGENTS.md ] && grep -qi 'pillars' AGENTS.md && [ -f agents/context.md ] && [ -f agents/repo.md ]; then
    g_ok "Pillars loader and floor pillars"
  else
    case "$pillars" in
      adoption-blocked-existing-agents|guidance-text|opted-out) g_ok "Pillars adoption recorded as $pillars" ;;
      *) g_fail "no Pillars memory (run arc-check.sh pillars) and no recorded block" ;;
    esac
  fi
  [ -f LICENSE ] || [ -f LICENSE.md ] || [ -f LICENSE.txt ] || g_warn "no LICENSE"
  [ -f SECURITY.md ] || [ -f .github/SECURITY.md ] || g_warn "no SECURITY.md"
}

gate_build() {
  f=$(tier_path 2.2)
  common_artifact_checks "$f" || true
  out=$(run_scan)
  code=$?
  printf '%s\n' "$out"
  if [ "$code" -eq 1 ]; then g_fail "placeholders or fake data in shipped source (see hits)"; fi
  if [ "$code" -eq 2 ]; then g_fail "no shipped source files found to check"; fi
  tests=$(project_files \
    | grep -E '(^|/)(tests?|__tests__|spec)/[^/]+\.[A-Za-z]+$|(_test|\.test|\.spec|_spec)\.[A-Za-z]+$|(^|/)test_[^/]*$' \
    | grep -Ev '(^|/)(__init__|conftest)\.py$|\.(md|txt|json|ya?ml|snap|lock)$' | wc -l | tr -d ' ')
  if [ "$tests" -gt 0 ]; then g_ok "$tests test files; confirm they pass"; else g_fail "no tests found"; fi
  if ! grep -Eiq '(tests?|specs?)[^|]*(pass|green|ok)|(pass|green)[^|]*(tests?|specs?)' "$f" 2>/dev/null; then
    g_warn "$f does not record a passing test run"
  fi
}

gate_deploy() {
  f=$(artifact_for 3.1 || tier_path 3.1)
  common_artifact_checks "$f" || return
  negated='untested|not (yet )?(been )?(tested|run|executed|exercised|verified|rehearsed)|never (tested|run|executed|exercised)|no rollback'
  evidence='(^|[^a-z])(tested|exercised|executed|drilled|rehearsed|verified|ran)([^a-z]|$)'
  rb=$( { grep -Ei 'rollback|roll(ed)? back' "$f"; section_body "$f" 'rollback|roll back'; } | grep -Eiv "$negated")
  if printf '%s\n' "$rb" | grep -Eiq "$evidence"; then
    g_ok "rollback exercised"
  else
    g_fail "no evidence that rollback was executed"
  fi
  if has "$f" 'canary'; then
    if has "$f" 'stop rule|abort (if|when)|halt (if|when)|rollback (at|if|when)|auto-?rollback|threshold'; then g_ok "canary has stop rules"; else g_fail "canary without stop rules (paper canary)"; fi
  fi
  if has "$f" 'migration'; then
    if has "$f" 'code-only|data-forward|expand|contract'; then g_ok "migrations classified"; else g_warn "migrations not classified code-only or data-forward"; fi
  fi
  if has "$f" 'same artifact|same image|digest|promot'; then g_ok "same-artifact promotion"; else g_warn "promotion of one artifact across environments not stated"; fi
}

gate_observe() {
  f=$(artifact_for 3.2 || tier_path 3.2)
  common_artifact_checks "$f" || return
  files="$f"
  for extra in .observe-ready/SLOs.md .observe-ready/STATE.md; do [ -f "$extra" ] && files="$files $extra"; done
  # shellcheck disable=SC2086
  if cat $files | grep -Ei 'slo' | grep -Eq '[0-9]+(\.[0-9]+)? ?%|p9[059]|[0-9]+ ?ms'; then g_ok "SLOs carry numbers"; else g_fail "no numeric SLO"; fi
  # shellcheck disable=SC2086
  if cat $files | grep -Eiq 'error[- ]budget' && cat $files | grep -Eiq 'owner'; then g_ok "error-budget policy with an owner"; else g_fail "no owned error-budget policy (paper SLO)"; fi
  # shellcheck disable=SC2086
  if cat $files | grep -Eq 'installation-ready|operationally-mature'; then g_ok "evidence state recorded"; else g_fail "record installation-ready or operationally-mature evidence"; fi
  # shellcheck disable=SC2086
  if cat $files | grep -Ei 'runbook' | grep -Eiq 'executed|exercised|ran|drill|last_executed'; then g_ok "runbooks executed"; else g_warn "no evidence a runbook was executed"; fi
}

gate_launch() {
  f=$(tier_path 3.3)
  common_artifact_checks "$f" || return
  slop=$(grep -Eil 'empower|seamless|unleash|supercharge|revolutioni[sz]e|game[- ]chang|next[- ]level' .launch-ready/*.md 2>/dev/null | tr '\n' ' ')
  if [ -n "$slop" ]; then g_warn "hero-fatigue phrases in $slop(run the substitution test)"; fi
  if has "$f" 'utm_|source attribution|attribution|ref='; then g_ok "source attribution"; else g_warn "no source attribution (silent launch)"; fi
  g_ok "prepared is not published: run arc-check.sh prepublish immediately before any public release"
}

gate_harden() {
  f=$(tier_path 3.4)
  common_artifact_checks "$f" || return
  rows=$(parse_findings "$f")
  if [ -z "$rows" ]; then
    if findings_none_declared "$f"; then g_ok "findings: none (declared)"; else g_fail "no findings could be read; give each finding id:, severity:, and status: lines, or write findings: none"; fi
  fi
  dups=$(printf '%s\n' "$rows" | cut -f1 | tr 'A-Z' 'a-z' | sort | uniq -d | grep . | tr '\n' ' ')
  [ -z "$dups" ] || g_fail "duplicate finding ids: $dups"
  accepted_pairs=$(valid_acceptances)
  before=$GATE_FAILS
  n=0
  while IFS='	' read -r gh_id gh_sev gh_st gh_kind; do
    [ -n "$gh_id" ] || continue
    n=$((n + 1))
    [ "$gh_sev" = unknown ] && g_fail "$gh_id: severity could not be read"
    [ "$gh_st" = unknown ] && g_fail "$gh_id has no status"
    case "$gh_st" in
      accepted|risk-accepted)
        if ! printf '%s\n' "$accepted_pairs" | grep -Fqx -- "$(lower "$gh_id")|$gh_sev"; then
          g_fail "$gh_id is accepted, but no current acceptance was recorded with arc-check.sh accept (a person runs it at a terminal)"
        fi ;;
    esac
  done <<EOF
$rows
EOF
  if [ "$n" -gt 0 ] && [ "$GATE_FAILS" -eq "$before" ]; then g_ok "$n findings with severity and status"; fi
  unexplained=$(critical_mentions "$f" | head -5 | tr '\n' ' ')
  [ -z "$unexplained" ] || g_fail "Critical is mentioned outside a readable finding (line ${unexplained% }); give it id:, severity:, and status: lines, or write critical findings: none"
  cats=$(grep -Eo 'A(0[1-9]|10)(:20[0-9][0-9])?' "$f" | cut -c1-3 | sort -u | wc -l | tr -d ' ')
  if [ "$cats" -ge 10 ]; then g_ok "OWASP Top 10 verdicts for all categories"; else g_warn "OWASP verdicts cover $cats of 10 categories (required for web apps and APIs)"; fi
  if grep -Eiq 'reproduc' "$f" && grep -Eiq 'retest|re-test|verified' "$f"; then g_ok "findings carry reproduction and retest"; else g_warn "findings lack reproduction or retest steps"; fi
}

gate_ledger() {
  if [ ! -f "$LEDGER" ]; then g_fail "no ledger at $LEDGER"; return; fi
  gl_pairs=$(ledger_pairs)
  for gl_t in $WORK_TIERS; do
    gl_s=$(pair_status "$gl_pairs" "$gl_t")
    if [ -z "$gl_s" ]; then g_fail "tier $gl_t is not in the ledger (silence is not a status)"
    elif ! valid_status "$gl_s"; then g_fail "tier $gl_t has invalid status '$gl_s'"
    fi
  done
  gl_mode=$(arc_mode)
  case "$gl_mode" in a|b|c|d) g_ok "arc_mode $gl_mode" ;; *) g_fail "arc_mode is not set to A, B, C, or D" ;; esac
}

run_gate() {
  GATE_FAILS=0
  rg_t="$1"
  printf 'gate %s %s\n' "$rg_t" "$(tier_name "$rg_t")"
  case "$rg_t" in
    0) gate_ledger ;; 1.1) gate_prd ;; 1.2) gate_arch ;; 1.3) gate_roadmap ;; 1.4) gate_stack ;;
    2.1) gate_repo ;; 2.2) gate_build ;; 3.1) gate_deploy ;; 3.2) gate_observe ;;
    3.3) gate_launch ;; 3.4) gate_harden ;;
  esac
  if [ "$GATE_FAILS" -eq 0 ]; then echo "gate $rg_t: pass"; return 0; fi
  echo "gate $rg_t: fail ($GATE_FAILS)"
  return 1
}

# ---------- commands ----------

cmd_init() {
  mode=""; guided=false
  while [ $# -gt 0 ]; do
    case "$1" in
      --mode) [ $# -ge 2 ] || die "--mode needs A, B, C, or D"; mode=$(printf '%s' "$2" | tr 'a-z' 'A-Z'); shift ;;
      --guided) guided=true ;;
      *) die "unknown init argument: $1" ;;
    esac
    shift
  done
  case "$mode" in ""|A|B|C|D) ;; *) die "--mode must be A, B, C, or D" ;; esac
  if [ -e "$LEDGER" ] || [ -L "$LEDGER" ]; then die "ledger already exists at $LEDGER; run status" 1; fi
  safe_mkdir .arc-ready
  guard_write "$LEDGER"
  ts=$(now)
  {
    echo "# arc-ready PROGRESS"
    echo
    echo "skill_version: $ARC_CHECK_VERSION"
    echo "arc_mode: ${mode:-unset}"
    echo "created: $ts"
    echo "guided: $guided"
    echo "pillars: pending"
    echo "gate-launch-on-hardening: default"
    echo
    echo "## Intent"
    echo
    echo "Replace this line with the request in the user's words and the assumptions made. Record skips with arc-check.sh mark <tier> skipped --reason, not here."
    echo
    echo "## Tiers"
    echo
    for it in $TIERS; do
      if [ "$it" = 0 ]; then is=in-flight; iv="$ts"; else is=pending; iv=-; fi
      printf -- '- %s (%s): %s | artifact: %s | verified: %s\n' "$it" "$(tier_name "$it")" "$is" "$(tier_path "$it")" "$iv"
    done
    echo
    echo "## Risk acceptances"
    echo
    echo "Recorded only by a person running arc-check.sh accept at a terminal. Lines written or edited by hand are ignored."
    echo
    echo "## Log"
    echo
    echo "- $ts: ledger created"
  } > "$LEDGER" || die "could not write $LEDGER" 1
  echo "created $LEDGER (arc_mode: ${mode:-unset}, guided: $guided)"
  [ -n "$mode" ] || echo "set arc_mode to A, B, C, or D in the ledger before other work"
  for it in $WORK_TIERS; do
    art=$(artifact_for "$it") || continue
    [ -z "$(artifact_problem "$art")" ] || continue
    echo "import candidate: $it $(tier_name "$it") at $art (verify it, then: arc-check.sh mark $it imported)"
  done
  return 0
}

cmd_status() {
  if [ ! -f "$LEDGER" ]; then
    echo "no ledger at $LEDGER"
    for t in $WORK_TIERS; do
      art=$(artifact_for "$t") && echo "on disk: $t $(tier_name "$t") at $art"
    done
    echo "next: arc-check.sh init --mode <A|B|C|D>"
    exit 3
  fi
  pairs=$(ledger_pairs)
  mode=$(arc_mode)
  echo "arc-check $ARC_CHECK_VERSION status (arc_mode: $(printf '%s' "${mode:-unset}" | tr 'a-d' 'A-D'))"
  problems=0; next=""
  for t in $TIERS; do
    s=$(pair_status "$pairs" "$t")
    name=$(tier_name "$t")
    if [ -z "$s" ]; then
      if [ "$t" = 0 ]; then echo "[ok] 0 ARC (implied by the ledger)"; continue; fi
      echo "[missing] $t $name is not in the ledger (silence is not a status)"
      problems=$((problems + 1))
      [ -n "$next" ] || next="$t"
      continue
    fi
    if ! valid_status "$s"; then
      echo "[invalid] $t $name has status '$s'"
      problems=$((problems + 1))
      continue
    fi
    if [ "$t" = 0 ]; then echo "[ok] 0 ARC $s"; continue; fi
    art=$(artifact_for "$t" || true)
    case "$s" in
      done|imported)
        if [ -z "$art" ]; then
          echo "[drift] $t $name is $s but $(tier_path "$t") is missing. Fix: arc-check.sh mark $t pending"
          problems=$((problems + 1)); [ -n "$next" ] || next="$t"
        else
          prob=$(artifact_problem "$art")
          if [ -n "$prob" ]; then
            echo "[drift] $t $name is $s but $art is $prob. Fix: arc-check.sh mark $t pending"
            problems=$((problems + 1)); [ -n "$next" ] || next="$t"
          else
            echo "[ok] $t $name $s ($art)"
          fi
        fi ;;
      skipped) echo "[ok] $t $name skipped" ;;
      *)
        if [ "$s" = pending ] && [ -n "$art" ] && [ -z "$(artifact_problem "$art")" ]; then
          echo "[import?] $t $name is pending but $art exists. Verify it, then: arc-check.sh mark $t imported"
        else
          echo "[ ] $t $name $s"
        fi
        [ -n "$next" ] || next="$t" ;;
    esac
  done
  for t in $WORK_TIERS; do
    s=$(pair_status "$pairs" "$t")
    case "$s" in in-flight|done) ;; *) continue ;; esac
    [ "$(pair_override "$pairs" "$t")" = 1 ] && continue
    for u in $(tier_upstream "$t"); do
      us=$(pair_status "$pairs" "$u")
      if ! is_complete "$us"; then
        echo "[order] $t $(tier_name "$t") is $s while upstream $u $(tier_name "$u") is ${us:-missing}; finish it or record --override"
        problems=$((problems + 1))
      fi
    done
  done
  s33=$(pair_status "$pairs" 3.3); s34=$(pair_status "$pairs" 3.4)
  if [ -z "$next" ]; then
    echo "arc complete: every tier is done, imported, or skipped"
  elif [ "$next" = 3.3 ] || [ "$next" = 3.4 ]; then
    if ! is_complete "$s33" && ! is_complete "$s34"; then echo "next: 3.3 LAUNCH and 3.4 HARDEN (parallel; run prepublish before any public release)"
    else echo "next: $next $(tier_name "$next") (run prepublish before any public release)"; fi
  else
    echo "next: $next $(tier_name "$next")"
  fi
  if [ "$problems" -gt 0 ]; then echo "result: $problems problem(s); disk wins, fix the ledger first"; exit 1; fi
  echo "result: ledger matches disk"
  exit 0
}

cmd_mark() {
  [ -f "$LEDGER" ] || die "no ledger; run arc-check.sh init first" 3
  [ $# -ge 2 ] || die "usage: mark TIER STATUS [--reason TEXT] [--override TEXT]"
  t=$(normalize_tier "$1") || die "unknown tier: $1"
  s=$(lower "$2")
  valid_status "$s" || die "unknown status: $2 (use one of: $STATUSES)"
  shift 2
  reason=""; override=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --reason) [ $# -ge 2 ] || die "--reason needs text"; reason="$2"; shift ;;
      --override) [ $# -ge 2 ] || die "--override needs text"; override="$2"; shift ;;
      *) die "unknown mark argument: $1" ;;
    esac
    shift
  done
  check_text "$reason" "--reason"
  check_text "$override" "--override"
  name=$(tier_name "$t")
  path=$(tier_path "$t")
  verified=-
  [ -n "$override" ] || override=$(tier_line_field "$t" override)
  if [ "$s" = in-flight ] || [ "$s" = done ]; then
    pairs=$(ledger_pairs)
    missing=""
    for u in $(tier_upstream "$t"); do
      is_complete "$(pair_status "$pairs" "$u")" || missing="$missing $u $(tier_name "$u");"
    done
    if [ -n "$missing" ] && [ -z "$override" ]; then
      die "refused: upstream not complete:$missing finish it, mark it imported or skipped, or pass --override \"reason\"" 1
    fi
  fi
  case "$s" in
    skipped)
      [ -n "$reason" ] || die "refused: skipped needs --reason (silence is not a skip)" 1 ;;
    imported)
      art=$(artifact_for "$t") || die "refused: nothing to import at $path" 1
      prob=$(artifact_problem "$art")
      [ -z "$prob" ] || die "refused: $art is $prob" 1
      path="$art"; verified=$(now) ;;
    done)
      if [ "$t" = 0 ]; then
        pairs=$(ledger_pairs)
        for w in $WORK_TIERS; do
          is_complete "$(pair_status "$pairs" "$w")" || die "refused: tier 0 is done only after every tier is done, imported, or skipped ($w is not)" 1
        done
      fi
      out=$(run_gate "$t")
      gate_code=$?
      printf '%s\n' "$out"
      if [ "$gate_code" -ne 0 ]; then
        die "refused: $t $name gate failed; fix the artifact, then mark done again" 1
      fi
      art=$(artifact_for "$t" || true)
      [ -n "$art" ] && path="$art"
      verified=$(now) ;;
  esac
  line="- $t ($name): $s | artifact: $path | verified: $verified"
  [ -n "$reason" ] && line="$line | reason: $reason"
  [ -n "$override" ] && line="$line | override: $override"
  write_tier_line "$t" "$line"
  note="$t $name $s"
  [ -n "$reason" ] && note="$note (reason: $reason)"
  [ -n "$override" ] && note="$note (override: $override)"
  log_event "$note"
  echo "recorded: $line"
}

cmd_gate() {
  [ $# -ge 1 ] || die "usage: gate TIER"
  t=$(normalize_tier "$1") || die "unknown tier: $1"
  run_gate "$t"
  exit $?
}

cmd_scan() {
  echo "scan: placeholders and fake data in shipped source"
  run_scan "$@"
  code=$?
  [ "$code" -eq 2 ] && exit 0
  exit "$code"
}

cmd_pillars() {
  pname=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --name) [ $# -ge 2 ] || die "--name needs text"; pname="$2"; shift ;;
      *) die "unknown pillars argument: $1" ;;
    esac
    shift
  done
  [ -n "$pname" ] || pname=$(basename "$ROOT")
  state=adopted
  if [ -e AGENTS.md ] || [ -L AGENTS.md ]; then
    if [ -f AGENTS.md ] && grep -qi 'pillars' AGENTS.md; then
      echo "[ok] AGENTS.md is already Pillars-compatible; left unchanged"
    else
      echo "[blocked] AGENTS.md exists and is not Pillars-compatible; left unchanged"
      state=adoption-blocked-existing-agents
    fi
  else
    guard_write AGENTS.md
    cat > AGENTS.md <<EOF || die "could not write AGENTS.md" 1
# $pname

This project follows the [Pillars](https://github.com/hannsxpeter/pillars) standard. Coding agents read the pillar files in \`./agents/*.md\` to stay aligned with the project's facts, decisions, and conventions.

## At the start of any task

1. Load every file in \`./agents/\` whose frontmatter has \`always_load: true\`.
2. Scan the frontmatter of the remaining pillars.
3. Load the pillars whose \`triggers\` or \`covers\` match the task, plus their \`must_read_with\` list (one level deep).
4. Consult \`see_also\` only when the task touches that area.
5. Follow Rules, apply Workflows, heed Watchouts, and ask about Gaps.

| Pillar state | Action |
|---|---|
| \`status: present\` | Load and comply. |
| \`status: stub\` | Ask before deciding anything in this area. |
| Listed in \`excluded:\` | Treat as intentionally not applicable. |

\`\`\`yaml
excluded: []
\`\`\`

## arc-ready artifacts

Planning, build, ship, and hardening decisions live in the arc-ready artifacts. Consult them before changing the related area. Tier status lives in \`.arc-ready/PROGRESS.md\`.

| Tier | Artifact |
|---|---|
| PRD | \`.prd-ready/PRD.md\` |
| Architecture | \`.architecture-ready/ARCH.md\` |
| Roadmap | \`.roadmap-ready/ROADMAP.md\` |
| Stack | \`.stack-ready/STACK.md\` |
| Build state | \`.production-ready/STATE.md\` |
| Deploy | \`.deploy-ready/DEPLOY.md\` |
| Observe | \`.observe-ready/OBSERVE.md\` |
| Launch | \`.launch-ready/STATE.md\` |
| Hardening | \`.harden-ready/FINDINGS.md\` |
EOF
    echo "[wrote] AGENTS.md (Pillars loader and arc-ready artifact map)"
  fi
  if [ "$state" = adopted ]; then
    if [ -e CLAUDE.md ] || [ -L CLAUDE.md ]; then
      :
    else
      ln -s AGENTS.md CLAUDE.md && echo "[wrote] CLAUDE.md -> AGENTS.md"
    fi
    if [ -L agents ]; then
      echo "[blocked] agents/ is a symlink; left unchanged"
      state=adoption-blocked-existing-agents
    else
      safe_mkdir agents
      for pillar in context repo; do
        if [ -e "agents/$pillar.md" ] || [ -L "agents/$pillar.md" ]; then echo "[ok] agents/$pillar.md exists; left unchanged"; continue; fi
        if [ "$pillar" = context ]; then
          covers="project identity, domain language, product invariants, glossary"; other=repo
          source=".prd-ready/PRD.md"
        else
          covers="file layout, naming conventions, where things go, repository structure"; other=context
          source=".repo-ready/SCAFFOLD.md and README.md"
        fi
        guard_write "agents/$pillar.md"
        cat > "agents/$pillar.md" <<EOF || die "could not write agents/$pillar.md" 1
---
pillar: $pillar
status: stub
always_load: true
covers: [$covers]
triggers: []
must_read_with: []
see_also: [$other]
---

## Scope

$covers. Fill from $source and cite the source path for each non-obvious claim.

## Context

## Decisions

## Rules

## Workflows

## Watchouts

## Touchpoints

- see_also: [$other]

## Gaps

- This pillar is a stub. Ask before inventing facts in this area.
EOF
        echo "[wrote] agents/$pillar.md (status: stub)"
      done
    fi
  fi
  if [ -f "$LEDGER" ]; then
    set_ledger_field pillars "$state"
    log_event "pillars: $state"
    echo "[ledger] pillars: $state"
  fi
  return 0
}

cmd_accept() {
  [ -f "$LEDGER" ] || die "no ledger; run arc-check.sh init first" 3
  [ -f "$FINDINGS" ] || die "no findings at $FINDINGS" 1
  [ $# -ge 1 ] || die "usage: accept FINDING --owner NAME --expires YYYY-MM-DD --justification TEXT"
  want="$1"; shift
  owner=""; expd=""; just=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --owner) [ $# -ge 2 ] || die "--owner needs a name"; owner="$2"; shift ;;
      --expires) [ $# -ge 2 ] || die "--expires needs a date"; expd="$2"; shift ;;
      --justification) [ $# -ge 2 ] || die "--justification needs text"; just="$2"; shift ;;
      *) die "unknown accept argument: $1" ;;
    esac
    shift
  done
  [ -n "$owner" ] && [ -n "$expd" ] && [ -n "$just" ] || die "accept needs --owner, --expires, and --justification"
  check_text "$owner" "--owner"
  check_text "$just" "--justification"
  valid_date "$expd" || die "--expires must be a real date in YYYY-MM-DD form"
  [ "$(printf '%s\n%s\n' "$(today)" "$expd" | sort | tail -1)" = "$expd" ] || die "--expires is in the past" 1
  matches=$(parse_findings "$FINDINGS" | AC_ID="$(lower "$want")" awk -F'\t' 'tolower($1) == ENVIRON["AC_ID"]')
  [ -n "$matches" ] || die "no finding with id $want in $FINDINGS" 1
  [ "$(printf '%s\n' "$matches" | wc -l | tr -d ' ')" -eq 1 ] || die "refused: $want names more than one finding; give each finding its own id: line" 1
  id=$(printf '%s\n' "$matches" | cut -f1)
  sev=$(printf '%s\n' "$matches" | cut -f2)
  kind=$(printf '%s\n' "$matches" | cut -f4)
  [ "$kind" != generated ] || die "refused: give this finding an explicit id: line first" 1
  [ "$sev" != unknown ] || die "refused: $id has a severity arc-check cannot read" 1
  if [ "$sev" = critical ] && policy_is_hard; then
    die "refused: gate-launch-on-hardening is hard, so Critical findings cannot be accepted" 1
  fi
  if [ ! -t 0 ]; then
    die "refused: accept needs a person at an interactive terminal. An agent must not record risk acceptances: report the finding and what its owner must do, then stop." 1
  fi
  printf 'Accept the risk of %s (%s), owned by %s, until %s?\nType %s to confirm: ' "$id" "$sev" "$owner" "$expd" "$id"
  read -r answer
  answer=$(printf '%s' "$answer" | tr -d '\r')
  [ "$answer" = "$id" ] || die "not confirmed; nothing recorded" 1
  acc=$(today)
  line="- finding: $id | severity: $sev | owner: $owner | accepted: $acc | expires: $expd | justification: $just | check: $(acceptance_check "$id" "$sev" "$owner" "$acc" "$expd" "$just")"
  guard_write "$LEDGER"
  tmp="$LEDGER.tmp.$$"
  AL_LINE="$line" awk '
    BEGIN { state = 0 }
    state == 0 && /^## Risk acceptances/ { print; state = 1; next }
    state == 1 && /^## / { print ENVIRON["AL_LINE"]; print ""; state = 2 }
    { print }
    END {
      if (state == 1) print ENVIRON["AL_LINE"]
      if (state == 0) { print ""; print "## Risk acceptances"; print ""; print ENVIRON["AL_LINE"] }
    }' "$LEDGER" > "$tmp" && mv "$tmp" "$LEDGER" || die "could not update $LEDGER" 1
  log_event "accept: $id ($sev) owned by $owner until $expd"
  echo "recorded: $line"
}

cmd_prepublish() {
  evaluate_prepublish
  if [ "${1:-}" = "--verify" ]; then
    if [ ! -f "$PREPUB" ]; then echo "[block] no pre-publication record; run arc-check.sh prepublish"; exit 1; fi
    rverdict=$(sed -n 's/^verdict:[[:space:]]*//p' "$PREPUB" | head -1)
    rrev=$(sed -n 's/^hardening_revision:[[:space:]]*//p' "$PREPUB" | head -1)
    if [ "$rrev" != "$PP_REV" ]; then
      echo "[block] pre-publication record is stale: the findings, acceptances, or policy changed since it was written (recorded $rrev, current $PP_REV). Run arc-check.sh prepublish again."
      exit 1
    fi
    if [ "$rverdict" != pass ] || [ "$PP_VERDICT" != pass ]; then
      echo "[block] the pre-publication gate does not pass:"
      printf '%s' "$PP_REASONS" | sed 's/^/  /'
      exit 1
    fi
    echo "[ok] pre-publication record is current and passing ($PP_REV)"
    exit 0
  fi
  safe_mkdir .launch-ready
  guard_write "$PREPUB"
  {
    echo "# Pre-publication gate"
    echo
    echo "checked_at: $(now)"
    echo "hardening_revision: $PP_REV"
    echo "findings_file: $FINDINGS"
    echo "policy: $PP_POLICY"
    echo "critical_total: $PP_TOTAL"
    echo "critical_accepted: $PP_ACCEPTED"
    echo "critical_unresolved: $PP_UNRESOLVED"
    echo "verdict: $PP_VERDICT"
    echo
    echo "## Reasons"
    echo
    if [ -n "$PP_REASONS" ]; then printf '%s' "$PP_REASONS"; else echo "- no unresolved Critical findings"; fi
    echo
    echo "Any change to the findings, the hardening state, the risk acceptances, or the policy invalidates this record. Re-run arc-check.sh prepublish before publishing."
  } > "$PREPUB" || die "could not write $PREPUB" 1
  printf '%s' "$PP_REASONS" | sed 's/^/  /'
  if [ "$PP_VERDICT" = block ]; then
    echo "  Do not publish. Only the risk owner can accept a Critical finding, by running arc-check.sh accept at a terminal."
    echo "  Do not write or edit a risk acceptance yourself. Report each finding and what its owner must do, then stop."
  fi
  if [ -f "$LEDGER" ]; then log_event "prepublish: $PP_VERDICT (critical unresolved $PP_UNRESOLVED, accepted $PP_ACCEPTED, $PP_REV)"; fi
  echo "prepublish: $PP_VERDICT (critical unresolved: $PP_UNRESOLVED, accepted: $PP_ACCEPTED) -> $PREPUB"
  [ "$PP_VERDICT" = pass ] && exit 0
  exit 1
}

# ---------- main ----------

if [ "${1:-}" = "-C" ]; then
  [ $# -ge 2 ] || die "-C needs a directory"
  cd "$2" || die "cannot enter $2"
  shift 2
fi
ROOT=$(pwd -P)
[ "$ROOT" = / ] && ROOT=""

cmd="${1:-}"
[ -n "$cmd" ] || { usage; exit 2; }
shift
case "$cmd" in
  init) cmd_init "$@" ;;
  status) cmd_status ;;
  mark) cmd_mark "$@" ;;
  gate) cmd_gate "$@" ;;
  pillars) cmd_pillars "$@" ;;
  prepublish) cmd_prepublish "$@" ;;
  accept) cmd_accept "$@" ;;
  scan) cmd_scan "$@" ;;
  version|--version) echo "arc-check $ARC_CHECK_VERSION" ;;
  -h|--help|help) usage ;;
  *) usage >&2; exit 2 ;;
esac
