# FVK Specification: astropy__astropy-13033

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Target

The audited unit is `BaseTimeSeries._check_required_columns()` in
`repo/astropy/timeseries/core.py`, plus the decorator path that calls it after
column-mutating methods such as `remove_column`.

There are no loops in the audited unit. The proof obligation is a case analysis
over the required-column state and the current column prefix.

## Intent Spec

I1. When required-column checking is disabled, `_check_required_columns()` must
not reject the object.

I2. When `_required_columns` is `None`, there is no required-column contract to
check.

I3. Otherwise, `_required_columns` describes an ordered required prefix of the
table column names. In relaxed mode, only the prefix length already present in
`self.colnames` is checked; outside relaxed mode, the full list is required.

I4. If the active required prefix is missing or out of order, the object is
invalid and the exception must make the missing required prefix clear.

I5. For multi-column requirements, the invalid-column message must display the
full active required prefix and the found prefix of the same length. This is the
issue's central required behavior.

I6. Existing single-required-column messages should remain stable when possible,
because public in-repository tests assert those strings exactly and the issue is
about additional required columns.

I7. When relaxed mode has successfully accumulated the complete required prefix,
`_required_columns_relax` must be turned off so later mutations enforce the full
contract.

## Public Evidence Ledger

E1. Source: prompt issue. Quote: "TimeSeries: misleading exception when required
column check fails." Obligation: error behavior must report the relevant
required-column failure, not a misleading scalar comparison. Status: encoded by
I4 and I5.

E2. Source: prompt issue. Quote: "additional required columns (in addition to
`time`)" and "try to remove a required column". Obligation: the domain includes
objects whose `_required_columns` has length greater than one, including
post-mutation states where only an initial prefix remains. Status: encoded by
I3 and I5.

E3. Source: prompt issue expected behavior. Quote: "An exception that informs
the users required columns are missing." Obligation: invalid-state exceptions
must identify required columns. Status: encoded by I4 and I5.

E4. Source: prompt issue actual behavior. Quote: "expected 'time' as the first
columns but found 'time'". Obligation: this is a SUSPECT legacy display, because
the issue identifies it as the bug. Status: rejected as a spec in
`FINDINGS.md` F-001.

E5. Source: prompt hint. Quote: "It works under the assumption that `time` is
the only required column." Obligation: the spec must not assume a single
required column. Status: encoded by I5.

E6. Source: prompt hint proposal. Quote: "required ['time', 'flux'] as the
first columns but found ['time']". Obligation: multi-required-column failures
should display list-shaped required/found prefixes. Status: encoded by I5.

E7. Source: code comment in `core.py`. Quote: "specific methods indicated by
the `_required_columns` attribute." Obligation: `_required_columns` is the source
of the required methods/columns contract. Status: encoded by I3.

E8. Source: code comment in `core.py`. Quote: "we don't require the columns to
be present but we do require them to be the correct ones IF present." Obligation:
relaxed mode checks only the present required prefix. Status: encoded by I3.

E9. Source: built-in subclasses. `TimeSeries._required_columns == ['time']` and
`BinnedTimeSeries._required_columns == ['time_bin_start', 'time_bin_size']`.
Obligation: both single-column and multi-column built-in cases are in scope.
Status: encoded by I5 and I6.

E10. Source: public in-repository tests. Exact assertions expect single-column
messages such as "expected 'time' as the first column but found 'a'". Obligation:
single-column message text is a compatibility frame condition unless it
conflicts with E1-E6. Status: encoded by I6.

## Formal Model

The proof abstracts the table object to these fields:

- `enabled`: Boolean value of `_required_columns_enabled`.
- `req`: either `None` or an ordered list of strings.
- `relax`: Boolean value of `_required_columns_relax`.
- `cols`: ordered list of current column names.
- `class_name`: `self.__class__.__name__`.

Definitions:

