# sphinx-doc__sphinx-9229 - FVK confirmed baseline-buggy analysis

- **Verdict:** CONFIRMED baseline-buggy. Both baseline and FVK have
  `resolved: true` in the official eval reports, but baseline introduced a new
  class-alias source-comment path without recording the source file as an
  autodoc rebuild dependency. FVK fixed the missing dependency frame condition.
- **Primary FVK finding:** `F1: V1 Missed Dependency Recording For Class-Alias
  Source Comments`.
- **Proof status:** constructed, not machine-checked. The FVK artifacts provide
  K claims and proof obligations, but the recorded run did not execute `kprove`.

## The issue

The public issue concerns type/class aliases documented by source next-line
comments. For documented aliases, autodoc should show the user-written source
comment instead of generated fallback text such as `alias of ...`.

Some aliases route through `ClassDocumenter.doc_as_attr`. Baseline changed that
path so `ClassDocumenter` could find comments from the aliasing module.

## What baseline did

Baseline added `ClassDocumenter.get_docstring_comment()` and, for class aliases,
loaded the analyzer for `self.modname`:

```python
analyzer = ModuleAnalyzer.for_module(self.modname)
analyzer.analyze()
key = (".".join(self.objpath[:-1]), self.objpath[-1])
if key in analyzer.attr_docs:
    return list(analyzer.attr_docs[key])
```

That made the rendered content pass the official class-alias doccomment test.
The missing part is that this new analyzer source was not added to
`self.directive.record_dependencies`.

## Why baseline is buggy

Sphinx autodoc content is not only a one-shot render. It also participates in
incremental rebuilds. When autodoc reads source comments from a file, that file
must be recorded as a dependency so later edits invalidate the generated
documentation.

Baseline created a new source-read path for class-alias comments but did not
record the analyzer source. The visible HTML/text output can be correct on the
first build while incremental rebuilds miss later changes to the aliasing source
file.

That is a correctness bug in Sphinx's build model: generated documentation can
become stale even though the source content it depends on changed.

## What FVK changed and why

FVK kept the baseline alias-docstring behavior and added dependency recording
before returning the source comments:

```python
self.directive.record_dependencies.add(analyzer.srcname)
return list(analyzer.attr_docs[key])
```

The FVK formal argument is claim 3 in `FORMAL_SPEC_ENGLISH.md`: for a
`ClassDocumenter.doc_as_attr` alias with a source docstring-comment in the
aliasing module/class scope, autodoc emits user doc content, suppresses the
generated alias fallback, and records the aliasing source file as a dependency.

This is a frame condition over the new content path. If a patch introduces a new
source file read for rendered autodoc content, it must preserve Sphinx's
existing dependency-recording invariant.

## Concrete demonstration

The failure shape is:

1. A module defines a class/type alias with a next-line source comment.
2. Autodoc documents the alias through the `ClassDocumenter.doc_as_attr` path.
3. Baseline reads the aliasing module's comment and renders it.
4. The aliasing source file changes.
5. Because baseline did not record `analyzer.srcname`, the incremental rebuild
   can fail to notice that the rendered autodoc content depends on that file.

FVK records the dependency at the same time it consumes the analyzer's
`attr_docs`, so the source-comment read is visible to the rebuild graph.

## Why the tests missed it

The official FAIL_TO_PASS test is:

```text
tests/test_ext_autodoc_autoclass.py::test_class_alias_having_doccomment
```

It verifies rendered content for the class-alias doccomment path. It does not
exercise incremental rebuild invalidation or inspect `record_dependencies`.
Baseline and FVK therefore both pass the official tests, but only FVK preserves
the dependency invariant.

## Gold comparison

The official gold patch takes a different implementation path through
`get_variable_comment()`. It does not directly confirm the one-line FVK change.

This case is retained because the FVK bug is specific to the baseline
implementation: once baseline chooses to read class-alias comments through a
new analyzer lookup, it must record that analyzer source. FVK fixes that real
incremental-build defect without changing the public alias-docstring behavior.

## Evidence files

- FVK findings: [_materials/FINDINGS.md](_materials/FINDINGS.md)
- FVK formal spec: [_materials/FORMAL_SPEC_ENGLISH.md](_materials/FORMAL_SPEC_ENGLISH.md)
- FVK notes: [_materials/fvk_notes.md](_materials/fvk_notes.md)

## Confidence and caveats

Confidence is high that baseline missed a real Sphinx dependency invariant:
the patch diff isolates the FVK change to
`self.directive.record_dependencies.add(analyzer.srcname)`, and the FVK finding
ties it directly to the newly introduced analyzer read.

The caveat is that the official gold patch uses a different implementation
shape. This is not a gold-equality case; it is a baseline-specific correctness
fix validated by Sphinx's rebuild-dependency model.
