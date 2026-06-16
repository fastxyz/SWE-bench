# FVK Findings

Constructed, not machine-checked.

## F-001: Pre-fix property type nodes were plain text

- Classification: resolved code bug.
- Evidence: the issue states that property type annotations do not
  cross-reference, and the pre-fix `PyProperty.handle_signature()` appended
  `addnodes.desc_annotation(typ, ': ' + typ)`.
- Input: `py:property` with `:type: Point`, as generated from
  `@property def end(self) -> Point`.
- Observed pre-fix behavior: the signature annotation contained plain text
  `": Point"`, so no Python pending cross-reference existed for `Point`.
- Expected behavior: the signature annotation contains visible text `": "` plus
  a parsed annotation node whose type token is a Python pending cross-reference.
- Resolution: V1 calls `_parse_annotation(typ, self.env)` and appends those
  parsed nodes. This discharges PO-001 and PO-002.

## F-002: Autodoc annotation discovery is not the root cause

- Classification: confirmed non-bug in producer path.
- Evidence: `PropertyDocumenter.add_directive_header()` already inspects the
  property getter signature and emits `:type:` from the return annotation when
  present.
- Input: property getter with return annotation `Point`.
- Observed V1 behavior: no producer code was changed; the consumer receives the
  same `:type:` option.
- Expected behavior: leave discovery unchanged and parse the consumed option.
- Resolution: no source edit under `sphinx.ext.autodoc` is justified. This
  supports PO-004 and PO-005.

## F-003: No compatibility blocker was found

- Classification: compatibility finding, resolved.
- Evidence: `PyProperty.handle_signature` keeps the same signature, return
  value, option names, and directive registration; search found no subclass
  override of this method.
- Input: public callers and directive dispatch for `py:property`.
- Observed V1 behavior: only the internal children of the optional type
  annotation node change.
- Expected behavior: public directive and method compatibility are preserved.
- Resolution: no compatibility source edit is required. This discharges PO-005.

## F-004: Proof is constructed over a mini semantics, not machine-checked

- Classification: proof capability / honesty gate.
- Evidence: the task forbids running K tooling, and FVK MVP proofs are
  constructed before later machine checking.
- Input: the emitted `.k` claims in `fvk/python-property-spec.k`.
- Observed state: commands are recorded but not executed.
- Expected next action: a future environment with K installed can run the
  emitted `kompile`, `kast`, and `kprove` commands.
- Resolution: this does not justify additional code changes; it only conditions
  proof confidence and any test-redundancy recommendation.

## Proof-Derived Findings From `/verify`

No additional code bug surfaced. The only proof limitation is F-004. The proof
obligations cover the issue exemplar, the no-type frame case, the consumer-side
root cause, and public compatibility. V1 may stand unchanged.
