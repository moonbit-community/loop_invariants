// ============================================================================
// INTEGER PARTITION FUNCTION  -  p(n) via Euler's pentagonal recurrence
// ============================================================================
//
// PROBLEM
//
// The unrestricted partition function `p(n)` counts the ways to write
// `n` as an unordered sum of positive integers.
//
//   p(0)=1, p(1)=1, p(2)=2, p(3)=3, p(4)=5, p(5)=7, ...
//
// PENTAGONAL NUMBER THEOREM (Euler 1741)
//
//   p(n) = sum_{k=1..} (-1)^{k+1} * (p(n - g_k) + p(n - g'_k))
//
// where the generalised pentagonal numbers are
//
//   g_k  = k(3k - 1) / 2,    g'_k = k(3k + 1) / 2
//
// (so 1, 2, 5, 7, 12, 15, 22, 26, ...). For each `n`, only
// `O(sqrt(n))` of these are <= `n`, giving the celebrated
//
//   T(n) = O(n * sqrt(n))
//
// recurrence.
//
// MODULAR VARIANT
//
// All operations stay non-negative if we work mod a prime `M`. Add a
// signed alternation cleanly with `(M + value) % M`.
//
// THE INVARIANT
//
//   "After computing p[k] for all k < n, the formula above using the
//    pentagonal generators yields p[n] using only previously stored
//    values."

///|
/// Compute `p(0), p(1), ..., p(n)` modulo `modulus` using Euler's
/// pentagonal recurrence. `modulus` must be positive.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let p = @integer_partition.partition_table_mod(10, 1000000007L)
///   // p(10) = 42.
///   @debug.assert_eq(p[10], 42L)
/// }
/// ```
pub fn partition_table_mod(n : Int, modulus : Int64) -> Array[Int64] {
  if n < 0 {
    return []
  }
  let m = if modulus <= 0L { 1L } else { modulus }
  let p = Array::make(n + 1, 0L)
  p[0] = 1L
  for k in 1..<=n {
    let mut total = 0L
    let mut j = 1
    while true {
      let g1 = j * (3 * j - 1) / 2
      let g2 = j * (3 * j + 1) / 2
      if g1 > k {
        break
      }
      let sign = if j % 2 == 1 { 1L } else { -1L }
      let term1 = p[k - g1]
      total = (total + sign * term1) % m
      if g2 <= k {
        let term2 = p[k - g2]
        total = (total + sign * term2) % m
      }
      j = j + 1
    }
    // Wrap to non-negative.
    if total < 0L {
      total = total + m
    }
    p[k] = total
  }
  p
}

///|
/// Plain `p(n)` for small `n` (fits in `Int64` only up to `n ≈ 416`).
/// Returns `0` for `n < 0`.
pub fn partition(n : Int) -> Int64 {
  if n < 0 {
    return 0L
  }
  // Effective modulus = 2^62, large enough that no wrap happens for
  // n <= 416 (where p(n) < 2^62). Beyond that, the result wraps; use
  // partition_table_mod with an explicit modulus for safe big-n usage.
  let table = partition_table_mod(n, 4611686018427387904L)
  table[n]
}

///|
/// Compute the **number of partitions of `n` into distinct parts**:
/// `q(n)`. Recurrence is the same as `p` but with the alternating sign
/// inside the pentagonal recurrence cancelled by a parity argument; in
/// practice we just compute via generating function
///
///   q(n) = sum_{j=1..} (-1)^{j+1} * q(n - j(3j-1)/2) ...  -- same shape
///
/// but with a different starting recurrence. We use a direct O(n*sqrt n)
/// approach via a DP over parts:
///
///   dp[i][n] = #partitions of n with all parts <= i, distinct
///   dp[i][n] = dp[i-1][n] + dp[i-1][n-i]
///
/// for `i = 1..n`. With rolling rows, space is O(n).
pub fn distinct_partition_table(n : Int) -> Array[Int64] {
  if n < 0 {
    return []
  }
  let dp = Array::make(n + 1, 0L)
  dp[0] = 1L
  for i in 1..<=n {
    let mut k = n
    while k >= i {
      dp[k] = dp[k] + dp[k - i]
      k = k - 1
    }
  }
  dp
}

///|
test "partition small values" {
  // p(0..15) = 1, 1, 2, 3, 5, 7, 11, 15, 22, 30, 42, 56, 77, 101, 135, 176
  let expected : ReadOnlyArray[Int64] = [
    1L, 1L, 2L, 3L, 5L, 7L, 11L, 15L, 22L, 30L, 42L, 56L, 77L, 101L, 135L, 176L,
  ]
  let p = partition_table_mod(15, 1000000000000000L)
  for k in 0..<=15 {
    @debug.assert_eq(p[k], expected[k])
  }
}

///|
test "partition single function matches table" {
  let table = partition_table_mod(20, 1000000000000000L)
  for k in 0..<=20 {
    @debug.assert_eq(partition(k), table[k])
  }
}

///|
test "partition modular consistency" {
  let big_m = 1000000007L
  let small_m = 17L
  let p_big = partition_table_mod(50, big_m)
  let p_small = partition_table_mod(50, small_m)
  for k in 0..<=50 {
    @debug.assert_eq(p_small[k], p_big[k] % small_m)
  }
}

///|
test "partition edge cases" {
  @debug.assert_eq(partition_table_mod(-1, 7L), [])
  @debug.assert_eq(partition_table_mod(0, 7L), [1L])
  @debug.assert_eq(partition(-5), 0L)
}

///|
test "distinct partitions small values" {
  // q(0..10) = 1, 1, 1, 2, 2, 3, 4, 5, 6, 8, 10
  let expected : ReadOnlyArray[Int64] = [
    1L, 1L, 1L, 2L, 2L, 3L, 4L, 5L, 6L, 8L, 10L,
  ]
  let q = distinct_partition_table(10)
  for k in 0..<=10 {
    @debug.assert_eq(q[k], expected[k])
  }
}

///|
test "partition vs distinct (Euler)" {
  // Euler's theorem: #partitions into distinct parts = #partitions into
  // odd parts. We don't compute the latter, but distinct should match
  // the standard q-sequence.
  let q = distinct_partition_table(20)
  // OEIS A000009: 1, 1, 1, 2, 2, 3, 4, 5, 6, 8, 10, 12, 15, 18, 22, 27,
  //               32, 38, 46, 54, 64
  let expected : ReadOnlyArray[Int64] = [
    1L, 1L, 1L, 2L, 2L, 3L, 4L, 5L, 6L, 8L, 10L, 12L, 15L, 18L, 22L, 27L, 32L, 38L,
    46L, 54L, 64L,
  ]
  for k in 0..<=20 {
    @debug.assert_eq(q[k], expected[k])
  }
}

///|
test "partition larger n agrees with known" {
  // p(50) = 204226, p(100) = 190569292.
  let p = partition_table_mod(100, 1000000000000000000L)
  @debug.assert_eq(p[50], 204226L)
  @debug.assert_eq(p[100], 190569292L)
}
