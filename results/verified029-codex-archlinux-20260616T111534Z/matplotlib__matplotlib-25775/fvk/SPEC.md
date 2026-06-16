# FVK Specification: Text Antialiasing

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were run.

## Scope

Target issue: `matplotlib__matplotlib-25775`, "Add get/set_antialiased to
Text objects".

The audited observable is the antialiasing value used for text font rendering:

- `Text` construction and `Text.set_antialiased`.
- `Text.draw` and `Annotation.draw`.
- AGG normal text and AGG raster mathtext consumption.
- Cairo normal text, Cairo mathtext, and Cairo graphics-context copying used by
  path effects.
- Backward compatibility for existing mathtext parser calls.

Out of scope by public evidence: TeX image generation via `TexManager`. That
path does not read `rcParams["text.antialiased"]` in the inspected source and
uses a pre-rendered image rather than the AGG/Cairo font-antialiasing hooks
named by the issue hints.

## Intent Spec

I1. `Text` must expose a per-artist antialiasing property with
`get_antialiased` and `set_antialiased`.

I2. `Text(..., antialiased=None)` and `Text.set_antialiased(None)` must default
to `rcParams["text.antialiased"]`, matching the existing artist convention used
by patch antialiasing.

I3. An explicit text antialiasing value must override the global rcParam for
that `Text` instance.

I4. `Text.draw` must transfer the stored per-artist antialiasing value into the
`GraphicsContext` before backend text rendering.

I5. `Annotation` must inherit the same text antialiasing behavior because it is
a `Text` subclass and delegates final text rendering to `Text.draw`.

I6. Backends that support font antialiasing in this source tree, AGG and Cairo,
must consume `GraphicsContext` antialiasing state instead of reading
`rcParams["text.antialiased"]` directly during font rendering.

I7. Existing public calls to `MathTextParser("agg").parse(s, dpi, prop)` must
keep their rcParam-based behavior when no per-artist/GC antialiasing value is
provided.

## Public Evidence Ledger

| ID | Source | Quoted evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | problem | "Add get/set_antialiased to Text objects" | Add Text getter/setter API. | Encoded by PO-01 and PO-02. |
| E2 | problem | "per-artist basis via `set_antialiased`" | Explicit Text value must be stored per object. | Encoded by PO-01 and PO-02. |
| E3 | problem | "use that info in the drawing stage" | Draw must push Text AA to the graphics context. | Encoded by PO-03. |
| E4 | problem | "adjusting Annotations accordingly" | Annotation text rendering must use the same Text AA. | Encoded by PO-07. |
| E5 | problem | "replace the access to `rcParams[\"text.antialiased\"]` by going through the GraphicsContext state" | Backend text rasterization must consume GC AA, not direct rcParam lookup. | Encoded by PO-03 through PO-06. |
| E6 | problem hint | "only AGG and Cairo backends support customizing font antialiasing" | Backend implementation work is required for AGG and Cairo. | Encoded by PO-04 through PO-06. |
| E7 | source convention | `Patch.set_antialiased(None)` falls back to `rcParams['patch.antialiased']`. | Text `None` should snapshot `rcParams["text.antialiased"]`. | Encoded by PO-01. |
| E8 | implementation | `Annotation.draw` ends by calling `Text.draw(self, renderer)`. | No annotation-specific backend path is needed if Text.draw is correct. | Encoded by PO-07. |
| E9 | implementation | Path effects copy GCs before drawing paths. | Copied Cairo GCs must synchronize copied AA state into the cairo context. | Finding F1, encoded by PO-06. |
| E10 | implementation | Existing mathtext parser callsites omit an antialiasing keyword. | New parser keyword must be optional and default to rcParam behavior. | Encoded by PO-08. |

## Formal Artifacts

The formal core is:

- `fvk/mini-matplotlib-text.k`: a minimal K model for Text AA state, GC AA
  state, backend consumption, and Cairo GC copying.
- `fvk/matplotlib-text-antialias-spec.k`: K reachability claims with
  `SPEC-PROVENANCE` comments tied to the public evidence ledger.

The model intentionally abstracts away text layout, color, alpha, URL, and
clipping. Those are frame properties for this issue: the patch should preserve
their existing transfer through the GC while adding antialiasing.

## Formal Spec English

FE-01. If `Text` is initialized or reset with `antialiased=None`, its stored AA
state becomes the current `rcParams["text.antialiased"]`.

FE-02. If `Text` is initialized or reset with `antialiased=B`, or if
`set_antialiased(B)` is called, `get_antialiased()` observes `B`.

FE-03. When a visible non-empty `Text` draws, the graphics context's AA state is
set to the Text object's stored AA value before text backend dispatch.

FE-04. `Annotation` text rendering has the same AA result as `Text` rendering.

FE-05. AGG normal text glyph rasterization consumes `gc.get_antialiased()`.

FE-06. AGG raster mathtext glyph rendering consumes the same GC-derived AA
value, and the mathtext raster cache distinguishes the two AA choices.

FE-07. Cairo normal text and Cairo mathtext set cairo font options from
`gc.get_antialiased()`.

FE-08. Cairo graphics-context copies preserve AA state in both Python storage
and the cairo context, so text drawn as paths through path effects observes the
Text AA value.

FE-09. Existing raster mathtext parser calls without the new keyword continue
to resolve AA from `rcParams["text.antialiased"]`.

## Spec Audit

| Formal English | Intent match | Result |
| --- | --- | --- |
| FE-01 | Matches I2 and E7. | Pass |
| FE-02 | Matches I1 and I3. | Pass |
| FE-03 | Matches I4 and E3/E5. | Pass |
| FE-04 | Matches I5 and E4/E8. | Pass |
| FE-05 | Matches I6 and E5/E6 for AGG normal text. | Pass |
| FE-06 | Matches I6 for AGG raster mathtext, which uses the same FT2 glyph AA hook. | Pass |
| FE-07 | Matches I6 and E5/E6 for Cairo text. | Pass |
| FE-08 | Matches I4/I6 for the path-effect dispatch path discovered in E9. | Pass after V2 edit |
| FE-09 | Matches I7 and E10. | Pass |

No formal claim is intentionally derived from hidden tests, benchmark verdicts,
or upstream patches.

## Public Compatibility Audit

Changed public or semi-public symbols:

- `Text.__init__`: adds keyword-only `antialiased=None` before `**kwargs`.
  Existing calls remain source-compatible. Existing `antialiased=` kwargs now
  bind explicitly instead of flowing through `**kwargs`; behavior is intended.
- `Text.set_antialiased`, `Text.get_antialiased`, aliases `set_aa`/`get_aa`:
  additive API; no public override of `Text.set_antialiased` was found in the
  inspected source.
- `MathTextParser.parse`: adds optional keyword-only `antialiased=None`.
  Existing positional and keyword calls remain valid. The default preserves
  rcParam behavior.
- `GraphicsContextCairo.set_antialiased` and `copy_properties`: no public
  signature break. The implementation now keeps the base GC state and cairo
  context state aligned.

Compatibility result: pass.
