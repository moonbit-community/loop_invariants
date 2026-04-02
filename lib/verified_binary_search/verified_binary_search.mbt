///|
/// Proof-native version of the binary-search example from `examples.mbt`.
pub fn binary_search(
  xs : FixedArray[Int],
  key : Int,
) -> Int? where {
  proof_require: sorted(xs),
  proof_ensure: result => binary_search_ok(xs, key, result),
} {
  for lo = 0, hi = xs.length(); lo < hi; {
    let mid = lo + (hi - lo) / 2
    if xs[mid] < key {
      continue mid + 1, hi
    } else if xs[mid] > key {
      continue lo, mid
    } else {
      break Some(mid)
    }
  } nobreak {
    None
  } where {
    proof_invariant: 0 <= lo,
    proof_invariant: lo <= hi,
    proof_invariant: hi <= xs.length(),
    proof_invariant: all_less_before(xs, key, lo),
    proof_invariant: all_greater_from(xs, key, hi),
    proof_yield: res => binary_search_ok(xs, key, res),
    reasoning: (
      #| This is the formal counterpart of the repo's binary-search invariant:
      #| `[lo, hi)` is the only remaining candidate window.
      #|
      #| `all_less_before(xs, key, lo)` excludes every index before `lo`, while
      #| `all_greater_from(xs, key, hi)` excludes every index from `hi`
      #| onward. Sortedness is what lets those one-point comparisons at `mid`
      #| expand into whole excluded regions.
      #|
      #| If `xs[mid] < key`, every earlier index is also `< key`, so the search
      #| can safely continue in `[mid + 1, hi)`. If `xs[mid] > key`, every
      #| later index is also `> key`, so the search can safely continue in
      #| `[lo, mid)`. If equality holds, `mid` is an immediate witness.
      #|
      #| The window width `hi - lo` strictly decreases on every non-yielding
      #| step, so normal termination means `lo == hi`. At that point the left
      #| and right exclusion predicates meet and rule out the whole array.
    ),
  }
}

///|
test "verified_binary_search_examples" {
  let xs = FixedArray::make(7, 0)
  xs[0] = 1
  xs[1] = 3
  xs[2] = 5
  xs[3] = 7
  xs[4] = 9
  xs[5] = 11
  xs[6] = 13
  assert_eq(binary_search(xs, 7), Some(3))
  assert_eq(binary_search(xs, 1), Some(0))
  assert_eq(binary_search(xs, 13), Some(6))
  assert_eq(binary_search(xs, 6), None)
  assert_eq(binary_search(xs, 0), None)
}
