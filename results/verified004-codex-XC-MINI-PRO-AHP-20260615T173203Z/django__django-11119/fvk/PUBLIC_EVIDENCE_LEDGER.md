# Public Evidence Ledger

| ID | Source | Evidence | Semantic Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "Engine.render_to_string() should honor the autoescape attribute" | Method-created contexts must use `Engine.autoescape`. | Encoded in `HONOR-ENGINE-AUTOESCAPE` claim. |
| E2 | prompt | "a Context is created without specifying the engine autoescape attribute" | The problematic path is context construction inside `Engine.render_to_string()`. | Encoded as the plain-context path. |
| E3 | prompt | "if you create en engine with autoescape=False and then call its render_to_string() method, the result will always be autoescaped" | Concrete discriminator: `engine.autoescape=False` with a non-`Context` context must render with autoescape disabled, not enabled. | Encoded in the concrete false claim and Finding F-001. |
| E4 | source comment | "Preserve this ability but don't rewrap `context`." | Caller-supplied `Context` objects keep their own autoescape value. | Encoded in `PRESERVE-EXISTING-CONTEXT` claim. |
| E5 | source code | `Context.__init__(..., autoescape=True, ...)` stores `self.autoescape = autoescape`. | Without passing the engine value, a newly created `Context` defaults to `True`. | Root cause evidence for F-001. |
| E6 | source code | backend `Template.render()` calls `make_context(..., autoescape=self.backend.engine.autoescape)`. | The backend render path establishes an existing Django convention for propagating engine autoescape into created contexts. | Supports the V1 edit as aligned with existing code. |
| E7 | source code | template rendering reads `context.autoescape` in variable/filter/tag rendering paths. | The autoescape flag is an observable rendering input, not dead state. | Supports model observable `rendered(Bool)`. |
