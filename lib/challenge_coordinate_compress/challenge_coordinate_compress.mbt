// ============================================================================
// Challenge: Coordinate Compression
// ============================================================================

///|
fn lower_bound_fixed(
  arr : FixedArray[Int],
  target : Int,
) -> Int where {
  proof_require: sorted(arr),
  proof_ensure: result => lower_bound_ok(arr, target, result),
} {
  for lo = 0, hi = arr.length(); lo < hi; {
    let mid = lo + (hi - lo) / 2
    if arr[mid] < target {
      continue mid + 1, hi
    } else {
      continue lo, mid
    }
  } nobreak {
    lo
  } where {
    proof_invariant: 0 <= lo,
    proof_invariant: lo <= hi,
    proof_invariant: hi <= arr.length(),
    proof_invariant: all_less_before(arr, target, lo),
    proof_invariant: all_geq_from(arr, target, hi),
    reasoning: (
      #|This is the package's proof-carrying lower-bound kernel.
      #|Every index before `lo` is already known to be `< target`, and every
      #|index from `hi` onward is already known to be `>= target`.
      #|Sortedness lets the midpoint comparison extend one of those proven
      #|regions while shrinking the search window.
    ),
  }
}

///|
/// Compress values to 0..(unique-1) preserving order.
pub fn coordinate_compress(values : ArrayView[Int]) -> (Array[Int], Array[Int]) {
  let n = values.length()
  let sorted : Array[Int] = []
  for val in values {
    sorted.push(val)
  }
  sorted.sort_by_key(x => x)
  let unique : Array[Int] = []
  for i, val in sorted {
    if i == 0 || val != sorted[i - 1] {
      unique.push(val)
    }
  }
  let unique_fixed = FixedArray::make(unique.length(), 0)
  for i, val in unique {
    unique_fixed[i] = val
  }
  let compressed : Array[Int] = Array::make(n, 0)
  for i, val in values {
    compressed[i] = lower_bound_fixed(unique_fixed, val)
  }
  (compressed, unique)
}

///|
test "coordinate_compress" {
  let values : Array[Int] = [100, 50, 100, -10]
  let (comp, uniq) = coordinate_compress(values[:])
  assert_eq(uniq, [-10, 50, 100])
  assert_eq(comp, [2, 1, 2, 0])
}
