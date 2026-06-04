// ============================================================================
// DIGIT PRIMITIVES
// ============================================================================
//
// A pack of small digit-oriented number-theory primitives that show up
// constantly in competitive programming and basic library code:
//
//   - digit_sum(n, base)           sum of digits in a given base
//   - digit_count(n, base)         number of digits
//   - digital_root(n, base)        iterated digit sum (single digit)
//   - reverse_digits(n, base)      reverse the digit string
//   - is_palindrome(n, base)       symmetric digit string
//   - digit_at(n, position, base)  k-th digit from the right
//   - to_digits(n, base)           array of digits (LSB-first)
//   - from_digits(digits, base)    inverse of to_digits
//
// THE DIGITAL ROOT IDENTITY
//
//   digital_root_10(n) = 1 + ((n - 1) mod 9)   for n > 0
//
// is a famous closed form; we include both the formulaic and the
// iterative versions and check they agree.
//
// COMPLEXITY
//
//   O(log_base n) per call.
//
// THE INVARIANT
//
//   "After processing the k-th digit, the accumulator equals the sum
//    of the lowest k digits of n in the chosen base."

///|
/// Sum of the digits of `n` written in base `base`.
/// Treats `n < 0` as its absolute value; returns `0` for `base <= 1`.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   @debug.assert_eq(@digit_sum.digit_sum(12345L, 10), 15)
/// }
/// ```
pub fn digit_sum(n : Int64, base : Int) -> Int {
  if base <= 1 {
    return 0
  }
  let mut m = if n < 0L { -n } else { n }
  let b = base.to_int64()
  let mut s = 0
  while m > 0L {
    s = s + (m % b).to_int()
    m = m / b
  }
  s
}

///|
/// Number of digits in `n` written in base `base`.
/// `0` has `1` digit by convention.
pub fn digit_count(n : Int64, base : Int) -> Int {
  if base <= 1 {
    return 0
  }
  let mut m = if n < 0L { -n } else { n }
  if m == 0L {
    return 1
  }
  let b = base.to_int64()
  let mut c = 0
  while m > 0L {
    c = c + 1
    m = m / b
  }
  c
}

///|
/// Iterated digit sum until a single digit remains.
pub fn digital_root(n : Int64, base : Int) -> Int {
  let mut m = if n < 0L { -n } else { n }
  if base <= 1 {
    return 0
  }
  let b = base.to_int64()
  while m >= b {
    m = digit_sum(m, base).to_int64()
  }
  m.to_int()
}

///|
/// Reverse the digit string of `n` in base `base`.
pub fn reverse_digits(n : Int64, base : Int) -> Int64 {
  if base <= 1 {
    return 0L
  }
  let mut m = if n < 0L { -n } else { n }
  let b = base.to_int64()
  let mut r = 0L
  while m > 0L {
    r = r * b + m % b
    m = m / b
  }
  r
}

///|
/// `true` iff the digit string of `|n|` in `base` reads the same forwards
/// and backwards.
pub fn is_palindrome(n : Int64, base : Int) -> Bool {
  n == reverse_digits(n, base) || (n < 0L && -n == reverse_digits(-n, base))
}

///|
/// The `position`-th digit from the right (0-indexed). Returns `0`
/// when `position` exceeds the digit count.
pub fn digit_at(n : Int64, position : Int, base : Int) -> Int {
  if base <= 1 || position < 0 {
    return 0
  }
  let mut m = if n < 0L { -n } else { n }
  let b = base.to_int64()
  let mut p = position
  while p > 0 && m > 0L {
    m = m / b
    p = p - 1
  }
  (m % b).to_int()
}

///|
/// Lowest-significant-first digit array.
pub fn to_digits(n : Int64, base : Int) -> Array[Int] {
  if base <= 1 {
    return []
  }
  let mut m = if n < 0L { -n } else { n }
  if m == 0L {
    return [0]
  }
  let res : Array[Int] = []
  let b = base.to_int64()
  while m > 0L {
    res.push((m % b).to_int())
    m = m / b
  }
  res
}

