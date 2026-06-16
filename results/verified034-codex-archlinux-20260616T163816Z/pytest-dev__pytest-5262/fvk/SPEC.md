# SPEC.md

Status: constructed, not machine-checked.

## Scope

The audited production unit is `_pytest.capture.EncodedFile.mode` in
`repo/src/_pytest/capture.py`. The surrounding behavior under audit is:

- `EncodedFile` wraps an underlying file-like `buffer`.
- `EncodedFile.write` accepts text and, on Python 3, rejects `bytes`.
- `EncodedFile.buffer.mode` remains the underlying binary stream mode.
- `EncodedFile.mode` is the public mode advertised by the wrapper.

There are no loops and no recursive functions in the audited change.

## Intent Spec

1. `EncodedFile.mode` must not advertise binary capability with a `b` flag.
2. If the wrapped buffer mode is `M`, then `EncodedFile.mode` must equal `M`
   with every `b` removed, preserving all other mode characters and their order.
3. `EncodedFile.buffer.mode` must remain the underlying mode, including `b`
   when the buffer is binary.
4. `EncodedFile.write` should remain text-oriented; the fix is not to accept
   `bytes`, because the issue is the mismatch between the advertised mode and
   the existing text-write contract.
5. Accessing `.mode` is specified for wrapped buffers that expose a string
   `mode` attribute. Buffers without `mode` keep the prior effective behavior:
   direct mode access raises `AttributeError`.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E-001 | `benchmark/PROBLEM.md` title | "`_pytest.capture.EncodedFile mode should not include `b` (binary)`" | `EncodedFile.mode` must not contain the binary flag. | Encoded in PO-1 and PO-2. |
| E-002 | `benchmark/PROBLEM.md` issue body | "Youtube-dl looks for `b` in `out.mode` to decide whether to writes `bytes` or `str`." | The advertised mode controls third-party write type selection. | Encoded in PO-1. |
| E-003 | `benchmark/PROBLEM.md` issue body | "`EncodedFile` incorrectly advertises `rb+`, the mode of the underlying stream." | Delegating `.mode` to the buffer is the pre-fix defect. | Finding F-001. |
| E-004 | `benchmark/PROBLEM.md` traceback | "`write() argument must be str, not bytes`" | The wrapper is text-oriented on Python 3. | Encoded in PO-1 and PO-4. |
| E-005 | `benchmark/PROBLEM.md` public hint | `return self.buffer.mode.replace('b', '')` | The expected transformation removes `b` from the underlying mode. | Encoded in PO-2 and PO-3. |
| E-006 | Source implementation | `__getattr__` delegates unknown attributes to `buffer`; V1 adds a `mode` property before `__getattr__`. | The fix should intercept only `.mode` and leave other delegation unchanged. | Encoded in PO-5. |

## Formal Model

The formal core is in:

- `fvk/mini-capture.k`
- `fvk/encodedfile-spec.k`

The model abstracts Python mode strings as finite lists of mode characters. The
special character `mcB` represents the binary flag `b`; all other legal mode
characters are represented by non-`mcB` constructors. The helper `stripB`
models Python's `mode.replace("b", "")` for this domain.

## Formal English

Claim C-1: for every finite buffer mode `M`, reading `EncodedFile.mode`
returns `stripB(M)`.

Claim C-2: for every finite buffer mode `M`, `stripB(M)` contains no `mcB`
binary flag.

Claim C-3: for every finite buffer mode `M`, reading `EncodedFile.buffer.mode`
returns exactly `M`.

Claim C-4: for every finite buffer mode `M`, `stripB(M)` preserves the relative
order and multiplicity of every non-`mcB` mode character.

## Adequacy Audit

| Claim | Intent coverage | Result |
| --- | --- | --- |
| C-1 | Matches E-001, E-003, and E-005. | Pass. |
| C-2 | Matches E-001 and E-002. | Pass. |
| C-3 | Matches the issue's distinction between wrapper mode and underlying stream mode; supports the hinted test shape. | Pass. |
| C-4 | Matches E-005: `replace("b", "")` removes only `b`. | Pass. |

No claim derives expected behavior solely from V1. V1 is checked against the
intent-derived transformation from the issue and public hint.

## Public Compatibility Audit

No public function or method signature changed. The new property resolves only
the `.mode` attribute that previously fell through to the wrapped buffer. The
existing `buffer` attribute and `__getattr__` delegation remain in place, so
callers that need the real binary mode can continue to use `.buffer.mode`.

The only intentional compatibility change is that `EncodedFile.mode` no longer
equals `EncodedFile.buffer.mode` when the underlying mode contains `b`; that
legacy equality is the reported bug.
