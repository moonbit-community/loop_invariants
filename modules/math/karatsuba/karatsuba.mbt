// ============================================================================
// KARATSUBA MULTIPLICATION  -  Karatsuba 1962
// ============================================================================
//
// PROBLEM
//
// Multiply two non-negative big integers represented in base
// `B = 10^9` (a "limb", little-endian: `x[0]` is the least-significant
// limb). The schoolbook algorithm is `O(n^2)`; Karatsuba reduces it
// to `O(n^{log_2 3}) ≈ O(n^{1.585})` via
//
//   x = a * B^k + b,    y = c * B^k + d
//   x*y = a*c * B^{2k} + ((a+b)(c+d) - a*c - b*d) * B^k + b*d
//
// using **three** multiplications of half-size pieces instead of four.
//
// COMPLEXITY
//
//   Time : T(n) = 3 * T(n/2) + O(n)  =  O(n^{log_2 3})
//   Space: O(n) per level.
//
// THE INVARIANT
//
//   "For two big-integer arrays `a, b`, the result returned by `mul`
//    is a big-integer representation of a * b in canonical form
//    (no leading-zero limbs except for the explicit value 0)."

///|
const BASE : Int64 = 1000000000L

///|
const CUTOFF : Int = 32

///|
/// Strip trailing zero limbs (most-significant), keeping at least one
/// limb so the canonical representation of 0 is `[0]`.
fn strip_leading_zeros(limbs : Array[Int64]) -> Array[Int64] {
  let mut i = limbs.length() - 1
  while i > 0 && limbs[i] == 0L {
    i = i - 1
  }
  if i + 1 == limbs.length() {
    limbs
  } else {
    let res = Array::make(i + 1, 0L)
    for k in 0..<=i {
      res[k] = limbs[k]
    }
    res
  }
}

///|
/// Add two big integers `a + b`. Result is canonical (no leading zeros).
pub fn add(a : Array[Int64], b : Array[Int64]) -> Array[Int64] {
  let n = a.length()
  let m = b.length()
  let len = if n > m { n } else { m }
  let res = Array::make(len + 1, 0L)
  let mut carry = 0L
  for i in 0..<len {
    let ai = if i < n { a[i] } else { 0L }
    let bi = if i < m { b[i] } else { 0L }
    let s = ai + bi + carry
    res[i] = s % BASE
    carry = s / BASE
  }
  res[len] = carry
  strip_leading_zeros(res)
}

///|
/// Subtract `a - b` with `a >= b`. Result is canonical.
pub fn sub(a : Array[Int64], b : Array[Int64]) -> Array[Int64] {
  let n = a.length()
  let m = b.length()
  let res = Array::make(n, 0L)
  let mut borrow = 0L
  for i in 0..<n {
    let ai = a[i]
    let bi = if i < m { b[i] } else { 0L }
    let mut d = ai - bi - borrow
    if d < 0L {
      d = d + BASE
      borrow = 1L
    } else {
      borrow = 0L
    }
    res[i] = d
  }
  strip_leading_zeros(res)
}

///|
/// Shift `x` left by `k` limbs: returns `x * BASE^k`.
fn shift_left(x : Array[Int64], k : Int) -> Array[Int64] {
  if x.length() == 1 && x[0] == 0L {
    return [0L]
  }
  let res = Array::make(x.length() + k, 0L)
  for i in 0..<x.length() {
    res[i + k] = x[i]
  }
  res
}

///|
/// Naive schoolbook multiplication; used at the recursion base.
pub fn mul_naive(a : Array[Int64], b : Array[Int64]) -> Array[Int64] {
  let n = a.length()
  let m = b.length()
  let res = Array::make(n + m, 0L)
  for i in 0..<n {
    let mut carry = 0L
    for j in 0..<m {
      let s = res[i + j] + a[i] * b[j] + carry
      res[i + j] = s % BASE
      carry = s / BASE
    }
    res[i + m] = res[i + m] + carry
  }
  strip_leading_zeros(res)
}

///|
fn take_slice(arr : Array[Int64], lo : Int, hi : Int) -> Array[Int64] {
  if lo >= hi {
    return [0L]
  }
  let res = Array::make(hi - lo, 0L)
  for i in 0..<(hi - lo) {
    res[i] = arr[lo + i]
  }
  strip_leading_zeros(res)
}

