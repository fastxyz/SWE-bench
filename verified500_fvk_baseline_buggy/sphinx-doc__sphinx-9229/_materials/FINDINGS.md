# FVK Findings

Status: constructed, not machine-checked. Findings are based on public intent,
source inspection, and the constructed proof obligations.

## F1: V1 Missed Dependency Recording For Class-Alias Source Comments

- Classification: code bug in V1, fixed in V2.
- Evidence: V1 made `ClassDocumenter.get_docstring_comment()` read
  `ModuleAnalyzer.for_module(self.modname)` so class aliases could use comments
  from the aliasing module. That analyzer source was not added to
  `directive.record_dependencies`.
- Input -> observed vs expected:
  - Input: explicit documentation of a class/type alias whose target object has
    a different real module, with a next-line docstring in the aliasing module.
  - V1 observed: the docstring could be rendered, but the aliasing source file
    was not necessarily recorded by the class-alias path.
  - Expected: any source file used for autodoc content is recorded for rebuilds.
- Resolution: V2 records `analyzer.srcname` before returning class-alias source
  comments.
- Proof obligation: PO4 and PO5.

## F2: Legacy Alias Fallback Expectations Are SUSPECT

- Classification: public-test/spec conflict, not a blocker to the fix.
- Evidence: visible legacy expectations include both a source docstring and
  generated `alias of ...` for documented aliases, while the issue explicitly
  asks to show docstrings "instead of" `alias of ...`.
- Input -> observed vs expected:
  - Input: documented `typing.List[int]`, `Dict[...]`, or `Callable[...]` alias.
  - Legacy observed: source docstring plus or instead of generated fallback.
  - Expected from issue: source docstring content, with fallback suppressed.
- Resolution: do not preserve legacy fallback for documented aliases.
- Proof obligation: PO1, PO2, PO3, and PO4.

## F3: Directive Body Content Is Out Of The Public Issue Scope

- Classification: underspecified intent / residual risk.
- Evidence: the issue is about source next-line docstrings, not explicit content
  placed inside an `.. autodata::` or `.. autoclass::` directive body.
- Input -> observed vs expected:
  - Input: undocumented alias with manual directive body content.
  - V2 observed: core fallback behavior may still be combined with manual
    content depending on the documenter path.
  - Expected: not specified by the issue.
- Resolution: no code change. Do not use this underspecified case to reject V2.
- Proof obligation: PO7.

## F4: Constructed Proof Not Machine-Checked

- Classification: proof capability / environment gap.
- Evidence: task forbids running K tools, tests, or Python.
- Input -> observed vs expected:
  - Input: `kompile`/`kprove` commands emitted in the artifacts.
  - Observed: commands were not executed.
  - Expected before deleting tests: machine-check returns `#Top`.
- Resolution: keep tests; treat proof as constructed evidence only.
- Proof obligation: PO8.
