# Formal Spec in English

Status: constructed, not machine-checked.

`VALUES-MARKS`: For any field set `F`, constructing a `values()` query produces a selected query marked with `ValuesIterable` and fields `F`.

`VALUES-LIST-TUPLE-MARKS`: For any field set `F`, constructing a tuple-mode `values_list()` query produces a selected query marked with `ValuesListIterable` and fields `F`.

`VALUES-LIST-FLAT-MARKS`: For any field set `F`, constructing a flat-mode `values_list()` query produces a selected query marked with `FlatValuesListIterable` and fields `F`.

`VALUES-LIST-NAMED-MARKS`: For any field set `F`, constructing a named-mode `values_list()` query produces a selected query marked with `NamedValuesListIterable` and fields `F`.

`ASSIGN-MARKED-SELECT`: Assigning a selected query carrying iterable marker `I` and fields `F` to any queryset produces a queryset with iterable `I`, fields `F`, and the assigned query.

`ASSIGN-UNMARKED-SELECT`: Assigning a selected query without marker metadata to any queryset produces a queryset with `ValuesIterable`, selected-name fields, and the assigned query.

`ASSIGN-NONSELECT-FRAME`: Assigning a non-selected query to any queryset replaces the query but preserves the queryset's prior iterable and fields.