///|
/// Karatsuba multiplication. Inputs are canonical little-endian
/// big-integer arrays. The result is canonical.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   // 123456789 * 987654321 = 121932631112635269
///   @debug.assert_eq(@karatsuba.mul([123456789L], [987654321L]), [
///     112635269L, 121932631L,
///   ])
/// }
/// ```
pub fn mul(a : Array[Int64], b : Array[Int64]) -> Array[Int64] {
  let n = a.length()
  let m = b.length()
  if (n == 1 && a[0] == 0L) || (m == 1 && b[0] == 0L) {
    return [0L]
  }
  if n < CUTOFF || m < CUTOFF {
    return mul_naive(a, b)
  }
  // Split at the midpoint of the longer.
  let max_len = if n > m { n } else { m }
  let k = (max_len + 1) / 2
  let a_lo = take_slice(a, 0, if k < n { k } else { n })
  let a_hi = take_slice(a, k, n)
  let b_lo = take_slice(b, 0, if k < m { k } else { m })
  let b_hi = take_slice(b, k, m)
  let p1 = mul(a_hi, b_hi) // a_hi * b_hi
  let p2 = mul(a_lo, b_lo) // a_lo * b_lo
  let sum_a = add(a_hi, a_lo)
  let sum_b = add(b_hi, b_lo)
  let p3 = mul(sum_a, sum_b)
  let middle = sub(sub(p3, p1), p2)
  let shifted_p1 = shift_left(p1, 2 * k)
  let shifted_middle = shift_left(middle, k)
  add(add(shifted_p1, shifted_middle), p2)
}

///|
/// Parse a decimal string into a canonical big-integer array.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let n = @karatsuba.from_string("1000000000")
///   @debug.assert_eq(n, [0L, 1L])
/// }
/// ```
pub fn from_string(s : String) -> Array[Int64] {
  if s.length() == 0 {
    return [0L]
  }
  let mut start = 0
  while start < s.length() - 1 && s[start] == '0' {
    start = start + 1
  }
  let digits = s.length() - start
  let limbs = (digits + 8) / 9
  let res = Array::make(limbs, 0L)
  let mut limb_idx = 0
  let mut end = s.length()
  while end > start {
    let lo = if end - 9 > start { end - 9 } else { start }
    let mut acc = 0L
    for i in lo..<end {
      let d = (s[i] - '0').to_int64()
      acc = acc * 10L + d
    }
    res[limb_idx] = acc
    limb_idx = limb_idx + 1
    end = lo
  }
  strip_leading_zeros(res)
}

///|
/// Render a canonical big integer back to a decimal string.
pub fn to_string(x : Array[Int64]) -> String {
  let n = x.length()
  if n == 0 || (n == 1 && x[0] == 0L) {
    return "0"
  }
  let buf = StringBuilder()
  buf.write_string(x[n - 1].to_string())
  let mut i = n - 2
  while i >= 0 {
    let s = x[i].to_string()
    let mut p = 9 - s.length()
    while p > 0 {
      buf.write_char('0')
      p = p - 1
    }
    buf.write_string(s)
    i = i - 1
  }
  buf.to_string()
}

///|
test "karatsuba single limbs" {
  // 123456789 * 987654321 = 121932631112635269.
  let c = mul([123456789L], [987654321L])
  @debug.assert_eq(c, [112635269L, 121932631L])
}

///|
test "karatsuba by string parsing" {
  let a = from_string("123456789012345678901234567890")
  let b = from_string("987654321098765432109876543210")
  let c = mul(a, b)
  @debug.assert_eq(
    to_string(c),
    "121932631137021795226185032733622923332237463801111263526900",
  )
}

///|
test "karatsuba zero" {
  let big = [12345L, 67890L, 11L]
  @debug.assert_eq(mul([0L], big), [0L])
  @debug.assert_eq(mul(big, [0L]), [0L])
}

///|
test "karatsuba large vs naive" {
  // 100-limb numbers; ensure Karatsuba matches schoolbook.
  let a = Array::makei(100, i => ((i * 7919 + 13) % 1000000000).to_int64())
  let b = Array::makei(100, i => ((i * 31337 + 7) % 1000000000).to_int64())
  @debug.assert_eq(mul(a, b), mul_naive(a, b))
}

///|
test "karatsuba round-trip via string" {
  let cases : ReadOnlyArray[String] = [
    "0",
    "1",
    "123",
    "1000000000",
    "999999999999999999",
    "12345678901234567890",
    "1" + "0".repeat(50),
  ]
  for s in cases {
    @debug.assert_eq(to_string(from_string(s)), s)
  }
}

///|
test "karatsuba identity x * 1 = x" {
  let big = from_string("314159265358979323846264338327950288419716939937510")
  @debug.assert_eq(mul(big, [1L]), big)
}

///|
test "karatsuba distributivity" {
  // (a + b) * c = a*c + b*c
  let a = from_string("100000000000000000000000")
  let b = from_string("200000000000000000000000")
  let c = from_string("3")
  let lhs = mul(add(a, b), c)
  let rhs = add(mul(a, c), mul(b, c))
  @debug.assert_eq(lhs, rhs)
}
