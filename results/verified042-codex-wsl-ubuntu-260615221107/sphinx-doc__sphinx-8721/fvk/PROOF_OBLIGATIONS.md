# Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Adequacy of the specification

Statement:

The formal claims must express the public intent rather than the V1 behavior by
itself.

Evidence:

- E1 through E5 in `fvk/SPEC.md`.
- The docs independently state that EPUB does not support viewcode by default
  and that `viewcode_enable_epub=True` is the opt-in.

Discharge:

`fvk/SPEC.md` includes intent-only obligations, a public evidence ledger,
formal English paraphrases, and a spec audit. All claims pass the audit.

Status: discharged by adequacy review.

## PO-002: Disabled EPUB emits no viewcode pages

Formal claim:

`collectPages(true, false, HAS_MODULES, ENTRIES) => .Pages`

Meaning:

For every module-cache state, an EPUB builder with `viewcode_enable_epub` false
must yield no module source pages and no `_modules/index` page.

Source obligations:

E1, E2, E3, and E4.

Discharge:

The first K rule in `mini-viewcode.k` rewrites this state directly to `.Pages`
without inspecting `HAS_MODULES` or `ENTRIES`. The V1 Python guard has the same
control shape.

Status: discharged by constructed proof.

## PO-003: Reused HTML environment is in domain

Formal claim:

Same as PO-002, with universal `HAS_MODULES`.

Meaning:

The disabled EPUB no-output guarantee applies even when `_viewcode_modules`
already exists because `make html epub` ran HTML first.

Source obligations:

E2 and E6.

Discharge:

The claim quantifies over `HAS_MODULES:Bool`; the disabled EPUB rule does not
branch on that value.

Status: discharged by constructed proof.

## PO-004: Non-EPUB builders preserve existing generation

Formal claim:

`collectPages(false, ENABLE_EPUB, true, ENTRIES) => pagesFor(ENTRIES)`

Meaning:

The fix must not disable viewcode pages for non-EPUB HTML-related builders with
available module entries.

Source obligations:

I3 and E6.

Discharge:

When `IS_EPUB` is false, `IS_EPUB and not ENABLE_EPUB` is false; the generation
rule applies. The V1 Python guard is likewise skipped.

Status: discharged by constructed proof.

## PO-005: Explicit EPUB opt-in preserves generation

Formal claim:

`collectPages(true, true, true, ENTRIES) => pagesFor(ENTRIES)`

Meaning:

If the user sets `viewcode_enable_epub=True`, EPUB remains enabled for viewcode
generation.

Source obligations:

E5.

Discharge:

When `ENABLE_EPUB` is true, the disabled EPUB guard is false; the generation
rule applies. The V1 Python guard is likewise skipped.

Status: discharged by constructed proof.

## PO-006: Public compatibility is preserved

Statement:

The fix must not change public signatures, event names, builder APIs, or test
files.

Evidence:

The diff changes only the body of `collect_pages`; the function signature and
`app.connect('html-collect-pages', collect_pages)` remain unchanged.

Discharge:

Public compatibility audit in `fvk/SPEC.md` passes.

Status: discharged by inspection.

## PO-007: Proof honesty under no-execution constraints

Statement:

All verification output must be labeled constructed, not machine-checked, and
must not claim test results.

Evidence:

The benchmark instructions forbid tests, Python execution, and K tooling.

Discharge:

`fvk/PROOF.md` lists the commands that should be run later and states that they
were not executed.

Status: discharged.
