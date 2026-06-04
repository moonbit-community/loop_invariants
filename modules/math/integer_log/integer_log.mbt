// ============================================================================
// INTEGER LOG  -  floor / ceil log_b(x) and the "is power of b" test
// ============================================================================
//
// PROBLEM
//
// Pure-integer primitives for working with magnitudes in different bases:
//
//   - floor_log(x, b)         largest k with b^k <= x        (for x >= 1, b >= 2)
//   - ceil_log(x, b)          smallest k with b^k >= x       (for x >= 1)
//   - is_power_of(x, b)       true iff x == b^k for some k >= 0
//   - is_perfect_power(x)     true iff x == m^k for some m >= 2, k >= 2
//   - log2_floor(x)           specialisation of floor_log with b = 2; bit-twiddling
//   - log2_ceil(x)
//
// EDGE CASES
//
//   - `x <= 0` always returns `-1` (no defined log).
//   - `b <= 1` always returns `-1` (no defined log in those bases).
//   - log_b(1) = 0 by convention.
//
// COMPLEXITY
//
//   O(log_b(x)) per call (a small constant; both log2 variants run in
//   O(1) once `bit_length` is implemented).
//
// THE INVARIANT
//
//   "After computing floor_log(x, b), the invariant
//    b^result <= x < b^(result + 1)
//    holds (subject to overflow saturation)."

///|
const MAX : Int64 = 9223372036854775807L

///|
fn ipow_safe(b : Int64, e : Int) -> Int64 {
  if b == 0L {
    return if e == 0 { 1L } else { 0L }
  }
  if b == 1L {
    return 1L
  }
  let mut r = 1L
  let mut bb = b
  let mut ee = e
  while ee > 0 {
    if (ee & 1) == 1 {
      if r > MAX / bb {
        return MAX
      }
      r = r * bb
    }
    ee = ee >> 1
    if ee > 0 {
      if bb > MAX / bb {
        bb = MAX
      } else {
        bb = bb * bb
      }
    }
  }
  r
}

///|
/// floor(log_b(x)). Returns `-1` for `x <= 0` or `b <= 1`.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   @debug.assert_eq(@integer_log.floor_log(1000L, 10), 3)
/// }
/// ```
pub fn floor_log(x : Int64, b : Int) -> Int {
  if x <= 0L || b <= 1 {
    return -1
  }
  let bb = b.to_int64()
  let mut k = 0
  let mut cur = 1L
  while cur <= x / bb || cur * bb <= x {
    // Two-armed condition handles overflow at the top: if cur*bb would
    // overflow, the first arm is false but we may still want to advance.
    if cur > MAX / bb {
      break
    }
    cur = cur * bb
    k = k + 1
  }
  k
}

///|
/// ceil(log_b(x)). Returns `-1` for `x <= 0` or `b <= 1`.
pub fn ceil_log(x : Int64, b : Int) -> Int {
  if x <= 0L || b <= 1 {
    return -1
  }
  if x == 1L {
    return 0
  }
  let f = floor_log(x, b)
  if ipow_safe(b.to_int64(), f) == x {
    f
  } else {
    f + 1
  }
}

///|
/// `true` iff `x = b^k` for some `k >= 0`. Returns `false` for `x <= 0`,
/// `b <= 1`, or non-power x.
pub fn is_power_of(x : Int64, b : Int) -> Bool {
  if x <= 0L || b <= 1 {
    return false
  }
  if x == 1L {
    return true
  }
  let bb = b.to_int64()
  let mut cur = 1L
  while cur < x {
    if cur > MAX / bb {
      return false
    }
    cur = cur * bb
  }
  cur == x
}

///|
/// floor(log_2(x)).
pub fn log2_floor(x : Int64) -> Int {
  if x <= 0L {
    return -1
  }
  let mut k = 0
  let mut y = x
  while y >= 2L {
    y = y >> 1
    k = k + 1
  }
  k
}

///|
/// ceil(log_2(x)).
pub fn log2_ceil(x : Int64) -> Int {
  if x <= 0L {
    return -1
  }
  if x == 1L {
    return 0
  }
  let f = log2_floor(x)
  if 1L << f == x {
    f
  } else {
    f + 1
  }
}

///|
/// `true` iff `x = m^k` for some integer `m >= 2`, `k >= 2`. Tests
/// k from 2 up to `log2(x)`, looking for an integer m-th root that
/// raises to exactly x.
pub fn is_perfect_power(x : Int64) -> Bool {
  if x < 4L {
    return false
  }
  let max_k = log2_floor(x)
  for k in 2..<=max_k {
    let m = nth_root_floor(x, k)
    if m >= 2L && ipow_safe(m, k) == x {
      return true
    }
  }
  false
}

