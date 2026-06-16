# FVK Notes

## Decisions

### Changed `repo/django/core/servers/basehttp.py`

I changed the custom `ServerHandler.finish_response()` cleanup block from
`except Exception:` to `except BaseException:`. The FVK audit identified this as
Finding F2: V1 had taken over response completion for `HEAD`, but its explicit
`self.result.close()` cleanup did not cover abnormal exits outside `Exception`.
Proof obligation PO6 requires preserving response close semantics when the
custom `HEAD` finisher exits abnormally. The V2 edit closes the result when
present and re-raises, discharging PO6.

### Kept the V1 `ServerHandler.write()` approach

Finding F1 and PO1 require `HEAD` body-output bytes to remain unchanged.
PO3 additionally requires headers to be sent and flushed despite removing the
normal body write. V1's `write()` branch satisfies both: it performs status,
header, byte-count, and flush bookkeeping for `HEAD`, but never writes body
data. PO8 frames non-`HEAD` behavior through the immediate `super().write()`
delegation, so this part of V1 stands.

### Kept the V1 `sendfile()` override

Finding F3 and PO4 require body suppression to cover optimized file paths, not
only iterable writes. V1's `sendfile()` override returns `False` for `HEAD`,
forcing the header-only path. PO8 is satisfied because non-`HEAD` requests still
delegate to `super().sendfile()`.

### Kept the V1 `finish_response()` shape

Findings F1 and F3 plus PO5 require `HEAD` completion to establish headers
without draining the full response body. V1's custom branch advances at most one
chunk, calls `write()` only for header bookkeeping, finishes/flushed headers,
and closes. The FVK audit found that shape correct; only the abnormal-exit
cleanup catch needed the PO6 improvement described above.

### Kept the V1 `ConditionalGetMiddleware` change

Finding F4 and PO7 trace to the public hint that `HEAD` bodies are still
available to middleware and validators may be set for `HEAD`. V1's method gate
`request.method not in ("GET", "HEAD")` and updated comments/docstring satisfy
that obligation. No further middleware edits were needed.

## Verification status

The proof in `fvk/PROOF.md` is constructed, not machine-checked, as required by
Finding F5 and PO9. I did not run tests, Python, `kompile`, `kast`, or `kprove`,
and I did not modify any test files.
