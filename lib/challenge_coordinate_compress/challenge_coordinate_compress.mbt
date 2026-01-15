// ============================================================================
// Challenge: Coordinate Compression
// ============================================================================

///|
fn lower_bound(arr : ArrayView[Int], target : Int) -> Int {
  for lo = 0, hi = arr.length() {
    if lo >= hi {
      break lo
    } else {
      let mid = lo + (hi - lo) / 2
      if arr[mid] < target {
        continue mid + 1, hi
      } else {
        continue lo, mid
      }
    }
  } where {
    invariant: lo >= 0 && lo <= hi && hi <= arr.length(),
    reasoning: (
      #|INVARIANT (Lower bound):
      #|All indices < lo are < target, all indices >= hi are >= target.
      #|MAINTENANCE:
      #|Shrink [lo, hi) based on mid comparison.
      #|TERMINATION:
      #|At lo = hi, lo is the first index with arr[lo] >= target.
    ),
  }
}

///|
/// Compress values to 0..(unique-1) preserving order.
#warnings("+missing_invariant+missing_reasoning")
pub fn coordinate_compress(values : ArrayView[Int]) -> (Array[Int], Array[Int]) {
  let n = values.length()
  let sorted : Array[Int] = []
  for i = 0; i < n; i = i + 1 {
    sorted.push(values[i])
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (Copy):
      #|sorted contains values[0..i).
      #|MAINTENANCE:
      #|Push values[i] into sorted and advance i.
      #|TERMINATION:
      #|At i = n, sorted is a full copy.
    ),
  }
  sorted.sort_by_key(fn(x) { x })
  let unique : Array[Int] = []
  for i = 0; i < sorted.length(); i = i + 1 {
    if i == 0 || sorted[i] != sorted[i - 1] {
      unique.push(sorted[i])
    }
  } where {
    invariant: i >= 0 && i <= sorted.length(),
    reasoning: (
      #|INVARIANT (Unique scan):
      #|unique holds the distinct sorted values from sorted[0..i).
      #|MAINTENANCE:
      #|Add sorted[i] only when it differs from the previous value.
      #|TERMINATION:
      #|At i = sorted.length(), unique contains all distinct values.
    ),
  }
  let compressed : Array[Int] = Array::make(n, 0)
  for i, val in values {
    compressed[i] = lower_bound(unique[:], val)
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
