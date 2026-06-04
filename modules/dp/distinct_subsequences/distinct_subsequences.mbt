// ============================================================================
// DISTINCT SUBSEQUENCES  -  LC 115 / Distinct Sequences mod p
// ============================================================================
//
// PROBLEM
//
// Count the number of **distinct** subsequences of `s` that equal a
// target string `t`. Each subsequence is a way to delete some
// characters of `s` (possibly none) without rearranging the rest so
// that the remaining string equals `t`.
//
// E.g. s = "rabbbit", t = "rabbit" -> 3 distinct ways.
//
// THE DP
//
//   dp[i][j] = #distinct subsequences of s[0..i] equal to t[0..j]
//   dp[i][0] = 1     (empty t is matched by the unique empty subseq)
//   dp[0][j] = 0     for j > 0
//   dp[i][j] = dp[i-1][j]                                 (skip s[i-1])
//           + dp[i-1][j-1]        if s[i-1] == t[j-1]    (use s[i-1])
//
// We roll the table to one dimension and iterate `j` from high to low.
//
// Also classic: **count all distinct subsequences of s** (including
// the empty one) via
//
//   dp[i] = 2 * dp[i-1] - dp[last[s[i-1]] - 1]
//
// where `last[c]` is the previous index of `c`; we provide it too.
//
// COMPLEXITY
//
//   count_equal_target(s, t) : O(|s| * |t|), O(|t|) rolling space
//   count_all_subseq(s)       : O(|s|), O(sigma) space
//
// THE INVARIANT
//
//   "After processing index i, dp[j] equals the number of distinct
//    subsequences of s[0..i] equal to t[0..j]."

///|
const MOD : Int64 = 1000000007L

///|
/// Number of distinct subsequences of `s` equal to `t`. Result mod
/// `1e9 + 7`.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let s = "rabbbit".to_array().map(c => c.to_int())
///   let t = "rabbit".to_array().map(c => c.to_int())
///   @debug.assert_eq(@distinct_subsequences.count_equal_target(s, t), 3L)
/// }
/// ```
pub fn count_equal_target(s : Array[Int], t : Array[Int]) -> Int64 {
  let n = s.length()
  let m = t.length()
  if m == 0 {
    return 1L
  }
  if n < m {
    return 0L
  }
  let dp = Array::make(m + 1, 0L)
  dp[0] = 1L
  for i in 1..<=n {
    let mut j = m
    while j >= 1 {
      if s[i - 1] == t[j - 1] {
        dp[j] = (dp[j] + dp[j - 1]) % MOD
      }
      j = j - 1
    }
  }
  dp[m]
}

///|
/// Number of distinct **non-empty** subsequences of `s`. Result mod
/// `1e9 + 7`. The unique empty subsequence is excluded; add 1 to
/// include it.
pub fn count_all_subseq(s : Array[Int]) -> Int64 {
  let n = s.length()
  // dp[i] = #distinct subsequences (including empty) of s[0..i].
  // dp[0] = 1.
  // dp[i] = 2 * dp[i-1] - (last[s[i-1]] != -1 ? dp[last - 1] : 0)
  let last : Map[Int, Int] = Map([], capacity=n)
  let dp = Array::make(n + 1, 0L)
  dp[0] = 1L
  for i in 1..<=n {
    let c = s[i - 1]
    let mut v = 2L * dp[i - 1] % MOD
    match last.get(c) {
      Some(prev) =>
        if prev - 1 >= 0 {
          v = (v - dp[prev - 1] + MOD) % MOD
        } else {
          v = (v - 1L + MOD) % MOD
        }
      None => ()
    }
    dp[i] = v
    last[c] = i
  }
  // Subtract 1 to exclude the empty subseq.
  (dp[n] - 1L + MOD) % MOD
}

///|
fn arr(str : String) -> Array[Int] {
  let r : Array[Int] = []
  for c in str {
    r.push(c.to_int())
  }
  r
}

///|
test "lc 115 rabbbit rabbit" {
  @debug.assert_eq(count_equal_target(arr("rabbbit"), arr("rabbit")), 3L)
}

///|
test "babgbag bag" {
  // babgbag has "bag" as a subsequence in 5 distinct ways.
  @debug.assert_eq(count_equal_target(arr("babgbag"), arr("bag")), 5L)
}

///|
test "empty target" {
  @debug.assert_eq(count_equal_target(arr("abc"), arr("")), 1L)
  @debug.assert_eq(count_equal_target(arr(""), arr("")), 1L)
}

///|
test "target longer than source" {
  @debug.assert_eq(count_equal_target(arr("ab"), arr("abc")), 0L)
}

///|
test "no matching subseq" {
  @debug.assert_eq(count_equal_target(arr("abc"), arr("xyz")), 0L)
}

///|
test "count_all_subseq small" {
  // "abc": non-empty subseqs are a, b, c, ab, ac, bc, abc -> 7.
  @debug.assert_eq(count_all_subseq(arr("abc")), 7L)
  // "aaa": distinct non-empty subseqs are a, aa, aaa -> 3.
  @debug.assert_eq(count_all_subseq(arr("aaa")), 3L)
  // Empty
  @debug.assert_eq(count_all_subseq(arr("")), 0L)
}

///|
test "count_all_subseq longer" {
  // "abab": distinct subseqs of length 1: a, b -> 2; length 2: aa, ab, ba, bb -> 4;
  // length 3: aab, aba, abb, bab -> 4; length 4: abab -> 1. Total 11.
  @debug.assert_eq(count_all_subseq(arr("abab")), 11L)
}
