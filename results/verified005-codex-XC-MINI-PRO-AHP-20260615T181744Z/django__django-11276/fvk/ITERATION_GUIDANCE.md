# Iteration Guidance

Status: V1 stands unchanged after FVK audit.

## Decision

No additional source edits are justified by the FVK findings. The V1 source
change satisfies all proof obligations in `PROOF_OBLIGATIONS.md` within the
targeted scope.

## Why V1 Stands

- Keep `_html_escape(str(text))`: required by PO1 and PO2; resolves F1.
- Keep `mark_safe(...)`: required by PO3; preserves the public safe-string
  return contract.
- Keep "always escape" behavior for safe input: required by PO4 and E7.
- Keep stdlib apostrophe spelling `&#x27;`: required by PO5; visible legacy
  `&#39;` expectations are SUSPECT per F2.
- Keep the `urlize()` `&#x27;` replacement: required by PO8; resolves F3.

## Rejected Changes

- Do not reintroduce a custom apostrophe mapping to `&#39;`. That would violate
  PO1 and PO5 and preserve SUSPECT legacy behavior from F2.
- Do not replace the local `urlize()` helper with broad stdlib `html.unescape()`
  in this pass. The public obligation is narrow support for entities produced
  by this module; broader unescaping could change URL parsing behavior without
  issue evidence.
- Do not edit tests or docs in this benchmark. Tests are fixed and hidden by
  instruction, and documentation edits are outside the requested source fix.

## Future Work Outside This Benchmark

- Run the recorded `kompile`/`kprove` commands in an environment with K.
- Run Django's relevant HTML utility and template-filter tests.
- Update public tests/documentation that intentionally assert the old `&#39;`
  literal to the stdlib `&#x27;` spelling, if maintainers accept the backwards
  incompatible text change.