///|
/// Inverse of `to_digits`: rebuild the integer from a lowest-first
/// digit array.
pub fn from_digits(digits : Array[Int], base : Int) -> Int64 {
  if base <= 1 {
    return 0L
  }
  let b = base.to_int64()
  let mut r = 0L
  let mut i = digits.length() - 1
  while i >= 0 {
    r = r * b + digits[i].to_int64()
    i = i - 1
  }
  r
}

///|
test "digit_sum base 10" {
  @debug.assert_eq(digit_sum(0L, 10), 0)
  @debug.assert_eq(digit_sum(7L, 10), 7)
  @debug.assert_eq(digit_sum(12345L, 10), 15)
  @debug.assert_eq(digit_sum(99999L, 10), 45)
  @debug.assert_eq(digit_sum(-321L, 10), 6)
}

///|
test "digit_sum other bases" {
  // 12345 in base 16 = 0x3039 -> 3 + 0 + 3 + 9 = 15.
  @debug.assert_eq(digit_sum(12345L, 16), 15)
  // 13 in base 2 = 1101 -> 3.
  @debug.assert_eq(digit_sum(13L, 2), 3)
  // 8 in base 8 = 10 -> 1.
  @debug.assert_eq(digit_sum(8L, 8), 1)
}

///|
test "digit_count" {
  @debug.assert_eq(digit_count(0L, 10), 1)
  @debug.assert_eq(digit_count(9L, 10), 1)
  @debug.assert_eq(digit_count(10L, 10), 2)
  @debug.assert_eq(digit_count(99L, 10), 2)
  @debug.assert_eq(digit_count(100L, 10), 3)
  @debug.assert_eq(digit_count(255L, 16), 2)
  @debug.assert_eq(digit_count(256L, 16), 3)
}

///|
test "digital_root_10 matches formula" {
  // For n > 0, digital_root_10(n) = 1 + ((n - 1) mod 9).
  for n in 1L..<200L {
    let expected = (1L + (n - 1L) % 9L).to_int()
    @debug.assert_eq(digital_root(n, 10), expected)
  }
  @debug.assert_eq(digital_root(0L, 10), 0)
}

///|
test "reverse_digits identities" {
  @debug.assert_eq(reverse_digits(12345L, 10), 54321L)
  @debug.assert_eq(reverse_digits(100L, 10), 1L) // trailing zero collapses
  // Double reverse equals original except for trailing-zero loss.
  for n in 1L..<1000L {
    let r = reverse_digits(n, 10)
    let rr = reverse_digits(r, 10)
    if n % 10L != 0L {
      @debug.assert_eq(rr, n)
    }
  }
}

///|
test "is_palindrome decimal" {
  @debug.assert_eq(is_palindrome(0L, 10), true)
  @debug.assert_eq(is_palindrome(7L, 10), true)
  @debug.assert_eq(is_palindrome(11L, 10), true)
  @debug.assert_eq(is_palindrome(12321L, 10), true)
  @debug.assert_eq(is_palindrome(12320L, 10), false)
  @debug.assert_eq(is_palindrome(123L, 10), false)
}

///|
test "is_palindrome bin and hex" {
  // 0b1001 = 9 is a binary palindrome.
  @debug.assert_eq(is_palindrome(9L, 2), true)
  // 0xABCBA = 703162.
  @debug.assert_eq(is_palindrome(703162L, 16), true)
}

///|
test "digit_at lowest first" {
  let n = 12345L
  @debug.assert_eq(digit_at(n, 0, 10), 5)
  @debug.assert_eq(digit_at(n, 1, 10), 4)
  @debug.assert_eq(digit_at(n, 4, 10), 1)
  // Past the end.
  @debug.assert_eq(digit_at(n, 5, 10), 0)
}

///|
test "to_digits / from_digits roundtrip" {
  for n in 0L..<300L {
    for b in 2..<=16 {
      let d = to_digits(n, b)
      @debug.assert_eq(from_digits(d, b), n)
    }
  }
}

///|
test "to_digits length matches digit_count" {
  for n in 0L..<200L {
    for b in 2..<=10 {
      @debug.assert_eq(to_digits(n, b).length(), digit_count(n, b))
    }
  }
}
