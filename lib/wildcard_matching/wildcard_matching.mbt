// ============================================================================
// WILDCARD MATCHING - DP with '*' and '?'
// ============================================================================
//
// Pattern rules:
// - '?' matches any single character
// - '*' matches any sequence (including empty)
//
// We compute dp[j] = match(text[0..i), pattern[0..j)) using rolling DP.
//
// TIME COMPLEXITY: O(n * m)
// SPACE COMPLEXITY: O(m)

///|
/// Return true if text matches pattern with '?' and '*'.
pub fn wildcard_match(text : String, pattern : String) -> Bool {
  let n = text.length()
  let m = pattern.length()
  let dp = Array::make(m + 1, false)
  dp[0] = true

  // Initialize dp for empty text and pattern prefix of '*'.
  for j = 1; j <= m; j = j + 1 {
    if pattern[j - 1] == '*' {
      dp[j] = dp[j - 1]
    } else {
      dp[j] = false
    }
  } where {
    invariant: j >= 1 && j <= m + 1,
    reasoning: (
      #|INVARIANT (init dp):
      #|dp[j] is true iff pattern[0..j) consists only of '*' characters.
      #|MAINTENANCE:
      #|Extend dp using dp[j-1] when pattern[j-1] is '*'.
      #|TERMINATION:
      #|At j = m, dp encodes matches for empty text.
    ),
  }
  for i = 1; i <= n; i = i + 1 {
    let mut prev = dp[0]
    dp[0] = false
    for j = 1; j <= m; j = j + 1 {
      let tmp = dp[j]
      let p = pattern[j - 1]
      if p == '*' {
        dp[j] = dp[j] || dp[j - 1]
      } else if p == '?' || p == text[i - 1] {
        dp[j] = prev
      } else {
        dp[j] = false
      }
      prev = tmp
    } where {
      invariant: j >= 1 && j <= m + 1,
      reasoning: (
        #|INVARIANT (row update):
        #|dp[0..j) reflects matches for text[0..i) and pattern[0..j).
        #|prev stores the old dp[j-1] (diagonal) from the previous row.
        #|MAINTENANCE:
        #|Handle '*' (expand or skip), '?' (single match), and exact match.
        #|TERMINATION:
        #|At j = m, the full row for text prefix i is computed.
      ),
    }
  } where {
    invariant: i >= 1 && i <= n + 1,
    reasoning: (
      #|INVARIANT (outer DP):
      #|dp encodes matches for text[0..i) against all pattern prefixes.
      #|MAINTENANCE:
      #|Update dp in place using the previous row via prev and tmp.
      #|TERMINATION:
      #|At i = n, dp[m] is the final match result.
    ),
  }
  dp[m]
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "wildcard basic" {
  inspect(wildcard_match("aaabxc", "a*b?c"), content="true")
  inspect(wildcard_match("abc", "a?c"), content="true")
  inspect(wildcard_match("ac", "a?c"), content="false")
}

///|
test "wildcard star" {
  inspect(wildcard_match("", "*"), content="true")
  inspect(wildcard_match("hello", "*"), content="true")
  inspect(wildcard_match("hello", "h*o"), content="true")
}
