# psf__requests-2931

- **Verdict:** C_ROBUSTNESS — fvk fixes the bytes defect in the *shared* `_encode_params`
  helper (exactly where gold fixes it), whereas baseline only guards the one caller and
  leaves the encoder a latent footgun; the difference is real but not reachable via a
  public API path on this commit.
- **Pitch-worthiness (1-5):** 3

## Benchmark Result

- Baseline arm: official SWE-bench evaluation marked the patch as resolved.
- FVK arm: official SWE-bench evaluation marked the patch as resolved.
- Audit category: baseline passed the benchmark but remained concretely buggy.

## The issue
On requests 2.9 a binary body `requests.put(url, data=u"ööö".encode("utf-8"))`
(i.e. `data=b"\xc3\xb6\xc3\xb6\xc3\xb6"`) blows up. `PreparedRequest.prepare_body`
routed every truthy non-file/non-stream `data` through the staticmethod
`_encode_params`, whose first branch was `if isinstance(data, (str, bytes)): return
to_native_string(data)`. On Python 3 `to_native_string(bytes)` does
`bytes.decode("ascii")` (see `requests/_internal_utils.py:34`), which raises
`UnicodeDecodeError` on any non-ASCII UTF-8 body. Intended behavior: an
already-encoded bytes body is the payload and must be passed through untouched.

## What baseline did
Patched only the **caller**. In `prepare_body` it added a caller-side guard
(`baseline.patch`):

    if isinstance(data, bytes):
        body = data
    else:
        body = self._encode_params(data)

`_encode_params` itself is left **unchanged** — it still does
`return to_native_string(data)` for `bytes`. Baseline's own notes
(`baseline_notes.md`) explicitly *reject* fixing `_encode_params` "because
`prepare_url` uses it for query strings" — but that is precisely the fix the
maintainers shipped (with a compensation in `prepare_url`), so baseline
diverged from gold on purpose and for the wrong reason.

## What fvk changed and why
Two-location strategy that mirrors gold (`fvk.patch`):
1. `_encode_params`: `bytes` returned unchanged, `str` handled in a separate
   branch — the shared encoder no longer corrupts bytes.
2. `prepare_url`: when `enc_params` is bytes, convert with `to_native_string`
   at the URL-assembly boundary, preserving the `params=b"test=foo"` contract.
It also dropped baseline's caller-side bypass since the encoder is now safe.
fvk's findings (`fvk_FINDINGS.md` F-001) frame this as fixing "the shared
`_encode_params` hazard" reachable "directly or through a future body path,"
and F-003 honestly declines to touch the unrelated empty-bytes+json boundary.

## Concrete demonstration
Reconstructed all four code variants (ORIGINAL/BASELINE/FVK/GOLD) of
`_encode_params` / `prepare_body` / `prepare_url` from the patch contexts and the
real `to_native_string`, then exercised them (`/tmp/req2931_demo.py`).

Distinguishing input — **direct call to the shared encoder with a non-ASCII
bytes payload** (`b"\xc3\xb6\xc3\xb6\xc3\xb6"`), i.e. `_encode_params(b"...")`:

| variant  | `_encode_params(b"\xc3\xb6\xc3\xb6\xc3\xb6")` |
|----------|-----------------------------------------------|
| ORIGINAL | RAISE `UnicodeDecodeError: 'ascii' codec can't decode byte 0xc3` |
| BASELINE | **RAISE `UnicodeDecodeError`** (encoder still buggy) |
| FVK      | OK -> `b"\xc3\xb6\xc3\xb6\xc3\xb6"` (bytes preserved) |
| GOLD     | OK -> `b"\xc3\xb6\xc3\xb6\xc3\xb6"` (bytes preserved) |

On the **public** body path `prepare_body(data=b"\xc3\xb6\xc3\xb6\xc3\xb6")`,
baseline / fvk / gold all return the bytes correctly (only ORIGINAL raises) — so
baseline genuinely fixes the *reported* bug; it just leaves the helper defective.
The compat path `prepare_url(params=b"test=foo")` yields `"test=foo"` in all four.

Honest caveat on reachability: on this commit the only public caller of
`_encode_params(bytes)` is `prepare_url`, and there a *non-ASCII* bytes params
value raises in **all** variants (gold and fvk included — correct for a URL
query). Baseline's `prepare_body` guards its own path. So baseline's residual
`_encode_params(bytes)` defect is **latent** (triggerable only by calling the
private helper directly or by a future body path), not a live user-facing bug
baseline ships. The win is hardening + gold-alignment, not a reproducible crash
through a supported API.

## Why the tests missed it
`tests.json` FAIL_TO_PASS is a single test, and `gold_test.patch` adds exactly
one assertion:

    def test_binary_put(self):
        request = requests.Request('PUT', 'http://example.com',
                                   data=u"ööö".encode("utf-8")).prepare()
        assert isinstance(request.body, bytes)

It exercises only the **public body path** and only asserts the body is bytes —
which baseline's caller-side guard satisfies. No test calls `_encode_params`
directly, and `test_params_bytes_are_encoded` only uses ASCII `b'test=foo'`, which
never trips `to_native_string`. So the suite cannot see baseline's untouched
encoder. (This also means it cannot *prove* fvk is better through the public
surface — the difference is structural/latent.)

## FVK vs. Human Fix

**Human fix issue:** no.

Gold and FVK both preserve raw bytes at `_encode_params()`, the shared root helper. Baseline guards only one caller, leaving the helper contract wrong.

Gold fixes the **same shared location** fvk does, not baseline's caller:

    # requests/models.py, _encode_params
    -        return to_native_string(data)
    +        return data            # for the (str, bytes) branch
    ...
    # prepare_url
    +        if isinstance(params, (str, bytes)):
    +            params = to_native_string(params)
             enc_params = self._encode_params(params)

fvk and gold differ only in mechanics (gold converts `params` before encoding;
fvk converts `enc_params` after) and in whether the `str` branch keeps
`to_native_string` — but on Python 3 `to_native_string(str)` is a no-op, so
**fvk is behaviorally identical to gold here**. Baseline is the odd one out.
Notably, modern requests codifies gold's design in its type stubs
(`_encode_params(bytes) -> bytes`), confirming fvk/gold picked the maintainers'
intended shape.

## Confidence & caveats
- Confidence **high** on the mechanism and on "fvk == gold, baseline differs":
  reproduced directly with the real `to_native_string` and the exact patch code.
- Confidence **high** that both baseline and fvk pass the hidden test (both
  return a bytes body on the public path) — consistent with both "resolved."
- Main caveat: the baseline->fvk improvement is **latent/structural**, not a
  demonstrable crash through a public API on this commit. The honest pitch is
  "fvk fixed the root-cause helper (matching gold) where baseline patched only a
  symptom site," not "baseline corrupts real user requests." fvk's own
  `fvk_FINDINGS.md` states this ("future body path"), which is credible, not
  overclaimed.
- Reconstruction caveat: code was rebuilt from patch hunks (per instructions, no
  repo checkout); the `_encode_params` dict branch is approximate but irrelevant
  to the str/bytes behavior under test.
