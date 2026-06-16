# FVK Findings

Status: constructed, not machine-checked.

## F-1: Pre-fix qop header value was unquoted

Input: a Digest challenge whose qop options include `auth`, for example `qop="auth"`.

Observed in the original source: `build_digest_header` serialized the outgoing Authorization field as `qop=auth`.

Expected from public intent E-1/E-3/E-4: the selected qop value is quoted as `qop="auth"`.

Classification: code bug. Status: fixed by V1 and retained in V2. Covered by PO-1.

## F-2: V1 used the raw qop-options string in the digest input

Input: a compliant qop-options challenge containing multiple values, for example parsed internally as `qop = "auth,auth-int"` or `qop = "auth-int, auth"`.

Observed in V1 by symbolic trace: the header advertised `qop="auth"`, but `noncebit` was built before qop selection with the raw `qop` string. That makes the response digest input use `auth,auth-int` or `auth-int, auth` while the header says the selected qop is `auth`.

Expected from E-2 plus PO-2: when Requests selects `auth`, both the header qop directive and the digest qop-value use the selected token `auth`.

Classification: code bug found by formalization. Status: fixed in V2 by deriving `noncebit` with the selected token `'auth'` after confirming `auth` is present in the stripped qop option list.

## F-3: `auth-int` remains explicitly unsupported

Input: a Digest challenge whose qop options contain `auth-int` but not `auth`.

Observed: the implementation reaches the existing `# XXX handle auth-int.` branch and returns `None`.

Expected for this FVK scope: do not claim `auth-int` support as proven. The issue text quotes RFC language mentioning `auth-int`, but the requested repair is qop quoting and option handling for the supported `auth` path.

Classification: residual unsupported feature / proof boundary. Status: not changed. Covered by PO-4 and called out in `ITERATION_GUIDANCE.md`.

## F-4: Public compatibility is preserved

Input: public use through `HTTPDigestAuth('user', 'pass')` and the internal retry flow.

Observed after V2: the constructor, `build_digest_header(self, method, url)` signature, and callsites are unchanged.

Expected from E-7 and PO-5: no public API or dispatch-shape change.

Classification: compatibility check. Status: passed.

## Proof-Derived Findings From `/verify`

The constructed proof has no loop or recursion obligations. Its main proof-derived finding is F-2: a proof of V1's header-quoting claim alone was insufficient because the full qop observable includes the digest qop-value contributor. The V2 claim spans both contributors.

The proof is constructed, not machine-checked. Do not remove tests based on this proof unless the recorded `kompile` and `kprove` commands later return `#Top`.

