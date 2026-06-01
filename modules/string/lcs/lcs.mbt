// ============================================================================
// LONGEST COMMON SUBSEQUENCE  -  O(n m) Wagner-Fischer
// ============================================================================
//
// PROBLEM
//
// Given two sequences `a` and `b`, find the longest sequence `c` that
// is a **subsequence** of both (elements need not be contiguous).
//
// E.g. a = "ABCBDAB", b = "BDCAB" -> "BCAB" (length 4).
//
// Distinct from `string/longest_common_substring`, which is the
// *contiguous* version.
//
// THE DP
//
//   lcs[i][j] = LCS length of a[0..i) and b[0..j)
//   lcs[0][_] = lcs[_][0] = 0
//   lcs[i][j] = lcs[i-1][j-1] + 1                       if a[i-1] == b[j-1]
//             = max(lcs[i-1][j], lcs[i][j-1])           otherwise
//
// COMPLEXITY
//
//   Time : O(n * m)
//   Space: O(n * m) for the full DP with reconstruction; O(min(n, m))
//          for length-only via rolling rows.
//
// PATH RECONSTRUCTION
//
// Walk back from (n, m): on equality, take the character and step
// diagonally; otherwise step toward the larger neighbour.
//
// THE INVARIANT
//
//   "After processing cell (i, j), lcs[i'][j'] equals the LCS of
//    a[0..i') and b[0..j') for every (i', j') with i' <= i and
//    j' <= j."

///|
/// Length of the longest common subsequence. Uses rolling-row DP in
/// `O(min(n, m))` extra space.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let a = "ABCBDAB".to_array().map(c => c.to_int())
///   let b = "BDCAB".to_array().map(c => c.to_int())
///   @debug.assert_eq(@lcs.length(a, b), 4)
/// }
/// ```
pub fn length(a : Array[Int], b : Array[Int]) -> Int {
  let n = a.length()
  let m = b.length()
  if n == 0 || m == 0 {
    return 0
  }
  // Ensure inner loop runs on the shorter dimension.
  let (x, y) = if n < m { (b, a) } else { (a, b) }
  let nx = x.length()
  let ny = y.length()
  let prev = Array::make(ny + 1, 0)
  let cur = Array::make(ny + 1, 0)
  for i in 1..<=nx {
    cur[0] = 0
    for j in 1..<=ny {
      if x[i - 1] == y[j - 1] {
        cur[j] = prev[j - 1] + 1
      } else {
        let a_left = prev[j]
        let b_above = cur[j - 1]
        cur[j] = if a_left > b_above { a_left } else { b_above }
      }
    }
    for j in 0..<=ny {
      prev[j] = cur[j]
    }
  }
  prev[ny]
}

///|
/// Return the length and one realising LCS sequence (in original order).
pub fn length_and_path(a : Array[Int], b : Array[Int]) -> (Int, Array[Int]) {
  let n = a.length()
  let m = b.length()
  if n == 0 || m == 0 {
    return (0, [])
  }
  let dp = Array::makei(n + 1, _ => Array::make(m + 1, 0))
  for i in 1..<=n {
    for j in 1..<=m {
      if a[i - 1] == b[j - 1] {
        dp[i][j] = dp[i - 1][j - 1] + 1
      } else {
        let l = dp[i - 1][j]
        let r = dp[i][j - 1]
        dp[i][j] = if l > r { l } else { r }
      }
    }
  }
  // Reconstruct.
  let path : Array[Int] = []
  let mut i = n
  let mut j = m
  while i > 0 && j > 0 {
    if a[i - 1] == b[j - 1] {
      path.push(a[i - 1])
      i = i - 1
      j = j - 1
    } else if dp[i - 1][j] >= dp[i][j - 1] {
      i = i - 1
    } else {
      j = j - 1
    }
  }
  // Reverse.
  let mut l = 0
  let mut r = path.length() - 1
  while l < r {
    let t = path[l]
    path[l] = path[r]
    path[r] = t
    l = l + 1
    r = r - 1
  }
  (dp[n][m], path)
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
fn is_subseq(sub : Array[Int], full : Array[Int]) -> Bool {
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
test "lcs classic example" {
  @debug.assert_eq(length(s("ABCBDAB"), s("BDCAB")), 4)
}

///|
test "lcs empty inputs" {
  @debug.assert_eq(length([], [1, 2, 3]), 0)
  @debug.assert_eq(length([1, 2], []), 0)
  @debug.assert_eq(length([], []), 0)
}

///|
test "lcs equal inputs" {
  let a = s("hello")
  @debug.assert_eq(length(a, a), a.length())
}

///|
test "lcs disjoint" {
  @debug.assert_eq(length(s("abc"), s("xyz")), 0)
}

///|
test "lcs reconstruction is a valid subseq of both" {
  let cases : ReadOnlyArray[(String, String)] = [
    ("ABCBDAB", "BDCAB"),
    ("AGGTAB", "GXTXAYB"),
    ("hello", "world"),
    ("programming", "logarithm"),
    ("", "abc"),
    ("xyz", ""),
  ]
  for c in cases {
    let a = s(c.0)
    let b = s(c.1)
    let (len, seq) = length_and_path(a, b)
    @debug.assert_eq(length(a, b), len)
    @debug.assert_eq(seq.length(), len)
    @debug.assert_eq(is_subseq(seq, a), true)
    @debug.assert_eq(is_subseq(seq, b), true)
  }
}

///|
test "lcs symmetry" {
  let cases : ReadOnlyArray[(String, String)] = [
    ("abcdef", "ace"),
    ("ABCBDAB", "BDCAB"),
    ("hello world", "hello there"),
  ]
  for c in cases {
    let a = s(c.0)
    let b = s(c.1)
    @debug.assert_eq(length(a, b), length(b, a))
  }
}

///|
test "lcs by brute force on small inputs" {
  fn brute(a : Array[Int], b : Array[Int]) -> Int {
    let n = a.length()
    let m = b.length()
    if n == 0 || m == 0 {
      return 0
    }
    let mut best = 0
    let mut mask = 0
    while mask < 1 << n {
      let sub : Array[Int] = []
      for k in 0..<n {
        if ((mask >> k) & 1) == 1 {
          sub.push(a[k])
        }
      }
      if is_subseq(sub, b) && sub.length() > best {
        best = sub.length()
      }
      mask = mask + 1
    }
    best
  }

  let cases : ReadOnlyArray[(String, String)] = [
    ("abc", "ac"),
    ("axbycz", "abc"),
    ("aabbcc", "abc"),
    ("xyz", "yzx"),
  ]
  for c in cases {
    let a = s(c.0)
    let b = s(c.1)
    @debug.assert_eq(length(a, b), brute(a, b))
  }
}