///|
fn nth_root_floor(x : Int64, n : Int) -> Int64 {
  if x <= 0L || n < 1 {
    return 0L
  }
  if n == 1 || x == 1L {
    return x
  }
  let mut r = 1L
  while ipow_safe(r, n) < x && r <= 1073741824L {
    r = r * 2L
  }
  // Newton.
  let mut prev = r
  let mut iter = 0
  while iter < 100 {
    let nm1 = (n - 1).to_int64()
    let pn1 = ipow_safe(r, n - 1)
    if pn1 == 0L {
      break
    }
    let next = (nm1 * r + x / pn1) / n.to_int64()
    if next >= r {
      break
    }
    prev = r
    r = next
    iter = iter + 1
  }
  let _ = prev
  while r > 0L && ipow_safe(r, n) > x {
    r = r - 1L
  }
  while ipow_safe(r + 1L, n) <= x {
    r = r + 1L
  }
  r
}

///|
test "floor_log basic" {
  @debug.assert_eq(floor_log(1L, 10), 0)
  @debug.assert_eq(floor_log(9L, 10), 0)
  @debug.assert_eq(floor_log(10L, 10), 1)
  @debug.assert_eq(floor_log(99L, 10), 1)
  @debug.assert_eq(floor_log(100L, 10), 2)
  @debug.assert_eq(floor_log(1000L, 10), 3)
}

///|
test "ceil_log basic" {
  @debug.assert_eq(ceil_log(1L, 10), 0)
  @debug.assert_eq(ceil_log(2L, 10), 1)
  @debug.assert_eq(ceil_log(10L, 10), 1)
  @debug.assert_eq(ceil_log(11L, 10), 2)
  @debug.assert_eq(ceil_log(100L, 10), 2)
  @debug.assert_eq(ceil_log(101L, 10), 3)
}

///|
test "log2 floor and ceil" {
  @debug.assert_eq(log2_floor(1L), 0)
  @debug.assert_eq(log2_floor(2L), 1)
  @debug.assert_eq(log2_floor(3L), 1)
  @debug.assert_eq(log2_floor(8L), 3)
  @debug.assert_eq(log2_floor(1024L), 10)
  @debug.assert_eq(log2_ceil(1L), 0)
  @debug.assert_eq(log2_ceil(3L), 2)
  @debug.assert_eq(log2_ceil(8L), 3)
  @debug.assert_eq(log2_ceil(1025L), 11)
}

///|
test "is_power_of" {
  @debug.assert_eq(is_power_of(1L, 5), true)
  @debug.assert_eq(is_power_of(25L, 5), true)
  @debug.assert_eq(is_power_of(125L, 5), true)
  @debug.assert_eq(is_power_of(126L, 5), false)
  @debug.assert_eq(is_power_of(1024L, 2), true)
  @debug.assert_eq(is_power_of(0L, 2), false)
  @debug.assert_eq(is_power_of(7L, 1), false)
}

///|
test "is_perfect_power" {
  @debug.assert_eq(is_perfect_power(4L), true) // 2^2
  @debug.assert_eq(is_perfect_power(8L), true) // 2^3
  @debug.assert_eq(is_perfect_power(9L), true) // 3^2
  @debug.assert_eq(is_perfect_power(10L), false)
  @debug.assert_eq(is_perfect_power(1024L), true) // 2^10 or 32^2
  @debug.assert_eq(is_perfect_power(1L), false) // by convention
  @debug.assert_eq(is_perfect_power(7L), false)
  @debug.assert_eq(is_perfect_power(81L), true) // 3^4 or 9^2
}

///|
test "log invariants" {
  // For x in [1, 200], b in [2, 10]:
  //   b^floor_log(x, b) <= x < b^(floor_log(x, b) + 1)
  for x in 1L..<200L {
    for b in 2..<=10 {
      let k = floor_log(x, b)
      let bb = b.to_int64()
      @debug.assert_eq(ipow_safe(bb, k) <= x, true)
      @debug.assert_eq(ipow_safe(bb, k + 1) > x, true)
    }
  }
}

///|
test "log edge cases" {
  @debug.assert_eq(floor_log(0L, 10), -1)
  @debug.assert_eq(floor_log(-1L, 10), -1)
  @debug.assert_eq(floor_log(5L, 1), -1)
  @debug.assert_eq(floor_log(5L, 0), -1)
  @debug.assert_eq(ceil_log(0L, 10), -1)
  @debug.assert_eq(log2_floor(0L), -1)
}
