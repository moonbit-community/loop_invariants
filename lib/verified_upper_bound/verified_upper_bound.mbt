///|
/// Return the first index whose value is strictly greater than `key`.
pub fn upper_bound(
  xs : FixedArray[Int],
  key : Int,
) -> Int where {
  proof_require: sorted(xs),
  proof_ensure: result => upper_bound_ok(xs, key, result),
} {
  for lo = 0, hi = xs.length(); lo < hi; {
    let mid = lo + (hi - lo) / 2
    if xs[mid] <= key {
      continue mid + 1, hi
    } else {
      continue lo, mid
    }
  } nobreak {
    lo
  } where {
    proof_invariant: 0 <= lo,
    proof_invariant: lo <= hi,
    proof_invariant: hi <= xs.length(),
    proof_invariant: all_leq_before(xs, key, lo),
    proof_invariant: all_gt_from(xs, key, hi),
    proof_reasoning: (
      #| `lo` is always a safe lower boundary: everything before it has already
      #| been proved `<= key`.
      #|
      #| `hi` is always a safe upper boundary: everything from it onward has
      #| already been proved `> key`.
      #|
      #| When `xs[mid] <= key`, sortedness lets us extend the left boundary to
      #| `mid + 1` because every index up to `mid` is also `<= key`.
      #|
      #| Otherwise `xs[mid] > key`, and sortedness lets us shrink the right
      #| boundary to `mid` because every later element is at least `xs[mid]`,
      #| hence still `> key`.
      #|
      #| The distance `hi - lo` strictly decreases at each step, so the loop
      #| terminates when the interval becomes empty. At that point `lo == hi`,
      #| and the two boundary facts exactly describe the upper bound.
    ),
  }
}
