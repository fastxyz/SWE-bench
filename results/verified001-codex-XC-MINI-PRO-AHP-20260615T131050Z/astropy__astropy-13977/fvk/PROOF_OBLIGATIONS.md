# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO1 - Guard domain covers inputs and outputs

Statement: The dispatch gate scans every object in `inputs + outputs`, where
`outputs` is normalized from `kwargs.get("out", ())` to a tuple-like sequence
for the scan.

Source: public hint E5 and code lines 639-649.

Discharge: V1 constructs `outputs`, then iterates over `inputs + outputs`.

## PO2 - Unknown unit-bearing objects return NotImplemented

Statement: For any scanned object `io`, if `io` is not `None`, not a `Quantity`,
not a `numpy.ndarray`, and has a `unit` attribute, the method returns
`NotImplemented`.

Source: public issue E1-E3 and code lines 649-653.

Discharge: The K claim `PO-UNSUPPORTED-UNIT` models any `OTHER_UNIT` element as
reaching `NOT_IMPLEMENTED`.

## PO3 - Non-unit unknown objects and plain scalars preserve the old path

Statement: If a scanned object is not recognized but also does not expose
`unit`, the new guard does not return early.

Source: issue scope and existing Quantity behavior.

Discharge: `OTHER_PLAIN` reduces through `guard` to the tail; lists with no
`OTHER_UNIT` reach `PROCEED`.

## PO4 - Quantity and ndarray subclasses preserve the old path

Statement: `Quantity` instances and `numpy.ndarray` instances or subclasses,
including Astropy table Columns, are accepted by the guard and proceed to the
existing converter/output logic.

Source: public hint E4-E5 and implementation evidence E7.

Discharge: `Q` and `ND` reduce through `guard` to the tail; lists with no
`OTHER_UNIT` reach `PROCEED`.

## PO5 - Converter application is unreachable on delegated duck-array paths

Statement: On paths with an unknown unit-bearing object, `converters_and_unit()`,
`check_output()`, and converter application are not reached from
`Quantity.__array_ufunc__`.

Source: public traceback E2.

Discharge: Code order places the guard before `converters_and_unit()` at line
659. The formal model returns `NOT_IMPLEMENTED` before `PROCEED`.

## PO6 - Adequacy: the abstraction distinguishes pass from fail

Statement: The model must distinguish `OTHER_UNIT` from `Q`, `ND`, `NONE`, and
`OTHER_PLAIN`; otherwise the proof would be vacuous.

Source: FVK adequacy rule and public intent E3-E6.

Discharge: `OTHER_UNIT` is the only abstract object class that reaches
`NOT_IMPLEMENTED`; every other class reaches `PROCEED`.

## PO7 - Honesty gate

Statement: Because no execution environment exists and K tooling was not run,
all proof results are constructed, not machine-checked. Test deletion is not
recommended.

Source: user no-exec instruction and FVK `/verify` honesty gate.

Discharge: `PROOF.md` records exact commands but marks them unexecuted.

