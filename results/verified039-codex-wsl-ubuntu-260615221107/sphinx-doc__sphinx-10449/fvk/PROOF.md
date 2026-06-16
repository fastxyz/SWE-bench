# FVK Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`,
or `kprove` were run.

## What Is Proved

Partial correctness of the audited autodoc type-hint handoff:

- `record_typehints()` does not record a `"return"` annotation for `class` or
  `exception` object descriptions.
- Since `merge_typehints()` creates an `rtype` field only from a recorded
  `"return"` annotation, the class-level `Return type` field reported in the
  issue is not produced on the audited path.
- Parameter annotations for classes and return annotations for functions and
  methods remain preserved.

## Constructed Proof Sketch

PO1 begins with `objtype == "class"` and a signature containing parameter
annotations plus a return annotation. Symbolic execution of
`record_typehints()` enters the `callable(obj)` branch, creates or retrieves
`annotations[name]`, and iterates through `sig.parameters.values()`. Each
annotated parameter is recorded before the return-annotation guard is reached.

At the guard:

```python
if (objtype not in ('class', 'exception') and
        sig.return_annotation is not sig.empty):
```

the first conjunct is false for `objtype == "class"`. By short-circuit Boolean
semantics, the body that writes `annotation['return']` is unreachable. The
post-state therefore contains the parameter annotations and no newly recorded
`"return"` key for the class fullname.

PO2 is identical except the first conjunct is false for
`objtype == "exception"`.

PO3 begins with `objtype == "function"` or `"method"` and a non-empty return
annotation. The first conjunct is true, the second conjunct is true, and the
body records `annotation['return']`. No V1 edit touches the parameter loop or
the stringification mode selection.

PO4 follows by inspection of `modify_field_list()` and
`augment_descriptions_with_types()`. The first helper skips `"return"` during
parameter-field insertion and creates `rtype` only under:

```python
if 'return' in annotations and 'return' not in arguments:
```

The second helper creates `rtype` only inside:

```python
if 'return' in annotations:
```

Therefore absence of `"return"` after PO1 or PO2 is sufficient to prevent
autodoc type-hint merging from injecting a class-like `rtype` field.

## Adequacy

The formal English in `SPEC.md` matches the public issue intent: no return type
listed for the class. The proof does not rely on the current output as the
expected output; it uses the issue expectation as the postcondition and treats
legacy public tests that encode class-level `Return type: None` as SUSPECT.

## Residual Risk

The proof is over a reduced model of the event handoff and assumes normal
autodoc ownership of `env.temp_data['annotations'][name]`. It does not prove
behavior against arbitrary external extensions that manually pre-populate that
internal map. It also does not prove termination, but the audited code has no
unbounded loop or recursion in the modeled path.

## Machine-Check Commands

Emitted for later checking only:

```sh
kompile fvk/mini-autodoc-typehints.k --backend haskell
kast --backend haskell fvk/autodoc-typehints-spec.k
kprove fvk/autodoc-typehints-spec.k
```

Expected result: `#Top` for all claims. Until those commands are actually run,
the proof remains constructed, not machine-checked.

## Test Guidance

No test files were modified. Existing function/method type-hint tests should be
kept. A class-level `Return type: None` expectation under
`autodoc_typehints = "description"` is legacy-bug coverage and should be
updated or replaced by a test asserting no class-level return type. Any test
removal would be recommendation-only and conditioned on a real `kprove` run.
