# ITERATION GUIDANCE

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Verdict

V1 stands unchanged.

The FVK audit found that V1 discharges the public issue intent:

- reject LF, CR, and tab before `urlsplit()` can strip them;
- reject both reported newline-containing URLs;
- preserve existing validation behavior for strings without those unsafe characters;
- keep public `URLValidator` construction and default form/model callsites compatible.

## Do not change now

Do not replace `urllib.parse.urlsplit()` with `django.utils.http._urlsplit()` for this issue. FINDINGS F-004 and PROOF_OBLIGATIONS PO-005 show the smaller early guard fixes the reported normalization bug while preserving the existing IDN fallback path for inputs without unsafe characters.

Do not edit form/model URL fields. FINDINGS F-005 and PROOF_OBLIGATIONS PO-007 show their public integration remains compatible with the unchanged `URLValidator()` call shape.

Do not edit tests. The task forbids test edits, and PROOF keeps test-removal guidance conditioned on future machine checking.

## Future checks

If a future public issue or Python change shows `urlsplit()` strips more characters before splitting, update the intent ledger first and then consider extending `unsafe_chars`. Do not extend the family from implementation speculation alone.

If K tooling becomes available, run:

```sh
kompile fvk/mini-urlvalidator.k --backend haskell
kast --backend haskell fvk/urlvalidator-spec.k
kprove fvk/urlvalidator-spec.k
```

Only after `kprove` returns `#Top` should any test-redundancy recommendation be treated as machine-checked.

## Suggested next prompt for a code generator

Keep the existing V1 source patch. If revising for readability only, preserve the exact behavior: `URLValidator.__call__()` must raise `ValidationError` for any string containing tab, carriage return, or line feed before scheme parsing or any call to `urlsplit()`.
