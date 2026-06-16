# Constructed Proof

Status: constructed, not machine-checked. No tests, Python code, `kompile`, or
`kprove` commands were executed.

## Formal Artifacts

- Semantics fragment: `fvk/mini-viewcode.k`
- Claims: `fvk/viewcode-spec.k`

Commands to machine-check later from the workspace root:

```sh
kompile fvk/mini-viewcode.k --backend haskell
kast --backend haskell fvk/viewcode-spec.k
kprove fvk/viewcode-spec.k
```

Expected machine-check result after a working K installation: `#Top` for all
claims.

## Proof Sketch

### Claim: EPUB disabled emits no pages

Initial symbolic state:

`collectPages(true, false, HAS_MODULES, ENTRIES)`

The first semantic rule in `mini-viewcode.k` matches exactly:

```k
rule
  <k> collectPages(true, false, HAS_MODULES:Bool, ENTRIES:Entries) => .K </k>
  <yielded> _ => .Pages </yielded>
```

There is no side condition. Therefore, by one Axiom step and framing, the
configuration reaches `.K` with yielded pages `.Pages`. Because the rule does
not inspect `HAS_MODULES`, the proof covers both a fresh EPUB environment and
the issue's reused `make html epub` environment where module data was populated
by HTML first.

This corresponds to V1's Python control flow:

```python
if app.builder.name.startswith("epub") and not env.config.viewcode_enable_epub:
    return
```

Since `collect_pages` is a generator function, this `return` terminates the
generator before any `yield`, so `gen_pages_from_extensions()` receives no
viewcode page tuples from this handler.

### Claim: Non-EPUB builders fall through

Initial symbolic state:

`collectPages(false, ENABLE_EPUB, true, ENTRIES)`

The disabled EPUB condition is:

`IS_EPUB and not ENABLE_EPUB`

With `IS_EPUB == false`, the condition is false. The first rule does not match,
and the generation rule applies:

```k
rule
  <k> collectPages(IS_EPUB, ENABLE_EPUB, true, ENTRIES) => .K </k>
  <yielded> _ => pagesFor(ENTRIES) </yielded>
  requires notBool (IS_EPUB andBool notBool ENABLE_EPUB)
```

The side condition simplifies to `true`. Thus the existing generation behavior
is preserved for non-EPUB builders.

### Claim: EPUB opt-in falls through

Initial symbolic state:

`collectPages(true, true, true, ENTRIES)`

The disabled EPUB condition is false because `not ENABLE_EPUB` is false. The
generation rule applies and yields `pagesFor(ENTRIES)`. This matches the docs:
setting `viewcode_enable_epub=True` enables viewcode for EPUB.

### Claim: No modules still emits no pages

Initial symbolic state:

`collectPages(IS_EPUB, ENABLE_EPUB, false, ENTRIES)` with the disabled EPUB
guard false.

The no-module rule applies and yields `.Pages`. This preserves the original
behavior when `_viewcode_modules` is absent.

## Adequacy and Completeness Check

The proof covers the full intent space named by the issue:

- EPUB disabled with a fresh environment
- EPUB disabled with a reused environment containing module entries
- non-EPUB builders
- EPUB explicitly enabled
- no module cache

It deliberately abstracts page contents and freshness checks because those are
only reached after the disabled EPUB guard is false and are not the reported
defect.

## Test Recommendation

No test files were modified. Because the benchmark hides the evaluator tests
and forbids execution, there is no test-removal recommendation. Any public or
hidden tests should be kept unless and until the K commands above are actually
run and return `#Top`.

## Residual Risk

The proof is partial correctness for this control decision: if
`collect_pages()` is invoked, the disabled EPUB path yields no pages. Termination
is trivial in the modeled branch because it returns immediately, but the overall
Sphinx build is outside this proof.

Trusted base:

- the abstraction from `builder.name.startswith("epub")` to `IS_EPUB`
- the mini K semantics matching the relevant Python generator control flow
- K reachability logic and the future K toolchain run

No source-level issue remains under the public intent.
