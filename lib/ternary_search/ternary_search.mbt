// ============================================================================
// TERNARY SEARCH - Unimodal Function Optimization
// ============================================================================
//
// Ternary search finds the maximum or minimum of a unimodal function in O(log n).
// A unimodal function has a single peak (for max) or valley (for min).
//
// KEY INSIGHT: Compare two points m1 and m2 in the middle third.
// If f(m1) < f(m2), the maximum is not in [left, m1].
// If f(m1) > f(m2), the maximum is not in [m2, right].
//
// UNIMODAL PROPERTY:
// For maximum: f strictly increases, then strictly decreases
// For minimum: f strictly decreases, then strictly increases
//
// INVARIANTS:
// 1. The optimal point is always within [left, right]
// 2. Interval size reduces by factor of 2/3 each iteration
// 3. After k iterations: interval ≤ (2/3)^k * initial_size
//
// TIME COMPLEXITY: O(log n) for discrete, O(log(1/ε)) for continuous
// SPACE COMPLEXITY: O(1)

///|
const TS_EPS : Double = 0.0000000001

///|
/// Find x that maximizes f(x) in range [left, right] (continuous)
fn ternary_search_max(
  f : (Double) -> Double,
  left : Double,
  right : Double
) -> Double {
  let mut l = left
  let mut r = right

  // Continue until interval is small enough
  for iter = 0; iter < 200 && r - l > TS_EPS; iter = iter + 1 {
    let m1 = l + (r - l) / 3.0
    let m2 = r - (r - l) / 3.0

    if f(m1) < f(m2) {
      l = m1
    } else {
      r = m2
    }
  }

  (l + r) / 2.0
}

///|
/// Find x that minimizes f(x) in range [left, right] (continuous)
fn ternary_search_min(
  f : (Double) -> Double,
  left : Double,
  right : Double
) -> Double {
  let mut l = left
  let mut r = right

  for iter = 0; iter < 200 && r - l > TS_EPS; iter = iter + 1 {
    let m1 = l + (r - l) / 3.0
    let m2 = r - (r - l) / 3.0

    if f(m1) > f(m2) {
      l = m1
    } else {
      r = m2
    }
  }

  (l + r) / 2.0
}

///|
/// Find index that maximizes f(i) in range [left, right] (discrete)
fn ternary_search_max_discrete(
  f : (Int) -> Int64,
  left : Int,
  right : Int
) -> Int {
  let mut l = left
  let mut r = right

  while r - l > 2 {
    let m1 = l + (r - l) / 3
    let m2 = r - (r - l) / 3

    if f(m1) < f(m2) {
      l = m1
    } else {
      r = m2
    }
  }

  // Linear search in small remaining range
  let mut best = l
  let mut best_val = f(l)
  for i = l + 1; i <= r; i = i + 1 {
    let val = f(i)
    if val > best_val {
      best_val = val
      best = i
    }
  }

  best
}

///|
/// Find index that minimizes f(i) in range [left, right] (discrete)
fn ternary_search_min_discrete(
  f : (Int) -> Int64,
  left : Int,
  right : Int
) -> Int {
  let mut l = left
  let mut r = right

  while r - l > 2 {
    let m1 = l + (r - l) / 3
    let m2 = r - (r - l) / 3

    if f(m1) > f(m2) {
      l = m1
    } else {
      r = m2
    }
  }

  let mut best = l
  let mut best_val = f(l)
  for i = l + 1; i <= r; i = i + 1 {
    let val = f(i)
    if val < best_val {
      best_val = val
      best = i
    }
  }

  best
}

// ============================================================================
// GOLDEN SECTION SEARCH - More efficient variant
// ============================================================================

///|
const GOLDEN_RATIO : Double = 1.618033988749895

///|
const INV_GOLDEN : Double = 0.618033988749895

///|
/// Golden section search for minimum
fn golden_section_min(
  f : (Double) -> Double,
  left : Double,
  right : Double
) -> Double {
  let mut a = left
  let mut b = right

  let mut c = b - (b - a) * INV_GOLDEN
  let mut d = a + (b - a) * INV_GOLDEN

  let mut fc = f(c)
  let mut fd = f(d)

  for iter = 0; iter < 200 && b - a > TS_EPS; iter = iter + 1 {
    if fc < fd {
      b = d
      d = c
      fd = fc
      c = b - (b - a) * INV_GOLDEN
      fc = f(c)
    } else {
      a = c
      c = d
      fc = fd
      d = a + (b - a) * INV_GOLDEN
      fd = f(d)
    }
  }

  (a + b) / 2.0
}

///|
/// Golden section search for maximum
fn golden_section_max(
  f : (Double) -> Double,
  left : Double,
  right : Double
) -> Double {
  // Minimize negative of function
  fn neg_f(x : Double) -> Double {
    let ff = f
    -ff(x)
  }
  golden_section_min(neg_f, left, right)
}

