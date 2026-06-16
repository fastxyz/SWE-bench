# Public Evidence Ledger

| ID | Source | Public evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "When a figure is unpickled, it's dpi is doubled. This behaviour happens every time and if done in a loop it can cause an `OverflowError`." | Loading must not multiply an already high-DPI-scaled value again. | Encoded in O1, O4. |
| E2 | prompt expected output | The expected output prints `200.0` on every iteration after the initial `200.0`. | Repeated dump/load on the same high-DPI backend is DPI-idempotent. | Encoded in O4. |
| E3 | prompt actual output | The actual output doubles: `200.0`, `400.0`, `800.0`, ... | The old serialized value was the scaled runtime DPI and is SUSPECT legacy behavior, not a target behavior. | Recorded as resolved finding F1. |
| E4 | public hint | "anything that know how to deal with high-dpi screens" | The repair should be backend-neutral and live in shared figure serialization logic if possible. | Encoded in O1, O6. |
| E5 | public hint | "when we handle high-dpi cases by doubling the dpi on the figure ... when we show it. We are saving the doubled dpi which when re-loaded in doubled again." | Serialization should store logical DPI for high-DPI canvases, leaving backend attachment to reapply the ratio. | Encoded in O1, O4. |
| E6 | source `FigureCanvasBase._set_device_pixel_ratio` | `dpi = ratio * self.figure._original_dpi`; then `self.figure._set_dpi(dpi, forward=False)`. | `_original_dpi` is the implementation's logical-DPI state used to derive high-DPI runtime `_dpi`. | Encoded in O1, O3. |
| E7 | source `FigureCanvasBase.__init__` | `figure._original_dpi = figure.dpi`; `_device_pixel_ratio = 1`. | A newly attached canvas treats current `figure.dpi` as logical DPI before applying a later ratio. | Encoded in O3, O4. |
| E8 | source `print_figure` | `dpi == 'figure'` resolves to `getattr(self.figure, '_original_dpi', self.figure.dpi)`. | Existing savefig behavior already treats `_original_dpi` as the logical high-DPI DPI. | Supports O1. |
| E9 | source `Artist.__getstate__` | Figure state is a shallow copy of `__dict__`. | `_dpi`, `_original_dpi`, and `dpi_scale_trans` are all pickled unless figure serialization adjusts them. | Encoded in O1, O5. |
| E10 | source `Figure._set_dpi` | `_set_dpi` updates `_dpi` and clears/scales `dpi_scale_trans`. | If `_dpi` is normalized during serialization, unpickle must resync the transform. | Encoded in O5. |
| E11 | source public API shape | `Figure.__getstate__` and `Figure.__setstate__` signatures are unchanged by V1. | No public callsite or override compatibility break is introduced. | Encoded in O6. |
