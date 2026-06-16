# Formal Spec In English

FS1. If `sharex(self, other)` is called and `self.xaxis` has no unit state,
then after sharing `self.xaxis` has the same converter and unit object as
`other.xaxis`.

FS2. If `sharey(self, other)` is called and `self.yaxis` has no unit state,
then after sharing `self.yaxis` has the same converter and unit object as
`other.yaxis`.

FS3. In the reported issue path, `sharex()` makes the fresh twin x-axis count
as having units before `ax2.plot()` sees categorical x data.

FS4. Because the twin x-axis already has units, `ax2.plot()` does not perform a
new shared x-axis unit update and does not fire the original axes' unit-change
callback.

FS5. Because the original axes' unit-change callback is not fired, the original
axes' `relim()` is not called by this path, and its existing stackplot
`dataLim` remains valid.

FS6. If the receiving axis already has units, V1 leaves those units unchanged.
