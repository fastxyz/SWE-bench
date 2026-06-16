# FVK Specification: `pyplot.set_cmap`

Status: constructed from public intent and source inspection; not
machine-checked.

Formal core:

- `fvk/mini-pyplot-cmap.k`
- `fvk/pyplot-set-cmap-spec.k`

## Scope

The audited units are:

- `matplotlib.pyplot.set_cmap`
- `matplotlib.cm.ColormapRegistry.get_cmap` for the `None` default path
- `matplotlib.cm._ensure_cmap` for the `None` default path

No loops are present in these units. The model is a small state machine over:

- a colormap registry mapping registered names to `Colormap` objects;
- `rcParams["image.cmap"]`, represented as either a registered name or a
  `Colormap` object;
- the optional current image and its assigned colormap.

## Intent Spec

1. A colormap registered under a public name must be usable by that registered
   name in pyplot APIs, even if the `Colormap.name` stored inside the object is
   different.
2. `pyplot.set_cmap(name)` sets the default colormap used by later image
   creation and applies the resolved colormap to the current image if one
   exists.
3. Invalid colormap names must continue to fail during colormap resolution,
   before `rcParams` or any current image is mutated.
4. `pyplot.set_cmap(cmap_obj)` is valid because the public docstring accepts a
   `Colormap` instance.
5. `rcParams["image.cmap"]` may be a `Colormap` instance, so default-colormap
   resolution must return that object directly when the rcParam stores one.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation |
| --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | The issue registers `my_cmap_name` for a colormap whose own name is `some_cmap_name`, then expects `plt.set_cmap("my_cmap_name")` and later `imshow` to work. | Preserve and store the registered string key on the string input path. |
| E2 | `benchmark/PROBLEM.md` public hint | The hint says the passed name is only used for lookup and the rcParam is set to the wrong value. | The bug is in the value written to `image.cmap`, not in registry lookup. |
| E3 | `repo/lib/matplotlib/cm.py` register docstring | A registered colormap name can be used in `get_cmap` or `image.cmap`. | `image.cmap` must contain a registered key when the caller supplied one. |
| E4 | `repo/lib/matplotlib/pyplot.py` docstring | `set_cmap` takes a `Colormap` or `str` and applies it to the current image if any. | Both string and object inputs are in-domain; current-image branch must be preserved. |
| E5 | `repo/doc/users/prev_whats_new/whats_new_3.4.0.rst` | `image.cmap` may be set to a `Colormap` instance from Python code. | Object-valued defaults must be resolved by default lookup helpers. |
| E6 | `repo/lib/matplotlib/rcsetup.py` | `_validate_cmap` accepts `str` or `Colormap`. | Storing a `Colormap` object in `image.cmap` is validator-compatible. |
| E7 | `repo/lib/matplotlib/cm.py` implementation comment | `_ensure_cmap` uses `check_in_list` to preserve ValueError vs KeyError. | Invalid strings remain errors before mutation. |

## Formal Claims In English

Claim C1: If `setCmap(str(ALIAS))` is called with `ALIAS` present in the
registry and the registry maps it to colormap `C`, then the final rc default is
`rcName(ALIAS)`. A following default-colormap lookup returns `C`. This holds
even when `C` has an internal name different from `ALIAS`; the internal name is
not part of the postcondition.

Claim C2: If a current image exists, `setCmap(str(ALIAS))` assigns the resolved
colormap `C` to that image and still stores `rcName(ALIAS)` as the future
default.

Claim C3: If `setCmap(obj(C))` is called with a `Colormap` object, the rc
default becomes `rcObj(C)`. A following default-colormap lookup returns `C`.

Claim C4: If `rcParams["image.cmap"]` is already object-valued, default lookup
returns that object directly.

Claim C5: If `setCmap(str(BAD))` is called with an unregistered name, the
function reaches the invalid-name result before mutating `image.cmap` or any
current image.

## Adequacy Audit

| Claim | Intent coverage | Result |
| --- | --- | --- |
| C1 | Covers E1, E2, and E3 exactly: registered aliases remain the default key. | Pass |
| C2 | Covers E4's current-image side effect for string inputs. | Pass |
| C3 | Covers E4 and E5 for direct `Colormap` inputs. | Pass |
| C4 | Covers E5 and E6 for object-valued rcParams used through default lookup. | Pass |
| C5 | Covers E7 and preserves existing invalid-name error ordering. | Pass |

No claim relies on hidden tests, benchmark outcomes, internet access, or the
upstream patch.

## Compatibility Audit

- Public signatures are unchanged.
- `pyplot.set_cmap("name")` still validates through `get_cmap` before mutating
  rcParams and still applies the resolved colormap to the current image.
- For string inputs, `rcParams["image.cmap"]` remains a string registered name.
  This preserves the public workaround and avoids surprising code that inspects
  the rcParam after string-based `set_cmap`.
- For `Colormap` inputs, `rcParams["image.cmap"]` now stores the object rather
  than the object's `.name`. This is compatible with the rc validator and with
  documented support for object-valued `image.cmap`.
- `ColormapRegistry.get_cmap(None)` and `_ensure_cmap(None)` now accept the
  same object-valued rcParam form that `_get_cmap(None)` already accepted.
- No tests were modified.
