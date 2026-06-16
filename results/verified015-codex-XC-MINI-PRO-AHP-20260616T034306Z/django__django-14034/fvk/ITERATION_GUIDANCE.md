# Iteration Guidance

## Verdict

V1 stands unchanged. The FVK audit found no source change justified by the
public intent, proof obligations, or compatibility audit.

## Why No V2 Source Edit

- F1 and PO-3 confirm the reported HTML `required` bug is addressed by V1.
- F2 and PO-6 reject a validation edit as contrary to the final public issue
  discussion and visible validation frame.
- F3 and PO-4 confirm V1 preserves required-all rendering.
- F4 and PO-5 confirm V1 preserves optional-parent rendering.
- PO-7 found no public compatibility blocker.

## Future Test Suggestions

Do not edit tests in this task. In a normal Django development environment, add
or keep tests for:

1. Required parent, `require_all_fields=False`, optional first subfield and
   required second subfield: only the second input renders `required`.
2. Optional parent, `require_all_fields=False`, required child subfield:
   no browser `required` attr is forced on all-empty submissions.
3. Required parent, `require_all_fields=True`: all subwidgets continue to render
   `required` when valid for the widget.
4. Partial-required field with a child widget whose `use_required_attribute()`
   returns false: that child does not render an invalid HTML `required` attr.

## Future Machine-Check Suggestions

The `.k` files are an abstraction of the Django render path, not a full Python
or Django semantics. A future FVK pass with K available should run the commands
in `PROOF.md` and decide whether any point tests are subsumed only after
`kprove` returns `#Top`.
