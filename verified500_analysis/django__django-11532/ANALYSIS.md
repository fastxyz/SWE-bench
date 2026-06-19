# django__django-11532 — FVK analysis

- **Verdict:** D_EQUIVALENT (leans F) — baseline already fixed the real bug the same way the human gold fix did; fvk's extra line is a redundant no-op in real runtime that only changes behavior inside the issue author's monkey-patch artifact, and gold never made it.
- **Pitch-worthiness (1-5):** 1 — this is NOT a "passed tests but still wrong" case; baseline was correct, so there is no honest distinguishing demo on any real input.

## The issue
When the machine's hostname is non-ASCII (e.g. `正宗` / `漢字`) and an email uses a non-Unicode encoding like `iso-8859-1`, Django's auto-generated `Message-ID` header contained the raw Unicode hostname. Encoding that header then raised `UnicodeEncodeError` (`'latin-1' codec can't encode...`). The fix: convert the hostname to IDNA/punycode (e.g. `漢字` → `xn--p8s937b`) before it reaches the header.

## What baseline did
Baseline fixed it at the source: in `django/core/mail/utils.py`, `CachedDnsName.get_fqdn()` now ASCII-checks the freshly read `socket.getfqdn()` and, on failure, converts it via `self._fqdn.encode('idna').decode('ascii')` before caching. Since every real consumer (`make_msgid(domain=DNS_NAME)`, SMTP `local_hostname`, etc.) reads the hostname through this cached object, they all get an ASCII-safe value. This is exactly where the official test exercises the code.

## What fvk changed and why
fvk kept baseline's `utils.py` fix but (a) refactored it into a shared `punycode(domain)` helper in `utils.py`, and (b) **additionally** changed `django/core/mail/message.py` line 260 from `make_msgid(domain=DNS_NAME)` to `make_msgid(domain=punycode(DNS_NAME))`. fvk's `fvk_FINDINGS.md` F1 claims baseline "missed the direct `DNS_NAME` substitution path" — i.e. a scenario where `DNS_NAME` is itself a raw Unicode string at the `message.py` use-site. That scenario only exists when `DNS_NAME` is monkey-patched (as in the issue's repro snippet); it cannot occur in normal runtime, where `DNS_NAME` is always a `CachedDnsName` object whose `__str__`/`get_fqdn` already punycode.

## Concrete demonstration
There is **no real input** that distinguishes baseline from fvk. Verified with stdlib (`socket`, `email.utils.make_msgid`, `email.header.Header`), reconstructing `CachedDnsName` from patch context:

- **Realistic runtime (`socket.getfqdn()` → `'正宗'`, `DNS_NAME` = the object):**
  baseline `make_msgid(domain=DNS_NAME)` → `<...@xn--jbt908a>`, header encodes OK under `iso-8859-1`. **Baseline does NOT crash.** Identical to fvk. (`get_fqdn()` punycodes before caching; `make_msgid` stringifies the object.)
- **Official test path** (`delattr(DNS_NAME, '_fqdn')` + mock `socket.getfqdn` → `'漢字'`): both baseline and fvk yield `@xn--p8s937b>` and pass.
- **Common ASCII host** (`mail.example.com`): byte-identical domain; both fine.
- **Only diverging case — the issue's mock artifact** (`patch("...message.DNS_NAME", "漢字")`, replacing the object with a raw string, bypassing `CachedDnsName`): baseline `make_msgid(domain="漢字")` → `<...@漢字>` → `UnicodeEncodeError`; fvk's `punycode(DNS_NAME)` → `@xn--p8s937b` → OK. This input never arises outside `unittest.mock`.

fvk's extra call is also harmless (idempotent: `punycode('xn--p8s937b') == 'xn--p8s937b'`; ASCII passthrough), so it is not a regression — just dead weight.

## Why the tests missed it
There is nothing for the tests to "miss": the single FAIL_TO_PASS test (`test_non_ascii_dns_non_unicode_email`, `gold_test.patch`) mocks `socket.getfqdn` and clears the cache, driving execution straight through `CachedDnsName.get_fqdn()` — precisely the line baseline fixed. So baseline genuinely passes it (resolved), and the test is in fact aimed at exactly the right place. The test does not (and need not) cover the monkey-patched-`DNS_NAME` shape that fvk's line targets, because that shape is a test-author convenience, not production behavior.

## Gold comparison
Gold fixes the Message-ID crash the **same way baseline did** — `utils.py`:
`-            self._fqdn = socket.getfqdn()` / `+            self._fqdn = punycode(socket.getfqdn())`.
Critically, **gold does NOT touch the `make_msgid(domain=DNS_NAME)` line** (confirmed: `make_msgid` appears nowhere in `gold.patch`). Gold's other edits (`sanitize_address`, `validators.py`, `html.py`, and a `punycode` helper in `django/utils/encoding.py`) are behavior-preserving extractions of pre-existing `domain.encode('idna').decode('ascii')` logic, not new bug fixes for this issue. So for the actual defect, **baseline matches gold and fvk diverges** by adding a line gold deliberately did not. GOLD_MATCH: baseline = yes; fvk = partial (right helper idea, but an extra non-gold edit).

## Confidence & caveats
High confidence. Demonstrations are empirical (stdlib `idna`/`make_msgid`/`Header` reproduced; `CachedDnsName` reconstructed faithfully from patch context). The Django package is not installed locally, so I modeled `CachedDnsName` rather than importing it, but its `__str__`→`get_fqdn` contract is fixed by the patch context and is standard. Conclusion: the "tests pass but code is subtly wrong" hypothesis does **not** hold here — baseline was already correct and gold-aligned; fvk's change is a redundant, gold-divergent no-op (harmless but unnecessary). Best honest fit is D_EQUIVALENT (with an F flavor for the unnecessary divergence from gold).
