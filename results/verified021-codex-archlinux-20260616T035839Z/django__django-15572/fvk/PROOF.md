# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were executed.

## Claims Proved

The constructed proof covers claims C1-C5 from `fvk/FORMAL_SPEC_ENGLISH.md`,
implemented as proof obligations PO1-PO6 in `fvk/PROOF_OBLIGATIONS.md`.

## Symbolic Proof Sketch

1. Direct configured dirs:
   - Symbolically take an arbitrary `directory` from `backend.engine.dirs`.
   - If `directory == ""`, the comprehension guard is false, so the body
     `cwd / to_path(directory)` is not evaluated and no `Path.cwd()` contribution
     can be produced from that element.
   - If `directory != ""`, the guard is true and the emitted expression is
     exactly the pre-existing `cwd / to_path(directory)`.

2. Loader-provided dirs:
   - Symbolically take an arbitrary `directory` from `loader.get_dirs()`.
   - If `directory == ""`, the conjoined guard is false before normalization,
     so the element contributes nothing.
   - If `directory != ""` and `is_django_path(directory)` is true, the existing
     Django-template exclusion still skips it.
   - If `directory != ""` and `is_django_path(directory)` is false, the emitted
     expression is exactly the pre-existing `cwd / to_path(directory)`.

3. False-positive removal in `template_changed()`:
   - By steps 1 and 2, `DIRS = [""]` cannot introduce `Path.cwd()` through
     either contributor.
   - `template_changed()` only returns `True` after finding a returned
     `template_dir` in `file_path.parents`.
   - Therefore an unrelated non-Python file under `Path.cwd()` is no longer
     matched solely because `""` normalized to the current directory.

4. Frame conditions:
   - The signal receivers, return shape, `reset_loaders()`, and path type of
     included entries are unchanged.
   - The proof does not claim total correctness, performance, or machine-checked
     K validity.

## Adequacy

`fvk/SPEC_AUDIT.md` maps every formal claim back to the intent obligations in
`fvk/INTENT_SPEC.md`. No claim relies solely on V1 behavior. The only scoped-out
case is explicit current-directory configuration, which the public issue does
not identify as invalid.

## Machine-check Commands Not Run

These are the commands the FVK method would use to machine-check the constructed
claims later:

```sh
kompile fvk/mini-autoreload.k --backend haskell
kast --backend haskell fvk/autoreload-spec.k
kprove fvk/autoreload-spec.k
```

Expected result from a completed machine-checking pass: `#Top` for the claims
corresponding to PO1-PO6. Because this session did not run K, syntax/toolchain
acceptance is not claimed.

## Test Guidance

No test files were modified. Suggested tests to keep or add in the fixed test
suite:

- Keep normalization coverage for non-empty relative strings and `Path` values.
- Add coverage for `DIRS = [""]` ensuring `get_template_directories()` does not
  include `Path.cwd()` from that value.
- Add coverage for loader `get_dirs()` returning `[""]`, because this is the
  second contributor covered by PO2.

No test removal is recommended unless the K claims are machine-checked and the
project maintainers decide those unit cases are redundant.
