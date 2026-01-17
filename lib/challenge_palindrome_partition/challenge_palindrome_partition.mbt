// ============================================================================
// Challenge: Palindrome Partition (Min Cuts)
// ============================================================================

///|
const INF : Int = 0x3fffffff

///|
/// Minimum cuts to partition s into palindromes.
pub fn min_palindrome_cuts(s : String) -> Int {
  let n = s.length()
  if n == 0 {
    return 0
  }
  let pal : Array[Array[Bool]] = Array::makei(n, _ => Array::make(n, false))
  for i in 0..<n {
    pal[i][i] = true
  }
  for len in 2..<(n + 1) {
    for i in 0..<(n - len + 1) {
      let j = i + len - 1
      let ci = s.get_char(i)
      let cj = s.get_char(j)
      if ci is Some(c1) && cj is Some(c2) && c1 == c2 {
        if len == 2 || pal[i + 1][j - 1] {
          pal[i][j] = true
        }
      }
    }
  }
  let dp = Array::make(n, INF)
  for i in 0..<n {
    for j in 0..<(i + 1) {
      if pal[j][i] {
        if j == 0 {
          dp[i] = 0
        } else if dp[j - 1] + 1 < dp[i] {
          dp[i] = dp[j - 1] + 1
        }
      }
    }
  }
  dp[n - 1]
}
