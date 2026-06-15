# FVK Spec

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 fix for `django__django-11119`: `Engine.render_to_string()` should honor `Engine.autoescape` when it creates the rendering `Context`.

The formal model is intentionally small and property-complete for the issue. It abstracts template lookup and the escaping algorithm, and preserves the observable that distinguishes correct from buggy behavior: the `autoescape` flag seen by `Template.render()`.

Formal files:

- `fvk/mini-template-engine.k`
- `fvk/engine-render-to-string-spec.k`

## Public Intent Ledger

| ID | Source | Evidence | Obligation |
| --- | --- | --- | --- |
| E1 | prompt | "Engine.render_to_string() should honor the autoescape attribute" | Method-created contexts use `Engine.autoescape`. |
| E2 | prompt | "a Context is created without specifying the engine autoescape attribute" | The constructed-Context path is the defective path. |
| E3 | prompt | `autoescape=False` leads to an always-autoescaped result | Concrete false-valued engine case must render with autoescape disabled. |
| E4 | source comment | "Preserve this ability but don't rewrap `context`." | Existing `Context` instances keep their own settings. |
| E5 | source code | `Context.__init__(..., autoescape=True, ...)` | Omitting `autoescape` defaults new contexts to `True`. |
| E6 | source code | backend render passes `autoescape=self.backend.engine.autoescape` to `make_context()` | The V1 behavior matches an existing backend convention. |
| E7 | source code | template rendering reads `context.autoescape` | The flag is observable during rendering. |

## Contract

For any engine autoescape value `EA`:

- If `context` is not already a `Context`, `Engine.render_to_string()` must call `Template.render()` with a newly created `Context` whose `autoescape` is `EA`.
- If `context` is already a `Context`, `Engine.render_to_string()` must render that object unchanged; its own `autoescape` value controls rendering.
- The single-template and multi-template selection branches must both satisfy the same autoescape contract.

## Preconditions

The claims assume template lookup succeeds and the provided plain context is acceptable to `Context(...)`, matching the issue's dictionary/`None` scenario. Template-not-found errors and invalid context object types are outside this issue and unchanged by V1.

## Postconditions

The postcondition is stated as `rendered(autoescape_flag)` in the K model:

- `renderToString(EA, TN, plain) => rendered(EA)`
- `renderToString(false, TN, plain) => rendered(false)`
- `renderToString(EA, TN, existing(CA)) => rendered(CA)`

## Adequacy

The model distinguishes a passing and failing instance: for `EA=False` and a plain context, the legacy implementation corresponds to `rendered(true)`, while the intended behavior and V1 correspond to `rendered(false)`. Therefore the abstraction retains the property the issue measures.
