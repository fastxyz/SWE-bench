# psf__requests-2931

## Summary

**Severity:** Low — baseline leaves a latent bytes-decoding defect in the *shared*
`_encode_params` helper that is not reachable through any public API path on this
commit (only by calling the private helper directly, or via a future body path),
so the practical blast radius is small.

Baseline and FVK both passed the official SWE-bench evaluation for this issue,
with **different** patches. The reported crash is fixed by both, but baseline
guards only the one caller (`prepare_body`) and leaves the shared encoder still
calling `to_native_string` on raw bytes — exactly the bug. FVK instead fixed the
bug at the shared `_encode_params` helper (where the human gold patch also fixes
it) and compensated at the URL call site. The case matters because FVK located
the residual hazard by **lifting the issue into a helper-level byte-preservation
invariant and auditing every caller of the shared encoder**, not by running more
tests.

| Arm | direct call `_encode_params(b"\xc3\xb6\xc3\xb6\xc3\xb6")` (shared encoder) | Resolved |
|---|---|---|
| baseline | **RAISE `UnicodeDecodeError`** (encoder untouched) | no |
| gold (human oracle) | OK → bytes preserved | yes |
| **fvk** | OK → bytes preserved | **yes** |

## 1. The issue and the real defect

The reported failure: on requests 2.9 a binary body crashes during preparation
([`problem_statement.md`](../verified500_analysis/psf__requests-2931/_materials/problem_statement.md#L4)):

```python
import requests
requests.put("http://httpbin.org/put", data=u"ööö".encode("utf-8"))
# i.e. data=b"\xc3\xb6\xc3\xb6\xc3\xb6" — works in 2.8.1, raises in 2.9
```

`PreparedRequest.prepare_body` routed every truthy non-file / non-stream `data`
through the staticmethod `_encode_params`, whose first branch was
`if isinstance(data, (str, bytes)): return to_native_string(data)`. On Python 3,
`to_native_string(bytes)` does `bytes.decode("ascii")`, which raises
`UnicodeDecodeError` on any non-ASCII UTF-8 body. The user-facing observable that
is wrong: an **already-encoded bytes body is the payload and must be passed
through untouched**, but the encoder decodes it instead. The same `_encode_params`
helper is also called by `prepare_url` for query strings, where bytes legitimately
need to become native URL text — so the helper serves two contexts with one
behavior.

## 2. Baseline's fix — and where it stopped

[Baseline](../verified500_analysis/psf__requests-2931/_materials/baseline.patch)
patched only the **caller**. In `prepare_body` it added a caller-side guard so
raw bytes bypass the encoder:

```python
if isinstance(data, bytes):
    body = data
else:
    body = self._encode_params(data)
```

`_encode_params` itself is left **unchanged** — it still does
`return to_native_string(data)` for `bytes`. Baseline was not careless: its notes
*consciously reject* fixing the shared helper, reasoning that `prepare_url` relies
on it for query strings:

> *"I rejected changing `_encode_params` to return bytes unchanged in all cases
> because `prepare_url` uses it for query strings, and the existing behavior
> expects `params=b"test=foo"` to become a usable native URL query string."*
> — [`reports/baseline_notes.md`](../results/verified030-codex-archlinux-20260616T123754Z/psf__requests-2931/reports/baseline_notes.md#L41)

That reasoning is **half right**: bytes `params` genuinely must become native URL
text. But it stops one step short — the safe fix is to make the encoder preserve
bytes and convert at the URL boundary, which is precisely what the maintainers
shipped. The exact obligation baseline left unmet: **the shared encoder still
violates byte preservation for every caller other than the one it guarded.**

## 3. How FVK formally captured the gap

FVK started from a helper-level invariant, not from the symptom. The decisive
intent item generalizes the issue beyond the single reported caller:

> **I1.** *A non-empty raw `bytes` value supplied as `data` is already a request
> body. Requests must preserve it byte-for-byte during preparation, including
> bytes that are not ASCII.*
> — [`fvk/INTENT_SPEC.md`](../results/verified030-codex-archlinux-20260616T123754Z/psf__requests-2931/fvk/INTENT_SPEC.md#L19)

The evidence ledger pins that intent to a concrete code fact found by source
audit — **not** to the reported test. The fact is that the defective conversion
is *shared* across two call sites:

> **E8 (implementation):** *`_encode_params` is called from both `prepare_body`
> and `prepare_url`.* → *A safe fix must distinguish body bytes from URL query
> bytes.*
> — [`fvk/PUBLIC_EVIDENCE_LEDGER.md`](../results/verified030-codex-archlinux-20260616T123754Z/psf__requests-2931/fvk/PUBLIC_EVIDENCE_LEDGER.md#L14)

Which is discharged into a formal obligation stated at the *helper* level, not the
caller level:

> **PO-1: Bytes preservation in `_encode_params`.** *Claim: for all byte sequences
> `B`, `_encode_params(B)` returns `B`.*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified030-codex-archlinux-20260616T123754Z/psf__requests-2931/fvk/PROOF_OBLIGATIONS.md#L5)

This is the crux of FVK's value: **the residual defect was located by reasoning,
not observation.** The issue says "a binary body must not be decoded"; FVK lifts
that into an invariant over the *shared encoder itself* (PO-1, quantified over all
`B`), and the code audit (E8) shows the encoder feeds two callers — so guarding
one caller cannot satisfy a helper-level invariant. The companion obligation PO-3
captures the compensation the maintainers also needed: bytes `params` must still
become native URL text at the URL boundary
([`fvk/PROOF_OBLIGATIONS.md#L28`](../results/verified030-codex-archlinux-20260616T123754Z/psf__requests-2931/fvk/PROOF_OBLIGATIONS.md#L28)).

## 4. From formal output to the fix

The FVK arm's repair is iterative, and the artifacts record the exact step where
the formalism changed the patch.

- **V1** (first attempt) guarded the public body path only — identical in effect
  to what baseline shipped (caller-side bypass in `prepare_body`).
- The completeness audit against the spec raised a finding that V1 still left the
  shared encoder hazardous:

  > **F-001: V1 fixed the public body path but left the shared encoder hazard.**
  > *Input: direct encoder use or any future body path reaching
  > `_encode_params(b"\xc3\xb6\xc3\xb6\xc3\xb6")` … V2 action: `_encode_params` now
  > returns `bytes` unchanged and handles text in a separate `elif isinstance(data,
  > str)` branch.*
  > — [`fvk/FINDINGS.md`](../results/verified030-codex-archlinux-20260616T123754Z/psf__requests-2931/fvk/FINDINGS.md#L5)

- The iteration guidance turned the finding into an instruction for the next
  revision, explicitly rejecting the V1 caller-local bypass:

  > *"V1 fixed the public `prepare_body` path by bypassing `_encode_params`, but
  > left the shared helper's bytes behavior as 'decode with `to_native_string`.'
  > V2 moves bytes preservation into `_encode_params` and compensates at the URL
  > call site, satisfying PO-1 through PO-4."*
  > — [`fvk/ITERATION_GUIDANCE.md`](../results/verified030-codex-archlinux-20260616T123754Z/psf__requests-2931/fvk/ITERATION_GUIDANCE.md#L7)

- The decision log records the resulting code change and its provenance:

  > *"`_encode_params` now handles `bytes` before `str` and returns bytes
  > unchanged. Trace: F-001, PO-1, PO-2. … `prepare_url` now converts byte
  > `enc_params` with `to_native_string` before joining them into the URL query.
  > Trace: F-002 and PO-3. … The V1 caller-local bytes bypass in `prepare_body`
  > was removed."*
  > — [`reports/fvk_notes.md`](../results/verified030-codex-archlinux-20260616T123754Z/psf__requests-2931/reports/fvk_notes.md#L17)

The causal chain is fully on the record:

```
INTENT I1   ->  E8  (code audit: _encode_params shared by prepare_body + prepare_url)
            ->  F-001 (V1 audit: shared encoder still decodes raw bytes)
            ->  PO-1  (obligation: _encode_params(B) = B for all bytes B)
            ->  PO-3  (compensation: prepare_url must re-nativize bytes params)
            ->  ITERATION_GUIDANCE / fvk_notes  ->  V2 patch
```

The resulting [V2 patch](../verified500_analysis/psf__requests-2931/_materials/fvk.patch)
splits bytes from text in the encoder and converts at the URL boundary:

```python
# _encode_params
-        if isinstance(data, (str, bytes)):
+        if isinstance(data, bytes):
+            return data
+        elif isinstance(data, str):
             return to_native_string(data)
# prepare_url
         enc_params = self._encode_params(params)
         if enc_params:
+            if isinstance(enc_params, bytes):
+                enc_params = to_native_string(enc_params)
```

The `V1 -> V2` transition was driven by `F-001`/`PO-1`, **not** by a new failing
test — the hidden test only exercises the public body path (see §5).

## 5. Verification

No harness proof exists for this case (`enhanced_tests/_proof/` was not produced),
so there is **no harness RED/GREEN table**. The evidence is the executed
demonstration carried over from the existing analysis — **run off the harness**.

**Behavioral demonstration (not on the harness).** All four code variants
(ORIGINAL / BASELINE / FVK / GOLD) of `_encode_params` / `prepare_body` /
`prepare_url` were reconstructed from the patch contexts and the real
`to_native_string`, then exercised. The distinguishing input is a **direct call to
the shared encoder** with a non-ASCII bytes payload, `_encode_params(b"\xc3\xb6\xc3\xb6\xc3\xb6")`:

| variant | `_encode_params(b"\xc3\xb6\xc3\xb6\xc3\xb6")` |
|---|---|
| ORIGINAL | RAISE `UnicodeDecodeError: 'ascii' codec can't decode byte 0xc3` |
| BASELINE | **RAISE `UnicodeDecodeError`** (encoder still buggy) |
| FVK | OK → `b"\xc3\xb6\xc3\xb6\xc3\xb6"` (bytes preserved) |
| GOLD | OK → `b"\xc3\xb6\xc3\xb6\xc3\xb6"` (bytes preserved) |

On the **public** body path `prepare_body(data=b"\xc3\xb6\xc3\xb6\xc3\xb6")`,
baseline / fvk / gold all return the bytes correctly (only ORIGINAL raises) — so
baseline genuinely fixes the *reported* bug; it just leaves the helper defective.
The compat path `prepare_url(params=b"test=foo")` yields `"test=foo"` in all four.

**FVK matches the human oracle; baseline is the odd one out.** Gold fixes the
**same shared location** FVK does, at `_encode_params`, with the same URL-boundary
compensation
([`_materials/gold.patch`](../verified500_analysis/psf__requests-2931/_materials/gold.patch#L7)):
gold returns `data` unchanged in the `(str, bytes)` branch and re-nativizes
`params` before the encoder call; FVK splits bytes/str and re-nativizes
`enc_params` after the call. On Python 3 `to_native_string(str)` is a no-op, so
**FVK is behaviorally identical to gold** on the audited slice. Baseline diverges
by guarding the caller rather than the helper.

## 6. Boundaries & honesty

- **Severity: Low.** The trigger breadth is narrow: on this commit the only public
  caller of `_encode_params(bytes)` is `prepare_url`, and there a *non-ASCII* bytes
  params value raises in **all** variants (gold and fvk included — correct for a
  URL query), while baseline's `prepare_body` guards its own body path. So
  baseline's residual `_encode_params(bytes)` defect is **latent** — reachable only
  by calling the private helper directly or through a future body path, not a live
  user-facing crash baseline ships. FVK's own
  [`fvk/FINDINGS.md#L11`](../results/verified030-codex-archlinux-20260616T123754Z/psf__requests-2931/fvk/FINDINGS.md#L11)
  frames it exactly this way ("future body path"), which is credible, not
  overclaimed. The value demonstrated is **hardening + gold-alignment**, not a
  reproducible crash through a supported API.
- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-requests-body.k`](../results/verified030-codex-archlinux-20260616T123754Z/psf__requests-2931/fvk/mini-requests-body.k),
  [`requests-body-spec.k`](../results/verified030-codex-archlinux-20260616T123754Z/psf__requests-2931/fvk/requests-body-spec.k))
  and the `kompile` / `kast` / `kprove` commands were **written but never run** —
  the FVK artifacts say so explicitly
  ([`fvk/PROOF.md`](../results/verified030-codex-archlinux-20260616T123754Z/psf__requests-2931/fvk/PROOF.md#L3),
  [finding F-004](../results/verified030-codex-archlinux-20260616T123754Z/psf__requests-2931/fvk/FINDINGS.md#L57)).
  We therefore claim **proof-structured reasoning** (a helper-level invariant with
  obligations discharged by construction), **not a machine-checked proof**.
- **Why the tests missed it.** `gold_test.patch` adds exactly one assertion
  ([`_materials/gold_test.patch`](../verified500_analysis/psf__requests-2931/_materials/gold_test.patch#L8)),
  which exercises only the public body path and only asserts the body is bytes —
  satisfied by baseline's caller-side guard. No test calls `_encode_params`
  directly, and the existing `test_params_bytes_are_encoded` only uses ASCII
  `b'test=foo'`, which never trips `to_native_string`. So the suite cannot see
  baseline's untouched encoder — and equally cannot *prove* FVK is better through
  the public surface; the difference is structural / latent.
- **Attribution / reconstruction caveats.** Per the run protocol the variant code
  was rebuilt from patch hunks with the real `to_native_string`, not from a repo
  checkout; the `_encode_params` dict branch in the reconstruction is approximate
  but irrelevant to the str/bytes behavior under test. The existing analysis doc's
  claims are **consistent with the run artifacts** (patches DIFFER, fvk==gold at
  the shared helper, baseline guards the caller) — no discrepancy found.

## Artifact map

| Claim | Source |
|---|---|
| Issue text, repro | [`_materials/problem_statement.md`](../verified500_analysis/psf__requests-2931/_materials/problem_statement.md#L4) |
| Baseline patch | [`_materials/baseline.patch`](../verified500_analysis/psf__requests-2931/_materials/baseline.patch#L9) |
| Baseline rejected the shared-helper fix | [`reports/baseline_notes.md`](../results/verified030-codex-archlinux-20260616T123754Z/psf__requests-2931/reports/baseline_notes.md#L41) |
| FVK patch | [`_materials/fvk.patch`](../verified500_analysis/psf__requests-2931/_materials/fvk.patch#L9) |
| Gold patch (same shared location) | [`_materials/gold.patch`](../verified500_analysis/psf__requests-2931/_materials/gold.patch#L7) |
| Intent I1 (byte-for-byte preservation) | [`fvk/INTENT_SPEC.md#L19`](../results/verified030-codex-archlinux-20260616T123754Z/psf__requests-2931/fvk/INTENT_SPEC.md#L19) |
| Evidence E8 (shared encoder) | [`fvk/PUBLIC_EVIDENCE_LEDGER.md#L14`](../results/verified030-codex-archlinux-20260616T123754Z/psf__requests-2931/fvk/PUBLIC_EVIDENCE_LEDGER.md#L14) |
| Obligation PO-1 | [`fvk/PROOF_OBLIGATIONS.md#L5`](../results/verified030-codex-archlinux-20260616T123754Z/psf__requests-2931/fvk/PROOF_OBLIGATIONS.md#L5) |
| Obligation PO-3 (URL compensation) | [`fvk/PROOF_OBLIGATIONS.md#L28`](../results/verified030-codex-archlinux-20260616T123754Z/psf__requests-2931/fvk/PROOF_OBLIGATIONS.md#L28) |
| Finding F-001 (V1 left encoder hazard) | [`fvk/FINDINGS.md#L5`](../results/verified030-codex-archlinux-20260616T123754Z/psf__requests-2931/fvk/FINDINGS.md#L5) |
| Honesty note F-004 (proof unrun) | [`fvk/FINDINGS.md#L57`](../results/verified030-codex-archlinux-20260616T123754Z/psf__requests-2931/fvk/FINDINGS.md#L57) |
| Latent-only caveat ("future body path") | [`fvk/FINDINGS.md#L11`](../results/verified030-codex-archlinux-20260616T123754Z/psf__requests-2931/fvk/FINDINGS.md#L11) |
| Iteration instruction (V1→V2) | [`fvk/ITERATION_GUIDANCE.md#L7`](../results/verified030-codex-archlinux-20260616T123754Z/psf__requests-2931/fvk/ITERATION_GUIDANCE.md#L7) |
| Decision trace (encoder + URL + bypass removal) | [`reports/fvk_notes.md#L17`](../results/verified030-codex-archlinux-20260616T123754Z/psf__requests-2931/reports/fvk_notes.md#L17) |
| Constructed K core | [`fvk/mini-requests-body.k`](../results/verified030-codex-archlinux-20260616T123754Z/psf__requests-2931/fvk/mini-requests-body.k), [`fvk/requests-body-spec.k`](../results/verified030-codex-archlinux-20260616T123754Z/psf__requests-2931/fvk/requests-body-spec.k) |
| Proof status (commands not run) | [`fvk/PROOF.md#L3`](../results/verified030-codex-archlinux-20260616T123754Z/psf__requests-2931/fvk/PROOF.md#L3) |
| Hidden test (public body path only) | [`_materials/gold_test.patch#L8`](../verified500_analysis/psf__requests-2931/_materials/gold_test.patch#L8) |
| Raw model traces | [`transcripts/fvk.jsonl.gz`](../results/verified030-codex-archlinux-20260616T123754Z/psf__requests-2931/transcripts/fvk.jsonl.gz) |
