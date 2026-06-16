# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Managed include uses source-read result

For any non-standard `.. include:: FILE`, if the raw include file text is `SRC`
and `source-read` handlers transform it to `SRC2`, the text inserted by docutils
is `SRC2`, not `SRC`.

Status: discharged by V2 helper wrapping docutils `FileInput.read()` and
returning `arg[0]`.

## PO-2: Included docname selection

The event docname is `env.path2doc(FILE)` when available; otherwise it falls
back to `env.docname`.

Status: discharged by `docname = env.path2doc(filename) or env.docname`.

## PO-3: Existing include behavior is delegated

Path resolution, `env.note_included()`, docutils options, dependency recording,
and insertion semantics remain owned by the existing Sphinx/docutils include
path.

Status: discharged because `Include.run()` still resolves the path, calls
`env.note_included(filename)`, and returns `super().run()` inside the wrapper.

## PO-4: FileInput interception and restoration are complete

During a managed include read, both supported docutils lookup channels for
`FileInput` are replaced by the wrapper; after the read returns or raises, both
are restored.

Status: V1 only patched `docutils.io.FileInput`. FVK finding F-001 required the
V2 change that also patches a direct `FileInput` global in `BaseInclude.run`
when present, with restoration in `finally`.

## PO-5: Standard docutils includes are unchanged

Arguments of the form `<name>` take the old `return super().run()` path without
Sphinx path processing or include-side source-read emission.

Status: discharged by the existing early return, left unchanged.

## PO-6: Duration listener remains compatible

If a top-level source-read event is followed by one or more include-triggered
source-read events during the same document read, `duration` keeps the original
`started_at` timestamp.

Status: V1 did not discharge this. FVK finding F-002 required the V2 change to
only set `started_at` when it is absent.

## PO-7: No test or public API churn

The fix must not modify test files or public function signatures.

Status: discharged. Only production source files and FVK/report artifacts were
modified.
