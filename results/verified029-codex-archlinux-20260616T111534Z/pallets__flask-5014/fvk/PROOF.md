# Constructed Proof

Status: constructed, not machine-checked. No K tooling, Python, or tests were executed.

## Claims Proved

- `C-INIT-EMPTY`: `Blueprint.__init__` raises `ValueError` when `name == ""`.
- `C-INIT-DOTTED`: the existing dotted-name `ValueError` remains for non-empty dotted names.
- `C-INIT-NONEMPTY`: valid non-empty, non-dotted constructor names still initialize `self.name`.
- `C-REGISTER-EMPTY-OVERRIDE`: `Blueprint.register` raises `ValueError` when `options["name"] == ""`.
- `C-REGISTER-EMPTY-DEFAULT`: `Blueprint.register` raises `ValueError` when the stored blueprint name is already `""`.
- `C-REGISTER-NONEMPTY-NOCONFLICT`: non-empty effective names fall through the new guard to the previous registration path.

## Proof Sketch

### Constructor

Symbolic state begins at the first V1 guard after `Scaffold.__init__`.

Case 1: `name == ""`.

The new guard condition is true, so the next transition is to `raise ValueError`. The assignment `self.name = name` is syntactically after this branch and is unreachable on this path. This discharges PO-1.

Case 2: `name != ""` and `name` contains `"."`.

The empty-name guard is false. Execution reaches the pre-existing dotted-name guard, which raises `ValueError`. V1 did not alter this branch. This discharges PO-3.

Case 3: `name != ""` and `name` does not contain `"."`.

Both validation guards are false. Execution reaches `self.name = name` and the existing initialization assignments. Since the only V1 constructor edit was the false guard above this point, the normal path is unchanged. This discharges PO-2 and the constructor portion of PO-7.

### Registration

Symbolic state begins after:

```python
name_prefix = options.get("name_prefix", "")
self_name = options.get("name", self.name)
```

Case 1: `self_name == ""`.

The new guard is true and raises `ValueError`. The later statements that compute `name`, check duplicates, mutate `app.blueprints`, set `_got_registered_once`, create setup state, register static rules, merge callback dictionaries, run deferred functions, register CLI commands, and register nested blueprints are after the raising branch and are unreachable on this path. This discharges PO-4.

Case 2: `self_name != ""`.

The new guard is false. Control reaches the pre-existing computation:

```python
name = f"{name_prefix}.{self_name}".lstrip(".")
```

The remaining duplicate-name and registration behavior is syntactically unchanged by V1. This discharges PO-5 and the registration portion of PO-7 for the no-conflict branch modeled in K. Existing duplicate-name behavior is outside the empty-name change and remains on the same path as before.

### Nested Registration

Nested blueprint options are stored by `Blueprint.register_blueprint`. During parent registration, each child is applied through:

```python
bp_options["name_prefix"] = name
blueprint.register(app, bp_options)
```

Therefore the child registration reaches the same `self_name = options.get("name", self.name)` guard. If nested `name=""` was recorded, PO-4 applies. This discharges PO-6.

## Adequacy

The formal claims prove the same behavior required by the intent spec: empty blueprint names, including effective names introduced through `name=`, raise `ValueError`. The claims do not prove broader validation for whitespace-only names, non-string values, or dotted registration overrides, because those are not required by the public issue.

## Machine-Check Commands

These commands are emitted for later checking only. They were not run.

```sh
kompile fvk/mini-python-blueprint.k --main-module MINI-PYTHON-BLUEPRINT --syntax-module MINI-PYTHON-BLUEPRINT-SYNTAX --backend haskell
kast --backend haskell fvk/blueprint-name-spec.k
kprove fvk/blueprint-name-spec.k --definition fvk/mini-python-blueprint-kompiled
```

Expected machine-check result: `#Top`.

## Test Recommendation

No tests were modified. If public tests are later added for `Blueprint("", __name__)` and `app.register_blueprint(bp, name="")`, they are direct instances of the constructed claims and would be candidates for redundancy only after the K proof is machine-checked. Integration tests for endpoint routing, CLI registration, nested blueprints, and duplicate-name behavior should be kept.
