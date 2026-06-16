# Iteration Guidance

Status: V2 is the recommended candidate.

## Decision

Keep the V1 source-code behavior and add the V2 documentation update. The FVK audit did not surface a remaining functional defect in the V1 code against the public intent. It did surface a public documentation mismatch, now fixed.

## Why V1 Code Stands

- PO-1 through PO-11 discharge the requested behavior and compatibility frame conditions.
- `FINDINGS.md` has no remaining blocking code bug after the V1 behavior changes.
- `SPEC_AUDIT.md` marks each formal claim as intent-backed rather than implementation-derived.
- `PUBLIC_COMPATIBILITY_AUDIT.md` finds no public signature, override, or dispatch compatibility break for documented option values.

## V2 Improvement

- Update `repo/doc/usage/extensions/autodoc.rst` so the public docs state that `private-members` can take explicit private member names.
- Add `private-members` to the `autodoc_default_options` example to document string-valued default support.

## Recommended Follow-Up Tests

Do not edit tests in this task. Future test coverage should exercise:

- class `:members:` plus `:private-members: _one`;
- module `:members:` plus `:private-members: private_function` where privacy comes from `:meta private:`;
- default options with `private-members` as a string;
- interaction with `exclude-members`;
- compatibility of bare `private-members` with existing all-private behavior.

## Machine-Check Step

When a K environment is available, run:

```sh
kompile fvk/mini-autodoc.k --backend haskell
kast --backend haskell fvk/autodoc-private-members-spec.k
kprove fvk/autodoc-private-members-spec.k
```

Treat the constructed proof as machine-verified only if `kprove` returns `#Top`.
