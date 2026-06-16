# FVK Findings

Status: constructed findings; no tests or K tooling were run.

## F-01: Registered alias was not preserved by V0

Input:

`set_cmap("my_cmap_name")` where the registry maps `"my_cmap_name"` to a
colormap object whose internal `.name` is `"some_cmap_name"`.

Observed before the fix:

`pyplot.set_cmap` resolved the colormap, then wrote `cmap.name` into
`rcParams["image.cmap"]`. Later default image creation looked up
`"some_cmap_name"`, which could be unregistered.

Expected:

The default should remain the registered key supplied by the caller,
`"my_cmap_name"`, so later default colormap lookup uses the registry entry that
is known to exist.

Classification:

Code bug. Fixed by `PO-01` and `PO-02`.

## F-02: V1 used truthiness where the proof obligation is identity-based

Input:

Any successful string input to `set_cmap`.

Observed in V1:

The rc assignment used `cmap_name or cmap.name`, which relied on truthiness
rather than explicitly testing whether the caller supplied a string.

Expected:

The branch condition should be "did the caller supply a string name?" not "is
the saved name truthy?" Even though registered names are non-empty in practice,
the proof obligation is more precise with `is not None`.

Classification:

Proof/spec clarity issue. Fixed by `PO-01`.

## F-03: Object-valued `image.cmap` was only partially supported

Input:

`set_cmap(cmap_obj)` where `cmap_obj.name` is not a registered colormap name,
or any Python code that sets `rcParams["image.cmap"]` directly to a
`Colormap` object.

Observed in V1 and nearby code:

`set_cmap(cmap_obj)` still wrote `cmap_obj.name` to `image.cmap`; default
resolution in `ColormapRegistry.get_cmap(None)` and `_ensure_cmap(None)` then
assumed the rcParam was a registered string.

Expected:

The public pyplot docstring accepts a `Colormap` instance, and Matplotlib
documentation says `image.cmap` may be a `Colormap` object. Default lookup
helpers should return that object directly.

Classification:

Code bug / compatibility inconsistency. Fixed by `PO-04` and `PO-05`.

## F-04: Invalid-name ordering must remain unchanged

Input:

`set_cmap("not_registered")`.

Observed:

The code calls `get_cmap` before mutating `rcParams` or consulting the current
image.

Expected:

Invalid names should still fail during lookup and leave the default colormap
and current image unchanged.

Classification:

Positive preservation finding. Covered by `PO-06`; no source change beyond the
existing call ordering was required.

## Residual Risks

- The K proof is constructed but not machine-checked because this session must
  not run `kompile`, `kprove`, tests, Python, or project code.
- The formal model abstracts away Matplotlib object-copy details. That is
  adequate for this issue because the defect is whether default lookup uses the
  registered key or an object/default value, not whether registry copies share
  identity with the caller's original object.
