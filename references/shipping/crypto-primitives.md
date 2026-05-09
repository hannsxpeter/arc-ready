# crypto-primitives: primitive selection, key management, IV discipline, PQ posture

Loaded at Tier 2 (Step 6). Net-new to the ready-suite; production-ready does not cover cryptographic primitive selection at this depth. The canonical reference is Latacora's "Cryptographic Right Answers" (2018) and "Cryptographic Right Answers PQ Edition" (2024), plus Aumasson's *Serious Cryptography* (2nd ed, No Starch 2024).

The load-bearing rule: **use AEAD, use the library's high-level API, never roll your own, verify against Latacora Right Answers**.

## The Right Answers cheat sheet (distilled)

Referenced: [Latacora: Cryptographic Right Answers 2018](https://www.latacora.com/blog/2018/04/03/cryptographic-right-answers/), [Latacora: Cryptographic Right Answers PQ Edition 2024](https://www.latacora.com/blog/2024/07/29/crypto-right-answers-pq/).

| Use case | Use | Avoid |
|---|---|---|
| Symmetric encryption of arbitrary data | AES-GCM or ChaCha20-Poly1305 via an AEAD API | CBC + HMAC, ECB, any "simple" encryption mode |
| Symmetric encryption where nonce uniqueness is hard | XChaCha20-Poly1305 (libsodium) | AES-GCM with random 96-bit nonces across many messages |
| Encrypt a short file / message | libsodium `secretbox` or equivalent | Hand-rolled IV-management |
| Password hashing | Argon2id (19 MiB, t=2, p=1) or scrypt | bcrypt for new systems; MD5, SHA-1, SHA-256, unsalted anything |
| Key derivation from a password | Argon2id; or scrypt | PBKDF2 with fewer than 600,000 iterations (SHA-256) |
| HKDF for key derivation from a high-entropy source | HKDF-SHA-256 | Home-grown construction |
| MAC | HMAC-SHA-256 with `timingSafeEqual` | MD5-HMAC; string equality on HMAC output |
| Signing | Ed25519 | ECDSA without RFC 6979 determinism; RSA-PKCS1-v1.5 for new systems |
| Signing (when Ed25519 not possible) | ECDSA P-256 with RFC 6979 deterministic; or RSA-PSS 3072+ | ECDSA with random nonces; RSA-PKCS1-v1.5 |
| Signing (FIPS context) | FIPS 186-5: Ed25519 (since 2023), ECDSA P-256/P-384 | RSA-PKCS1-v1.5 for new signatures |
| Asymmetric encryption | X25519 (ECDH) then AEAD (hybrid public-key encryption) | RSA-OAEP (fine but less common); RSA-PKCS1-v1.5 encryption (broken) |
| Nonce / IV generation | AEAD-specific: counter with domain separation, OR random with library-safety margin (Xchacha20 yes, AES-GCM no for high message volume) | User-controlled IVs; same IV across messages |
| Random numbers for security | `crypto.randomBytes` / `SecureRandom` / `os.urandom` | `Math.random` / `rand()` |
| TLS | 1.3 preferred; 1.2 minimum; HSTS with preload where appropriate | TLS 1.0/1.1, weak cipher suites, self-signed for production |
| Public-key encryption / hybrid (2024) | X25519 + ML-KEM-768 hybrid KEM | Pure ML-KEM without hybrid (yet); RSA-KEM |

## AEAD versus raw encryption

**AEAD** (Authenticated Encryption with Associated Data) combines confidentiality and integrity in a single primitive. Raw encryption without integrity is catastrophically broken in adversarial settings (padding oracle, chosen-ciphertext). Latacora: "Use AEAD or nothing."

Two concrete primitives dominate:

- **AES-GCM.** Hardware-accelerated on AES-NI (most x86 since Ivy Bridge, ARMv8+). Nonce reuse is **catastrophic**: leaks the authentication key, permits universal forgery of subsequent messages under the same key.
- **ChaCha20-Poly1305.** Software-fast on all platforms. Nonce reuse is still **catastrophic** (leaks plaintext in known-plaintext case), but the forgery class is narrower than AES-GCM.
- **XChaCha20-Poly1305.** Extended 192-bit nonce. Safe to generate randomly; collision probability is negligible even at extreme message volume. Recommended where the library supports it (libsodium, Rust `chacha20poly1305` crate, Go `chacha20poly1305`, Python `cryptography`).

References: [Wikipedia: ChaCha20-Poly1305](https://en.wikipedia.org/wiki/ChaCha20-Poly1305), [IACR eprint 2023/085: ChaCha20-Poly1305 multi-user security](https://eprint.iacr.org/2023/085.pdf), [Soatok: Understanding extended-nonce constructions](https://soatok.blog/2021/03/12/understanding-extended-nonce-constructions/).

### Nonce / IV reuse catastrophes

The single most common crypto-bug class in audit. Real production examples: multiple OpenSSL CVEs, Sony PS3's ECDSA signing key leak (nonce reuse, not AEAD, but same class).

**Safe patterns.**

- **Counter-based nonces.** Maintain a monotonically-increasing counter per key; write counter to durable storage; never decrement. Suitable when the encryptor is a single process with durable state.
- **Random nonces under XChaCha20-Poly1305.** 192-bit random nonce has collision probability 2^-96 at 2^48 messages; safe at any realistic scale.
- **Random nonces under AES-GCM with a message-count limit.** 96-bit random nonce has collision probability 2^-32 at 2^32 messages; acceptable up to ~2^24 messages per key (birthday bound). Beyond that, rotate the key.

**Unsafe patterns.**

- **User-controlled IVs.** The caller picks the nonce; attacker picks a colliding one. Fails immediately.
- **Sequential counters without durable state.** A restart resets the counter; two messages under the same key+nonce.
- **Timestamp nonces.** Two messages within the same millisecond collide.

### Test

Inventory every encryption call-site. For each:

```
# Grep for the primitive
grep -rn "createCipheriv\|createDecipheriv" src/    # Node.js
grep -rn "AES\.\|Cipher\|PKCS" src/                  # Java
grep -rn "encrypt\|decrypt\|nacl" src/               # Python, Go, Rust
grep -rn "crypto::"  src/                            # Rust

# For each hit, answer:
# 1. What is the primitive? (GCM, ChaCha20-Poly1305, CBC, ECB)
# 2. What is the nonce source?
# 3. Is nonce reuse possible under any restart, race, or user-controlled path?
# 4. Is the library's high-level API used, or is the caller managing IV/nonce?
```

**Pass condition.** Every encryption uses AEAD; every nonce is either counter-based with durable state, random under XChaCha20-Poly1305, or random under AES-GCM with volume in the safe range.

## Password hashing: Argon2id as default

**OWASP 2024 current guidance** (Password Storage Cheat Sheet): Argon2id with 19 MiB memory, 2 iterations, 1 parallelism. [OWASP Password Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html).

Preference order:

1. **Argon2id.** Best. Memory-hard, resistant to GPU/ASIC attacks.
2. **scrypt.** Good. Memory-hard, older than Argon2id.
3. **bcrypt.** Acceptable for legacy. Cost >= 10. Note: bcrypt truncates passwords at 72 bytes; this matters if users can set long passphrases. Not the default for new systems.
4. **PBKDF2.** Only when FIPS 140 compliance is required. SHA-256 with 600,000+ iterations (OWASP 2023 update).

**Do not use.** MD5, SHA-1, SHA-256 as password hash, plaintext, any "encryption" of passwords (passwords are hashed, not encrypted; the difference matters).

### Test

Find the password-hashing call site. Verify the primitive and parameters.

```
# Node.js: argon2 library
grep -rn "argon2\|argon\.hash\|argon2id" src/
# Verify: hash({..., type: argon2.argon2id, memoryCost: 19456, timeCost: 2, parallelism: 1})

# Python: argon2-cffi
grep -rn "PasswordHasher\|argon2\." src/
# Verify PasswordHasher(time_cost=2, memory_cost=19456, parallelism=1)

# If bcrypt is used, verify cost
grep -rn "bcrypt\.hash\|bcrypt\.gensalt" src/
# Verify cost >= 12

# Anti-pattern search
grep -rn "createHash.*sha256\|sha1\|md5" src/ | grep -i password
# Any hits are findings.
```

**Pass condition.** Password hashing uses Argon2id (preferred) or scrypt/bcrypt with appropriate cost. No SHA-family hash alone. No unsalted hash.

## Signature schemes

References: [NIST FIPS 186-5 PDF](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.186-5.pdf), [WorkOS: HMAC vs RSA vs ECDSA for JWT signing](https://workos.com/blog/hmac-vs-rsa-vs-ecdsa-which-algorithm-should-you-use-to-sign-jwts), [Scott Brady: JWT signing algorithm choice](https://www.scottbrady.io/jose/jwts-which-signing-algorithm-should-i-use), [Wikipedia: EdDSA](https://en.wikipedia.org/wiki/EdDSA).

### Ed25519 is the default

- Deterministic: no nonce-leakage class of bug (unlike ECDSA).
- Fast on all platforms.
- Compact: 32-byte keys, 64-byte signatures.
- Side-channel resistant by design.
- FIPS 186-5 approved since 2023.

**Use Ed25519 unless there is a FIPS-pre-2023 compliance reason or a legacy ecosystem constraint.**

### ECDSA: only with deterministic nonces (RFC 6979)

ECDSA requires a per-signature nonce; if the nonce repeats under the same key, the private key can be recovered. Real production breaches: Sony PS3 (2010, recovered Sony's signing key), multiple Bitcoin wallet exposures.

**Defense.** RFC 6979: derive the nonce deterministically from the private key and message. Every modern ECDSA library supports this; verify your library uses it.

**Curves.** P-256 (NIST), P-384 (NIST). Consumer apps: P-256. Higher-assurance: P-384.

### RSA: only when required

RSA is older, larger, slower. Modern apps use Ed25519 by default; RSA is fine when required by an ecosystem (some SAML providers, some JWT ecosystems).

- **RSA-PSS.** The correct padding for signing. Not PKCS1-v1.5 for new signatures (PKCS1-v1.5 is still acceptable for verification of legacy signatures, but do not use it for new signing).
- **Key size.** 3072-bit minimum for new keys; 2048-bit acceptable for legacy. Do not accept or generate keys below 2048-bit.

### Test

```
# Identify every signature call-site
grep -rn "sign\|verify\|ed25519\|ecdsa\|rsa\.sign" src/

# For each:
# - Algorithm: Ed25519, ECDSA (with RFC 6979?), or RSA (PSS?)?
# - Key size if RSA: 3072+?
# - Is verification using constant-time comparison on the output? (timingSafeEqual, not ===)
```

## TLS configuration

- **Minimum TLS 1.2.** TLS 1.0 and 1.1 are disabled by default on modern runtimes; verify.
- **Preferred TLS 1.3.** Faster handshake, mandatory AEAD, removed legacy ciphers.
- **Cipher suite allowlist.** Mozilla SSL Configuration Generator (modern profile) as starting point. Reject RC4, 3DES, MD5-based suites, export ciphers.
- **HSTS.** `Strict-Transport-Security: max-age=31536000; includeSubDomains; preload` for production. Add domain to HSTS preload list.
- **HSTS preload pitfall.** Once preloaded, removal takes months. Verify the domain and all subdomains are HTTPS-only before preloading.
- **OCSP stapling.** Reduces CA-lookup latency; preserves client privacy.
- **Certificate pinning.** For mobile apps, pin the intermediate or root CA; do not pin the leaf. For browsers, do not pin (HPKP is deprecated).
- **SNI.** Always use SNI in 2026; non-SNI is legacy client territory.

### Test

```
# SSL Labs
# https://www.ssllabs.com/ssltest/analyze.html?d=app.example.com

# testssl.sh (localinstall)
./testssl.sh https://app.example.com

# Verify
# - Minimum TLS: 1.2
# - Preferred: 1.3
# - HSTS: max-age >= 1 year, includeSubDomains
# - No weak ciphers: no RC4, 3DES, export, DES-CBC
# - Certificate: valid chain, SAN covers the domain
```

**Pass condition.** SSL Labs Grade A or A+. HSTS present with max-age >= 1 year.

## Key management

### Never in source

Hardcoded keys in source code are the most common finding across audits. Grep the codebase for key-shaped patterns (high-entropy strings, Base64 blocks).

```
# Generic
git log -p | grep -E "AKIA[A-Z0-9]{16}|[A-Za-z0-9+/]{40,}={0,2}" | head
# AWS-specific
# GitGuardian, TruffleHog in CI catch most of this.
```

### Where keys go

- **KMS for key encryption keys (KEK).** AWS KMS, GCP Cloud KMS, Azure Key Vault, HashiCorp Vault. The KEK encrypts data encryption keys (DEK).
- **Envelope encryption.** DEK is generated fresh per data unit; KEK (in KMS) encrypts the DEK; the encrypted DEK is stored with the data. Decryption: fetch encrypted DEK, KMS-decrypt to get plaintext DEK, decrypt data with DEK.
- **Rotation.** KEK rotation in KMS is a one-liner; DEK rotation requires re-encrypting data (possible without key access if DEK is the only thing re-encrypted).

### Key rotation cadence

- **API keys to third parties.** Annual at minimum; on suspected compromise immediately.
- **Database credentials.** Quarterly or on-personnel-change for shared credentials; per-user credentials can have longer life.
- **TLS certificates.** Automated via ACME (Let's Encrypt, ZeroSSL); 90-day or shorter is now standard.
- **JWT signing keys.** Annual with overlap period for un-expired tokens; key rotation is the reason multiple `kid` values are supported.
- **HMAC secrets for webhooks.** Annual; rotation coordinated with the partner.
- **Encryption keys (KEK).** Annual; KMS automates; re-encryption of DEKs is opportunistic.

### Test

```
# Inventory every key / secret
grep -rn "KEY\|SECRET\|TOKEN" .env* config/
# Verify each is in KMS or vault, not in .env

# Key rotation
# For each credential: when was it last rotated? Can the engineer answer?
```

## Post-quantum posture (CNSA 2.0)

The NSA's Commercial National Security Algorithm Suite 2.0 mandates post-quantum algorithms for US National Security Systems.

**Timeline.** [NSA CNSA 2.0 algorithms PDF](https://media.defense.gov/2025/May/30/2003728741/-1/-1/0/CSA_CNSA_2.0_ALGORITHMS.PDF), [Post-Quantum: CNSA 2.0 PQC requirements](https://www.qusecure.com/cnsa-2-0-pqc-requirements-timelines-federal-impact/).

| Year | Requirement |
|---|---|
| 2025 | Preferred for code/firmware signing (CNSA 2.0). |
| 2027 | All new NSS systems must follow CNSA 2.0. |
| 2030 | Mandatory for code/firmware signing. |
| 2033 | Full adoption for web/cloud communications. |
| 2035 | Full adoption across NSS. |

**Approved algorithms.**

- **AES-256** (symmetric, PQ-safe at this key size).
- **SHA-384** (hash, PQ-safe).
- **CRYSTALS-Kyber (ML-KEM).** Key encapsulation. Hybrid with X25519 or P-256 for near-term deployment.
- **CRYSTALS-Dilithium (ML-DSA).** Digital signature.

### Latacora's 2024 post-quantum recommendations

- **Hybrid key exchange.** X25519 + ML-KEM-768 (or P-256 + ML-KEM-768 for FIPS contexts).
- **Symmetric encryption.** XSalsa20+Poly1305 (or AES-256-GCM for hardware acceleration).
- **256-bit keys throughout.** 128-bit is becoming insufficient under PQ adversaries.

### Practical posture for most apps

Most apps do not need to be PQ-ready today. The minimum:

- **Be crypto-agile.** Primitives should be swappable by configuration, not hardcoded. A three-year-from-now migration should be a config change plus re-encryption pass.
- **Monitor CNSA 2.0 timeline** if you sell to US federal government.
- **Plan for hybrid KEM in the 2027-2030 window** for non-federal orgs; 2025 for federal.
- **Avoid harvest-now-decrypt-later exposure** for data that must be confidential beyond 2033. This is the primary PQ-driven action for most orgs: what data, encrypted under pre-PQ primitives today, must still be confidential in 2033+? That data is the priority for PQ re-encryption.

**Pass condition for 2026.** Crypto-agility documented. PQ-migration plan noted. No urgent action required for most apps; noted explicitly.

## Constant-time comparison

Every MAC comparison, every signature comparison, every password-hash comparison, every token comparison must use constant-time equality.

```javascript
// unsafe
if (providedSig === expectedSig) { ... }

// safe
if (crypto.timingSafeEqual(
  Buffer.from(providedSig, 'hex'),
  Buffer.from(expectedSig, 'hex')
)) { ... }
```

**Test.** Grep for every comparison of cryptographic output against `===`, `==`, `.equals()`, or string equality:

```
grep -rn "sig ==\|sig ===\|token ==\|token ===\|hash ==\|hash ===\|mac ==\|mac ===" src/
```

Any hit is a finding.

## The `.harden-ready/CRYPTO-VERIFICATION.md` artifact

Record every primitive in use and the audit result:

```markdown
## Symmetric encryption
- Primitive: AES-256-GCM
- Library: Node.js `crypto` module
- Mode: via `createCipheriv` with 96-bit random IV
- Message volume per key: <100K messages per key, well within birthday bound
- Key rotation: annual via KMS
- Status: Pass

## Password hashing
- Primitive: Argon2id
- Library: `argon2` (Node.js) v0.30.3
- Parameters: memoryCost: 19456, timeCost: 2, parallelism: 1
- Legacy migration: bcrypt hashes are re-hashed to Argon2id on next login
- Status: Pass

## Signature / JWT
- Primitive: RS256 (RSA 2048)
- Library: `jsonwebtoken` v9.0.2
- Key storage: private key in AWS KMS; public key distributed via JWKS
- Rotation: annual with overlap
- Status: Medium finding F-12 (RSA 2048 preferred upgrade to RSA 3072 or Ed25519 within 12 months)

## Random number generation
- Primitive: `crypto.randomBytes` (Node.js)
- Math.random() usage for security: none found
- Status: Pass

## TLS
- SSL Labs grade: A+
- Minimum version: TLS 1.2
- Preferred: TLS 1.3
- HSTS: max-age 63072000, includeSubDomains, preload (enrolled)
- Status: Pass

## Key management
- KMS: AWS KMS
- Keys in env files: 0 (verified via GitGuardian scan)
- Envelope encryption: Yes (DEK per tenant, KEK in KMS)
- Rotation cadence: Documented in .harden-ready/CADENCE.md
- Status: Pass

## Constant-time comparison
- HMAC: `crypto.timingSafeEqual`
- Webhook sig: `crypto.timingSafeEqual`
- Token compare: `crypto.timingSafeEqual`
- Search for `===` on crypto output: 0 hits
- Status: Pass

## Post-quantum posture
- Crypto-agility: Yes; primitives in config
- PQ migration plan: revisit 2028 per Latacora guidance
- Harvest-now-decrypt-later: low risk for this app; no data required confidential beyond 5 years
- Status: Pass with note
```

Every Fail or note rolls into a finding.
