# FVK Specification: sphinx-doc__sphinx-8721

Status: constructed, not machine-checked.

## Scope

The audited production behavior is `sphinx.ext.viewcode.collect_pages(app)` as
called from `StandaloneHTMLBuilder.gen_pages_from_extensions()` through the
`html-collect-pages` event. The issue concerns EPUB builders, which inherit the
standalone HTML builder path and can therefore call this event while reusing an
environment populated by an earlier HTML build.

The observable modeled here is the sequence of generated viewcode page tuples:
module source pages and the `_modules/index` overview page. The model abstracts
page contents, highlighting, parent links, and filesystem freshness checks,
because the public issue is about whether any viewcode pages are emitted for
EPUB when `viewcode_enable_epub` is false.

## Intent Spec

I1. Disabled EPUB must not generate viewcode pages.

Evidence: `benchmark/PROBLEM.md`: "viewcode creates pages for epub even if
`viewcode_enable_epub=False` on `make html epub`"; expected behavior: "module
pages should not be created for epub by default."

Obligation: for every EPUB builder state, including a reused environment with
existing `_viewcode_modules`, `collect_pages` emits no page tuples when
`viewcode_enable_epub` is false.

I2. EPUB viewcode support is explicit opt-in.

Evidence: `repo/doc/usage/extensions/viewcode.rst`: "By default `epub` builder
doesn't support this extension"; `viewcode_enable_epub`: "If this is `True`,
viewcode extension is also enabled even if you use epub builders."

Obligation: when `viewcode_enable_epub` is true, EPUB continues into the normal
viewcode generation path.

I3. Normal HTML-related builders are not part of the reported defect.

Evidence: `repo/doc/usage/extensions/viewcode.rst`: viewcode "works only on
HTML related builders ... except `singlehtml`"; the issue only names EPUB
default behavior.

Obligation: non-EPUB builders keep the existing `collect_pages` behavior.

I4. The fix must be source-only and compatible.

Evidence: benchmark instructions forbid test edits and require a targeted
source fix.

Obligation: no public API signature, event name, return protocol, or test file
is changed.

## Public Evidence Ledger

| ID | Source | Quoted evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "viewcode creates pages for epub even if `viewcode_enable_epub=False`" | Disabled EPUB page emission is the bug. | Encoded in claim `EPUB-DISABLED-NO-PAGES`. |
| E2 | prompt | "`make html epub`" | Reused environment after HTML is in domain. | Encoded by quantifying over `HAS_MODULES`. |
| E3 | prompt | "module pages should not be created for epub by default" | Expected output for EPUB-disabled is no generated module or index pages. | Encoded in claim postcondition `.Pages`. |
| E4 | docs | "By default `epub` builder doesn't support this extension" | Default EPUB config must disable viewcode output. | Encoded in claim `EPUB-DISABLED-NO-PAGES`. |
| E5 | docs | "If this is `True`, viewcode extension is also enabled even if you use epub builders" | Explicit EPUB opt-in must preserve generation. | Encoded in claim `EPUB-ENABLED-FALLTHROUGH`. |
| E6 | code | `EpubBuilder(StandaloneHTMLBuilder)` and `gen_pages_from_extensions()` emits `html-collect-pages` | `collect_pages` is the page-emission boundary for EPUB too. | Used to localize the proof target. |
| E7 | code | V1 guard in `collect_pages`: `if app.builder.name.startswith("epub") and not env.config.viewcode_enable_epub: return` | Candidate implementation enforces E1/E3 at the generation boundary. | Proved by symbolic rule 1. |

## Formal Model

The K model is in `fvk/mini-viewcode.k`; claims are in
`fvk/viewcode-spec.k`.

The abstraction is:

- `IS_EPUB`: `app.builder.name.startswith("epub")`
- `ENABLE_EPUB`: `env.config.viewcode_enable_epub`
- `HAS_MODULES`: whether `_viewcode_modules` exists and has usable entries
- `ENTRIES`: an abstract nonempty set of module entries
- `.Pages`: no generated viewcode pages
- `pagesFor(ENTRIES)`: the existing page generation behavior

Primary claim:

`collectPages(true, false, HAS_MODULES, ENTRIES) => .Pages`

This is intentionally quantified over `HAS_MODULES`; the issue path is a reused
environment where `HAS_MODULES` may be true because HTML populated the cache.

Frame claims:

- `collectPages(false, ENABLE_EPUB, true, ENTRIES) => pagesFor(ENTRIES)`
- `collectPages(true, true, true, ENTRIES) => pagesFor(ENTRIES)`
- if the disabled EPUB guard is false and `HAS_MODULES` is false, output is
  `.Pages`

## Formal Spec English

Claim `EPUB-DISABLED-NO-PAGES`: for every module-cache state, an EPUB builder
with `viewcode_enable_epub` false returns from `collect_pages` without yielding
any page tuple.

Claim `NON-EPUB-FALLTHROUGH`: a non-EPUB builder with module entries still uses
the existing generation path.

Claim `EPUB-ENABLED-FALLTHROUGH`: an EPUB builder with
`viewcode_enable_epub` true and module entries still uses the existing
generation path.

Claim `NO-MODULES-NO-PAGES`: outside the disabled-EPUB guard, absence of module
data still yields no pages.

## Spec Audit

`EPUB-DISABLED-NO-PAGES`: pass. It directly matches E1, E2, E3, and E4.

`NON-EPUB-FALLTHROUGH`: pass. It is a frame condition from E3/I3, preserving
behavior outside the reported EPUB default path.

`EPUB-ENABLED-FALLTHROUGH`: pass. It is required by E5.

`NO-MODULES-NO-PAGES`: pass. It preserves pre-existing behavior and does not
conflict with any public intent.

No formal-English claim is candidate-derived without public support. The only
implementation evidence is used for localization and frame conditions.

## Public Compatibility Audit

Changed public symbol: none. V1 changes only the body of
`sphinx.ext.viewcode.collect_pages`.

Function signature: unchanged.

Event registration: unchanged; `collect_pages` remains connected to
`html-collect-pages`.

Return protocol: unchanged; it is still a generator function that may yield page
tuples or stop without yielding.

Public call sites: `StandaloneHTMLBuilder.gen_pages_from_extensions()` still
iterates over the handler result. The early `return` in a generator means the
generator stops without yielding, which matches the existing no-module return
shape.

Subclass/override compatibility: no method signature or virtual dispatch shape
changed.

Compatibility status: pass.