- `active_req(req, relax, cols) = req[:len(cols)]` if `relax` is true.
- `active_req(req, relax, cols) = req` otherwise.
- `found(cols, active) = cols[:len(active)]`.
- `prefix_ok(cols, active) = found(cols, active) == active`.

Observable result:

- `ok(relax')`: no exception, with final relaxed-state flag `relax'`.
- `error(message)`: a `ValueError` carrying `message`.

The model intentionally treats the actual table data and column values as frame
state: the issue is only about required column names and the exception string.

## K-Style Claim Sketch

These are the reachability claims used by `PROOF.md`. The standalone supporting
K-style files are `fvk/mini-required-columns.k` and
`fvk/required-columns-spec.k`. The task forbids running K tooling, so they are
constructed only.

```k
// CLAIM RC-DISABLED
// SPEC-PROVENANCE: I1
claim <k> check(C, false, REQOPT, RELAX, COLS) => ok(RELAX) </k>
  [all-path]

// CLAIM RC-NONE
// SPEC-PROVENANCE: I2
claim <k> check(C, true, none, RELAX, COLS) => ok(RELAX) </k>
  [all-path]

// CLAIM RC-NONRELAX-EMPTY-SINGLE
// SPEC-PROVENANCE: I4, I6, E10
claim <k> check(C, true, some(REQ), false, .Cols)
       => error(singleNoColumns(C, head(REQ))) </k>
  requires size(REQ) ==Int 1
  [all-path]

// CLAIM RC-NONRELAX-EMPTY-MULTI
// SPEC-PROVENANCE: I4, I5, E3, E6
claim <k> check(C, true, some(REQ), false, .Cols)
       => error(multiNoColumns(C, REQ)) </k>
  requires size(REQ) >Int 1
  [all-path]

// CLAIM RC-MISMATCH-SINGLE
// SPEC-PROVENANCE: I4, I6, E10
claim <k> check(C, true, some(REQ), RELAX, COLS)
       => error(singleFound(C, head(ACTIVE), head(COLS))) </k>
  requires ACTIVE ==K activeReq(REQ, RELAX, COLS)
       andBool size(ACTIVE) ==Int 1
       andBool take(COLS, size(ACTIVE)) =/=K ACTIVE
  [all-path]

// CLAIM RC-MISMATCH-MULTI
// SPEC-PROVENANCE: I4, I5, E1-E6
claim <k> check(C, true, some(REQ), RELAX, COLS)
       => error(multiFound(C, ACTIVE, take(COLS, size(ACTIVE)))) </k>
  requires ACTIVE ==K activeReq(REQ, RELAX, COLS)
       andBool size(ACTIVE) >Int 1
       andBool take(COLS, size(ACTIVE)) =/=K ACTIVE
  [all-path]

// CLAIM RC-VALID
// SPEC-PROVENANCE: I3, I7
claim <k> check(C, true, some(REQ), RELAX, COLS)
       => ok(RELAX andBool notBool (REQ ==K take(COLS, size(REQ)))) </k>
  requires ACTIVE ==K activeReq(REQ, RELAX, COLS)
       andBool take(COLS, size(ACTIVE)) ==K ACTIVE
       andBool notBool (notBool RELAX andBool size(COLS) ==Int 0)
  [all-path]
```

The claim names are referenced by `fvk/PROOF_OBLIGATIONS.md` and
`fvk/PROOF.md`.

## Adequacy Audit

A1. The formal model includes the property that distinguishes pass from fail:
the ordered required prefix and the ordered found prefix. It does not collapse
the issue into a boolean invalid state.

A2. The multi-column message form in RC-MISMATCH-MULTI is directly entailed by
E1-E6. It is not derived from V1 implementation behavior.

A3. The single-column message form in RC-MISMATCH-SINGLE is supported by E10 and
does not conflict with the issue because the issue is specifically about
additional required columns.

A4. Public compatibility: V1 changes no public function signature, method name,
decorator coverage, or mutation behavior. It changes only `ValueError` message
content for multi-column required-prefix failures, which is the intended public
observable.
