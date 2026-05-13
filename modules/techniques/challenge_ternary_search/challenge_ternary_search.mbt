// ============================================================================
// Challenge: Ternary Search on Unimodal Array
// ============================================================================

///|
fn scan_min_index(
  arr : FixedArray[Int],
) -> Int where {
  proof_require: nonempty(arr),
  proof_ensure: result => is_min_index(arr, result),
} {
  for i in 1..<arr.length(); best = 0 {
    let new_best = if arr[i] < arr[best] { i } else { best }
    continue new_best
  } nobreak {
    best
  } where {
    proof_invariant: 1 <= i,
    proof_invariant: i <= arr.length(),
    proof_invariant: 0 <= best,
    proof_invariant: best < i,
    proof_invariant: min_in_prefix(arr, best, i),
    proof_reasoning: (
      #|This helper proves the final linear scan over the narrowed ternary
      #|search window.
      #|
      #|`best` is always an index of a minimum element inside the processed
      #|prefix `arr[0 .. i)`. Each step compares the next candidate against the
      #|current witness and keeps the better one.
    ),
  }
}

///|
/// Find index of minimum value in a unimodal array (decreasing then increasing).
pub fn find_min_unimodal(arr : ArrayView[Int]) -> Int {
  let n = arr.length()
  guard n > 0 else { return -1 }
  let (lo, hi) = for _ in 0..<n; lo = 0, hi = n - 1 {
    if hi - lo <= 3 {
      break (lo, hi)
    }
    let m1 = lo + (hi - lo) / 3
    let m2 = hi - (hi - lo) / 3
    if arr[m1] <= arr[m2] {
      continue lo, m2 - 1
    } else {
      continue m1 + 1, hi
    }
  } nobreak {
    (lo, hi)
  }
  // Linear scan for minimum in the small window
  let window_len = hi - lo + 1
  let window = FixedArray::make(window_len, 0)
  for offset in 0..<window_len {
    window[offset] = arr[lo + offset]
  }
  lo + scan_min_index(window)
}

///|
test "find_min_unimodal" {
  let arr : Array[Int] = [9, 7, 5, 3, 4, 6, 8]
  @debug.assert_eq(find_min_unimodal(arr), 3)
  let arr2 : Array[Int] = [5, 4, 3, 2, 1]
  @debug.assert_eq(find_min_unimodal(arr2), 4)
}
