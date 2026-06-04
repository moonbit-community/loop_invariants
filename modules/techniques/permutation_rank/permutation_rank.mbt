// ============================================================================
// PERMUTATION RANK / UNRANK  -  Lehmer code
// ============================================================================
//
// PROBLEM
//
// Bijection between permutations of `{0, 1, ..., n - 1}` and the
// integers `{0, 1, ..., n! - 1}` in lexicographic order. The forward
// direction (`rank`) maps a permutation `p` to its position; the inverse
// (`unrank`) recovers the permutation from a position.
//
// LEHMER CODE
//
// For a permutation `p`, its Lehmer code is `c[i] = #{j > i : p[j] < p[i]}`.
// The integer rank is then `sum c[i] * (n - 1 - i)!`.
//
// To unrank: peel digits off the factorial-base representation, each
// digit indexing into the still-available set.
//
// COMPLEXITY
//
//   rank   : O(n^2) naively; O(n log n) with a Fenwick tree.
//   unrank : O(n^2) naively; O(n log n) with an order-statistic tree.
//
// We use the O(n^2) variant -- still fast for n <= 20, the largest
// where n! fits in `Int64` anyway.
//
// THE INVARIANT
//
//   "After processing index i, rank equals the number of permutations
//    of {0, .., n-1} that begin with a prefix lexicographically less
//    than p[0..i] (relative to the still-available element set)."

///|
const MAX_N : Int = 20

///|
fn factorial(n : Int) -> Int64 {
  let mut r = 1L
  for i in 2..<=n {
    r = r * i.to_int64()
  }
  r
}

///|
/// Lexicographic rank (0-indexed) of permutation `p` of `{0, 1, ..., n-1}`.
/// Returns `0` for `p.length() == 0` or `p.length() > 20`.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   // Among the 6 permutations of {0, 1, 2}, [1, 0, 2] is at rank 2.
///   @debug.assert_eq(@permutation_rank.rank([1, 0, 2]), 2L)
/// }
/// ```
pub fn rank(p : Array[Int]) -> Int64 {
  let n = p.length()
  if n == 0 || n > MAX_N {
    return 0L
  }
  let mut total = 0L
  for i in 0..<n {
    let mut smaller_right = 0
    for j in (i + 1)..<n {
      if p[j] < p[i] {
        smaller_right = smaller_right + 1
      }
    }
    total = total + smaller_right.to_int64() * factorial(n - 1 - i)
  }
  total
}

///|
/// Inverse of `rank`: produce the permutation of `{0, ..., n-1}` at the
/// given rank. Returns an empty array when `n == 0` or `n > 20` or
/// `rank < 0` or `rank >= n!`.
pub fn unrank(n : Int, rank : Int64) -> Array[Int] {
  if n <= 0 || n > MAX_N || rank < 0L || rank >= factorial(n) {
    return []
  }
  let avail : Array[Int] = Array::makei(n, i => i)
  let res : Array[Int] = []
  let mut r = rank
  for i in 0..<n {
    let f = factorial(n - 1 - i)
    let idx = (r / f).to_int()
    r = r % f
    res.push(avail[idx])
    avail.remove(idx) |> ignore
  }
  res
}

///|
test "rank small" {
  // Permutations of {0, 1, 2} in lex order:
  //   0 [0,1,2], 1 [0,2,1], 2 [1,0,2], 3 [1,2,0], 4 [2,0,1], 5 [2,1,0]
  @debug.assert_eq(rank([0, 1, 2]), 0L)
  @debug.assert_eq(rank([0, 2, 1]), 1L)
  @debug.assert_eq(rank([1, 0, 2]), 2L)
  @debug.assert_eq(rank([1, 2, 0]), 3L)
  @debug.assert_eq(rank([2, 0, 1]), 4L)
  @debug.assert_eq(rank([2, 1, 0]), 5L)
}

///|
test "unrank small" {
  @debug.assert_eq(unrank(3, 0L), [0, 1, 2])
  @debug.assert_eq(unrank(3, 1L), [0, 2, 1])
  @debug.assert_eq(unrank(3, 2L), [1, 0, 2])
  @debug.assert_eq(unrank(3, 3L), [1, 2, 0])
  @debug.assert_eq(unrank(3, 4L), [2, 0, 1])
  @debug.assert_eq(unrank(3, 5L), [2, 1, 0])
}

///|
test "rank unrank roundtrip" {
  for n in 0..<=6 {
    let total = factorial(n)
    let mut r = 0L
    while r < total {
      let p = unrank(n, r)
      @debug.assert_eq(rank(p), r)
      r = r + 1L
    }
  }
}

///|
test "rank single and empty" {
  @debug.assert_eq(rank([]), 0L)
  @debug.assert_eq(rank([0]), 0L)
}

///|
test "unrank out of range" {
  @debug.assert_eq(unrank(0, 0L), [])
  @debug.assert_eq(unrank(3, -1L), [])
  @debug.assert_eq(unrank(3, 6L), []) // 3! = 6, max valid rank is 5
}

///|
test "rank larger n" {
  // 10! = 3628800; identity has rank 0.
  let n = 10
  let p = Array::makei(n, i => i)
  @debug.assert_eq(rank(p), 0L)
  // Last permutation is descending; rank = n! - 1.
  let p_last = Array::makei(n, i => n - 1 - i)
  @debug.assert_eq(rank(p_last), factorial(n) - 1L)
}
