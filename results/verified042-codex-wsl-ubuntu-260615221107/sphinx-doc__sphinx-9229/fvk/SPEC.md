# FVK Spec: Autodoc Type-Alias Docstrings

Status: constructed, not machine-checked. No tests, Python, or K tools were run.

## Intent-Only Spec

1. Source type aliases documented with next-line docstrings must render those
   docstrings.
2. For documented type aliases, generated fallback text such as `alias of ...`
   must not replace or accompany the user docstring as the primary content.
3. The behavior must be consistent across the type-alias family shown in the
   issue: `Dict[...]`, `Union[...]`, and `Callable[...]`.
4. Existing fallback text remains valid for undocumented aliases.
5. If autodoc reads source comments from a module to generate output, that source
   must remain part of the recorded dependency set used by Sphinx rebuild logic.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "3 multiline docstrings for type aliases" | Scope includes source-level next-line docstrings. | Encoded |
| E2 | prompt | "For 1 ... docstring is correctly shown ... for 2 ... ignored" | Audit all alias routes, not only the route already working. | Encoded |
| E3 | prompt | "show the contents in the docstrings for all the type aliases instead of ... `alias of ...`" | If a source docstring-comment exists, render it and suppress generated alias fallback. | Encoded |
| E4 | code | `Parser.visit_Expr()` records a string expression after `Assign`/`AnnAssign` as a variable comment. | Parser is not the defect; later documenter content selection is under audit. | Encoded |
| E5 | code | `GenericAliasMixin`, `NewTypeMixin`, `TypeVarMixin`, and `ClassDocumenter.doc_as_attr` synthesize fallback content. | Every fallback producer that can document aliases must honor the docstring-comment predicate. | Encoded |
| E6 | code | `Documenter.generate()` records analyzer sources as dependencies when it uses them. | The new class-alias source-comment analyzer lookup should also record its source. | Encoded |
| E7 | public tests | Visible legacy expectations include docstring plus alias fallback for some aliases. | SUSPECT: conflicts with E3 because it preserves behavior the issue calls the bug. | Finding F2 |

## Model

The formal model abstracts the full autodoc machinery to the observable needed
for this issue:

- `HasDocComment`: true when `ModuleAnalyzer.attr_docs` contains a source-level
  docstring-comment for the documented alias.
- `AliasKind`: `genericAlias`, `newType`, or `typeVar`.
- `renderDataAlias(kind, HasDocComment)`: data documenter alias path.
- `renderAttributeAlias(kind, HasDocComment)`: class attribute documenter alias
  path.
- `renderClassAlias(HasDocComment)`: `ClassDocumenter.doc_as_attr` alias path,
  used by Python 3.6-style typing aliases and ordinary class aliases.
- `result(docShown, aliasFallbackShown, dependencyRecorded)`: the observable
  content/dependency outcome.

The mini semantics is in `fvk/mini-autodoc-alias.k`; the claims are in
`fvk/autodoc-alias-spec.k`.

## Claims

1. `DATA-DOC-COMMENT-SUPPRESSES-FALLBACK`: for all data alias kinds, a source
   docstring-comment yields `result(true, false, false)`.
2. `ATTRIBUTE-DOC-COMMENT-SUPPRESSES-FALLBACK`: for all attribute alias kinds, a
   source docstring-comment yields `result(true, false, false)`.
3. `CLASS-ALIAS-DOC-COMMENT-SUPPRESSES-FALLBACK-AND-RECORDS-DEPENDENCY`: a
   class-alias source docstring-comment yields `result(true, false, true)`.
4. Undocumented data, attribute, and class aliases keep the fallback:
   `result(false, true, false)`.

## Preconditions and Frame Conditions

- The source analyzer can parse the module, or else `HasDocComment` is false.
- The documented object is routed through one of the modeled alias documenter
  paths.
- User extensions connected to `autodoc-process-docstring` may still mutate
  lines after autodoc chooses the source docstring; this audit covers core
  autodoc's selection and fallback generation.
- No public method signatures or directive option shapes change.

## Adequacy Audit

The formal claims match the intent: documented aliases show user docs without
fallback; undocumented aliases retain fallback behavior; class-alias source
comment reads are dependency-tracked. The abstraction preserves the property
under verification because it distinguishes the two outputs the issue contrasts:
user doc content vs generated `alias of ...` content.
