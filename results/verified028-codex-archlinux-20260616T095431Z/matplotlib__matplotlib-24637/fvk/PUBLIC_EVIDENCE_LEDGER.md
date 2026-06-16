# Public Evidence Ledger

| ID | Source | Quote or code evidence | Obligation |
| --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "aim is to set the artist gid associated with each image so I can access them later when saved to an svg" | Parent annotation gid must be visible in SVG output. |
| E2 | `benchmark/PROBLEM.md` | `ab.set_gid('My_label')` and `GID = My_label`, but the saved SVG lacks the label | `get_gid()` returning `My_label` is insufficient unless the draw path passes it to the renderer. |
| E3 | `benchmark/PROBLEM.md` hints | "wrap the entire AnnotationBbox in a svg element with that gid" | Use a parent renderer group around the composite annotation. |
| E4 | `repo/lib/matplotlib/offsetbox.py` | `AnnotationBbox.draw` draws optional `arrow_patch`, then `patch`, then `offsetbox` | The group must enclose this full sequence without reordering it. |
| E5 | `repo/lib/matplotlib/backends/backend_svg.py` | `open_group` starts `<g>` with `id=gid` when `gid` is supplied | Passing `gid` to `open_group` is the renderer mechanism for the SVG id. |
| E6 | `repo/lib/matplotlib/backend_bases.py` | RendererBase defines `open_group` and `close_group` as SVG-only hooks | The fix can call existing renderer API methods without changing renderer contracts. |
| E7 | `repo/lib/matplotlib/legend.py`, `repo/lib/matplotlib/table.py` | Composite artists open groups after visibility checks and close them after child drawing | `AnnotationBbox` should follow the same grouping shape. |