// ============================================================================
// BITONIC ARRAY SEARCH
// ============================================================================

///|
/// Find maximum in bitonic array (increases then decreases)
fn find_bitonic_max(arr : Array[Int64]) -> Int {
  let n = arr.length()
  if n == 0 {
    return -1
  }
  if n == 1 {
    return 0
  }

  let mut l = 0
  let mut r = n - 1

  while l < r {
    let mid = (l + r) / 2
    if arr[mid] < arr[mid + 1] {
      l = mid + 1
    } else {
      r = mid
    }
  }

  l
}

///|
/// Search for target in bitonic array
fn bitonic_search(arr : Array[Int64], target : Int64) -> Int {
  let peak = find_bitonic_max(arr)
  if peak < 0 {
    return -1
  }

  // Binary search in increasing part [0, peak]
  let mut l = 0
  let mut r = peak

  while l <= r {
    let mid = (l + r) / 2
    if arr[mid] == target {
      return mid
    } else if arr[mid] < target {
      l = mid + 1
    } else {
      r = mid - 1
    }
  }

  // Binary search in decreasing part [peak, n-1]
  l = peak
  r = arr.length() - 1

  while l <= r {
    let mid = (l + r) / 2
    if arr[mid] == target {
      return mid
    } else if arr[mid] > target {
      l = mid + 1
    } else {
      r = mid - 1
    }
  }

  -1
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "ternary_search_max quadratic" {
  // f(x) = -(x-5)² + 25, maximum at x=5
  fn f(x : Double) -> Double {
    -(x - 5.0) * (x - 5.0) + 25.0
  }

  let result = ternary_search_max(f, 0.0, 10.0)
  inspect(result > 4.99 && result < 5.01, content="true")
}

///|
test "ternary_search_min quadratic" {
  // f(x) = (x-3)², minimum at x=3
  fn f(x : Double) -> Double {
    (x - 3.0) * (x - 3.0)
  }

  let result = ternary_search_min(f, 0.0, 10.0)
  inspect(result > 2.99 && result < 3.01, content="true")
}

///|
test "ternary_search_max_discrete" {
  // Array with peak at index 5
  fn f(i : Int) -> Int64 {
    let x = i - 5
    (-(x * x) + 100).to_int64()
  }

  let result = ternary_search_max_discrete(f, 0, 10)
  inspect(result, content="5")
}

///|
test "ternary_search_min_discrete" {
  // Array with minimum at index 3
  fn f(i : Int) -> Int64 {
    let x = i - 3
    (x * x).to_int64()
  }

  let result = ternary_search_min_discrete(f, 0, 10)
  inspect(result, content="3")
}

///|
test "golden_section_min" {
  fn f(x : Double) -> Double {
    (x - 2.0) * (x - 2.0)
  }

  let result = golden_section_min(f, 0.0, 5.0)
  inspect(result > 1.99 && result < 2.01, content="true")
}

///|
test "golden_section_max" {
  fn f(x : Double) -> Double {
    -(x - 4.0) * (x - 4.0) + 16.0
  }

  let result = golden_section_max(f, 0.0, 8.0)
  inspect(result > 3.99 && result < 4.01, content="true")
}

///|
test "find_bitonic_max" {
  let arr : Array[Int64] = [1L, 3L, 5L, 7L, 6L, 4L, 2L]
  inspect(find_bitonic_max(arr), content="3") // Peak at index 3 (value 7)
}

///|
test "find_bitonic_max edges" {
  // Peak at start
  let arr1 : Array[Int64] = [10L, 8L, 6L, 4L, 2L]
  inspect(find_bitonic_max(arr1), content="0")

  // Peak at end
  let arr2 : Array[Int64] = [1L, 2L, 3L, 4L, 5L]
  inspect(find_bitonic_max(arr2), content="4")
}

///|
test "bitonic_search" {
  let arr : Array[Int64] = [1L, 3L, 5L, 7L, 6L, 4L, 2L]

  inspect(bitonic_search(arr, 7L), content="3")
  inspect(bitonic_search(arr, 3L), content="1")
  inspect(bitonic_search(arr, 4L), content="5")
  inspect(bitonic_search(arr, 10L), content="-1")
}

///|
test "ternary_search single point" {
  fn f(_x : Double) -> Double {
    5.0
  }

  let result = ternary_search_max(f, 0.0, 10.0)
  inspect(result >= 0.0 && result <= 10.0, content="true")
}

///|
test "find_bitonic_max single" {
  let arr : Array[Int64] = [5L]
  inspect(find_bitonic_max(arr), content="0")
}

///|
test "find_bitonic_max empty" {
  let arr : Array[Int64] = []
  inspect(find_bitonic_max(arr), content="-1")
}
