// ============================================================================
// LONGEST PALINDROMIC SUBSEQUENCE  -  O(n^2) DP
// ============================================================================
//
// PROBLEM
//
// Given a sequence `s`, find the length of the **longest palindromic
// subsequence** (LPS): the longest subsequence (not necessarily
// contiguous) that reads the same forwards and backwards.
//
// E.g. "BBABCBCAB" -> 7 ("BABCBAB").
//
// EQUIVALENT FORMULATION
//
// `LPS(s) = LCS(s, reverse(s))`. So one option is to call any
// LCS implementation on s and reverse(s). The direct DP avoids the
// extra string copy and is what we use here.
//
// THE DP
//
//   lps[i][j] = LPS length of s[i..j].
//   lps[i][i] = 1
//   lps[i][j] = lps[i+1][j-1] + 2                if s[i] == s[j]
//             = max(lps[i+1][j], lps[i][j-1])    otherwise
//
// Iterate by increasing length `len = j - i + 1`.
//
// COMPLEXITY
//
//   Time : O(n^2)
//   Space: O(n^2) for the full DP; the reconstruction needs the table.
//
// PATH RECONSTRUCTION
//
// Walk from (0, n-1) back: when `s[i] == s[j]`, add both ends and
// recurse on (i+1, j-1); otherwise step into whichever direction
// matches `lps[i][j]`.
//
// THE INVARIANT
//
//   "After processing all (i, j) with j - i + 1 <= L, lps[i'][j'] is
//    the LPS length of s[i'..j'] for every i', j' with that length."

///|
/// Length of the LPS of the input. Items are compared by `==`.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let s = "BBABCBCAB".to_array().map(c => c.to_int())
///   @debug.assert_eq(@longest_palindromic_subsequence.length(s), 7)
/// }
/// ```
pub fn length(s : Array[Int]) -> Int {
  let n = s.length()
  if n == 0 {
    return 0
  }
  let lps = Array::makei(n, _ => Array::make(n, 0))
  for i in 0..<n {
    lps[i][i] = 1
  }
  for len in 2..<=n {
    for i in 0..<=(n - len) {
      let j = i + len - 1
      if s[i] == s[j] {
        let inner = if len == 2 { 0 } else { lps[i + 1][j - 1] }
        lps[i][j] = inner + 2
      } else {
        let a = lps[i + 1][j]
        let b = lps[i][j - 1]
        lps[i][j] = if a > b { a } else { b }
      }
    }
  }
  lps[0][n - 1]
}

///|
/// Length plus one realising palindromic subsequence (returned as an
/// `Array[Int]` in left-to-right order).
pub fn length_and_path(s : Array[Int]) -> (Int, Array[Int]) {
  let n = s.length()
  if n == 0 {
    return (0, [])
  }
  let lps = Array::makei(n, _ => Array::make(n, 0))
  for i in 0..<n {
    lps[i][i] = 1
  }
  for len in 2..<=n {
    for i in 0..<=(n - len) {
      let j = i + len - 1
      if s[i] == s[j] {
        let inner = if len == 2 { 0 } else { lps[i + 1][j - 1] }
        lps[i][j] = inner + 2
      } else {
        let a = lps[i + 1][j]
        let b = lps[i][j - 1]
        lps[i][j] = if a > b { a } else { b }
      }
    }
  }
  // Reconstruct.
  let left : Array[Int] = []
  let right : Array[Int] = []
  let mut i = 0
  let mut j = n - 1
  while i < j {
    if s[i] == s[j] {
      left.push(s[i])
      right.push(s[j])
      i = i + 1
      j = j - 1
    } else if lps[i + 1][j] >= lps[i][j - 1] {
      i = i + 1
    } else {
      j = j - 1
    }
  }
  if i == j {
    left.push(s[i])
  }
  // right was pushed in outer-to-inner order; reverse and concatenate.
  let mut k = right.length() - 1
  while k >= 0 {
    left.push(right[k])
    k = k - 1
  }
  (lps[0][n - 1], left)
}

///|
fn is_palindrome(a : Array[Int]) -> Bool {
  let n = a.length()
  for i in 0..<(n / 2) {
    if a[i] != a[n - 1 - i] {
      return false
    }
  }
  true
}

///|
fn is_subsequence(sub : Array[Int], full : Array[Int]) -> Bool {
  let mut i = 0
  let mut j = 0
  while i < sub.length() && j < full.length() {
    if sub[i] == full[j] {
      i = i + 1
    }
    j = j + 1
  }
  i == sub.length()
}

///|
fn s(str : String) -> Array[Int] {
  let r : Array[Int] = []
  for c in str {
    r.push(c.to_int())
  }
  r
}

///|
test "lps classic example" {
  @debug.assert_eq(length(s("BBABCBCAB")), 7)
}

///|
test "lps short examples" {
  @debug.assert_eq(length(s("a")), 1)
  @debug.assert_eq(length(s("ab")), 1)
  @debug.assert_eq(length(s("aa")), 2)
  @debug.assert_eq(length(s("aba")), 3)
  @debug.assert_eq(length(s("abab")), 3)
  @debug.assert_eq(length(s("abcde")), 1)
}

///|
test "lps empty" {
  @debug.assert_eq(length([]), 0)
}

///|
test "lps reconstruction is a palindrome and subsequence" {
  let cases = ["BBABCBCAB", "agbdba", "character", "abcdef", "aaaa", "racecar"]
  for c in cases {
    let arr = s(c)
    let (len, seq) = length_and_path(arr)
    @debug.assert_eq(length(arr), len)
    @debug.assert_eq(seq.length(), len)
    @debug.assert_eq(is_palindrome(seq), true)
    @debug.assert_eq(is_subsequence(seq, arr), true)
  }
}

///|
test "lps palindrome trivially" {
  let arr = s("racecar")
  @debug.assert_eq(length(arr), arr.length())
}
