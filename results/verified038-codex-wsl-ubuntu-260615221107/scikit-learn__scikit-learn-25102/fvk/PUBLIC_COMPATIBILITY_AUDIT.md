# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Symbol: `SelectorMixin.transform`

- Public signature before: `transform(self, X)`
- Public signature after: `transform(self, X)`
- Compatibility: pass. No argument or return protocol is added. Return type changes only under the already-supported pandas output configuration.

## Changed Helper: `SelectorMixin._transform`

- Public status: private helper by convention.
- Callers: shared implementation calls from `SelectorMixin.transform`; no public signature is changed.
- Compatibility: pass. Dense and sparse selection semantics remain selected-column behavior.

## New Helper: `_is_pandas_output_configured`

- Public status: private module helper.
- Compatibility: pass. It is not exported and does not require subclass participation.

## Subclasses Of `SelectorMixin`

Audited source subclasses:

- `_BaseFilter` and its public variants: `SelectPercentile`, `SelectKBest`, `SelectFpr`, `SelectFdr`, `SelectFwe`, `GenericUnivariateSelect`
- `VarianceThreshold`
- `SelectFromModel`
- `RFE`
- `SequentialFeatureSelector`

Compatibility: pass. All continue to provide `_get_support_mask`; none must override `transform` or accept new parameters.

## `set_output` Wrapper

- The existing `_SetOutputMixin` wrapping protocol remains unchanged.
- `_wrap_data_with_container` still applies feature names and index for pandas output.
- Compatibility: pass. No changes to `_SetOutputMixin`, `_wrap_in_pandas_container`, or public `set_output` values.

## Potential Behavior Change Audited

When pandas output is configured and the input is a pandas `DataFrame`, selectors now return selected original columns, so downstream consumers may see preserved pandas dtypes instead of homogeneous converted dtypes. This is the intended behavior change for the issue.

No unhandled public callsite or override was found in the audited source files.
