# FVK Notes

## Decisions

V1 stands unchanged. The FVK audit found the original bug as F-001 and discharged it through PO-001: `Engine.render_to_string()` creates plain contexts with `autoescape=self.autoescape`. The current source already contains that exact edit, so no further source change is warranted.

The existing `Context` branch remains unchanged. F-002 and PO-002 trace this to the source comment preserving backwards-compatible acceptance of `Context` objects without rewrapping them. Overriding a supplied `Context` with the engine setting would satisfy the reported plain-context case but violate that explicit compatibility obligation.

No template-selection change was made. F-003 and PO-003 show that both single-name and list/tuple template paths converge before context handling, so the root cause is not in `get_template()` or `select_template()`.

No API or callsite compatibility change was made. F-004 and PO-005 show that the method signature, return protocol, and virtual dispatch shape are unchanged, and `Context.__init__()` already accepts the `autoescape` keyword used by V1.

## Artifact Changes

The FVK package under `fvk/` records the intent, evidence, formal model, proof obligations, constructed proof, and iteration guidance. The proof is labeled constructed but not machine-checked, and `fvk/PROOF.md` records the `kompile`, `kast`, and `kprove` commands instead of executing them.

## Execution Constraints

No tests, Python code, or K tooling were run. No test files were modified.
