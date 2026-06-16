# FVK Findings

Status: constructed, not machine-checked. Findings are based on public issue intent, repository docs, and source inspection only.

## F-001: Empty Constructor Name Was Accepted

Classification: code bug, resolved by V1.

Input:

```python
Blueprint("", __name__)
```

Pre-V1 observed behavior by source inspection: the constructor accepted `name == ""` because it only rejected names containing `"."`, then assigned `self.name = ""`.

Expected behavior from E1: raise `ValueError` when a blueprint is given an empty name.

V1 audit result: resolved by `if name == "": raise ValueError(...)` in `Blueprint.__init__`.

Proof obligations: PO-1, PO-2, PO-3.

## F-002: Empty Registration Override Could Still Create an Empty Effective Name

Classification: code bug, resolved by V1.

Input:

```python
bp = Blueprint("bp", __name__)
app.register_blueprint(bp, name="")
```

Pre-V1 observed behavior by source inspection: `self_name = ""`, then `name = f"{name_prefix}.{self_name}".lstrip(".")`, which can produce `""`. The registration path could then store the blueprint under an empty key and create unprefixed endpoints.

Expected behavior from E1 and E4: `name=""` is a pre-dotted registration name override, so it must be rejected with `ValueError`.

V1 audit result: resolved by `if self_name == "": raise ValueError(...)` in `Blueprint.register`.

Proof obligations: PO-4, PO-5.

## F-003: Nested `name=""` Is Covered at Effective Registration Time

Classification: no additional code change required.

Input shape:

```python
parent.register_blueprint(child, name="")
app.register_blueprint(parent)
```

Audit result: `Blueprint.register_blueprint` records nested options. During parent registration, the child is registered through `blueprint.register(app, bp_options)`, with `bp_options["name_prefix"] = name`. The V1 `Blueprint.register` guard evaluates `self_name = options.get("name", self.name)` and rejects `self_name == ""`.

Expected behavior: `ValueError` is raised when the nested blueprint registration becomes effective on the app. The public issue does not require the earlier option-recording call to raise before app registration.

Proof obligations: PO-4, PO-6.

## NF-001: Whitespace-Only Names Are Not Covered by the Public Intent

Classification: rejected alternative.

Input shape:

```python
Blueprint(" ", __name__)
```

Audit result: The phrase "empty name" supports rejecting `""`, not all strings that may be visually blank or undesirable. Expanding the guard to `if not name` or `if not name.strip()` would change behavior beyond the public issue and could alter handling of non-string values.

Decision: keep exact empty-string validation.

Proof obligations: PO-2, PO-7.

## NF-002: Dotted `name=` Registration Overrides Are Not Part of This Fix

Classification: rejected alternative.

Input shape:

```python
app.register_blueprint(bp, name="a.b")
```

Audit result: Existing source rejects dotted constructor names, but did not reject dotted registration override names before V1. The public issue asks for non-empty names, not dotted override validation. Changing this would be a separate compatibility decision.

Decision: do not add dotted `name=` override validation in this patch.

Proof obligations: PO-5, PO-7.

## Proof-Derived Findings

No blocking proof-derived finding remains against V1. The constructed branch proof discharges the empty-constructor and empty-effective-registration cases. The proof does not establish termination beyond the finite validation branches, and it is not machine-checked because K tooling was not run.

