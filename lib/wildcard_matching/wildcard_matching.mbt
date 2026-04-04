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
/// Return `true` if `text` matches `pattern` under wildcard rules.
///
/// Wildcard characters:
/// - `'?'` matches exactly one arbitrary character.
/// - `'*'` matches any sequence of characters, including the empty sequence.
///
/// All other characters match only themselves (case-sensitive).
///
/// ## Algorithm
///
/// The function uses a space-optimised dynamic programming approach.
/// Define `dp[i][j]` as `true` when `text[0..i)` matches `pattern[0..j)`.
///
/// Base cases:
/// - `dp[0][0] = true`  (empty text matches empty pattern)
/// - `dp[0][j] = true`  only when `pattern[0..j)` consists entirely of `'*'`
/// - `dp[i][0] = false` for `i >= 1`  (non-empty text never matches empty pattern)
///
/// Recurrence:
/// ```
/// pattern[j-1] is literal c or '?':
///   dp[i][j] = dp[i-1][j-1]  if p=='?' or p==text[i-1]
///            = false          otherwise
///
/// pattern[j-1] is '*':
///   dp[i][j] = dp[i][j-1]    // '*' matches zero chars (skip star)
///           OR dp[i-1][j]    // '*' consumes text[i-1] (star extends)
/// ```
///
/// Only one rolling array of length `m+1` is kept in memory.
/// The diagonal value `dp[i-1][j-1]` is preserved in the loop variable
/// `prev` before `dp[j-1]` is overwritten.
///
/// ## Examples
///
/// ```moonbit
/// // Literal match with wildcards
/// assert_true!(wildcard_match("aaabxc", "a*b?c"))
/// assert_true!(wildcard_match("abc",    "a?c"))
///
/// // '?' requires exactly one character
/// assert_false!(wildcard_match("ac", "a?c"))
///
/// // '*' matches empty or many characters
/// assert_true!(wildcard_match("",      "*"))
/// assert_true!(wildcard_match("hello", "*"))
/// assert_true!(wildcard_match("hello", "h*o"))
///
/// // Exact match (no wildcards)
/// assert_true!(wildcard_match("abc", "abc"))
/// assert_false!(wildcard_match("abc", "ab"))
///
/// // Multiple wildcards
/// assert_true!(wildcard_match("abcde", "a*c*e"))
/// assert_true!(wildcard_match("abcde", "*****"))
/// assert_true!(wildcard_match("abc",   "???"))
/// assert_false!(wildcard_match("ab",   "???"))
/// ```
///
/// ## Complexity
///
/// Time: O(n * m), Space: O(m), where n = text length, m = pattern length.
pub fn wildcard_match(text : String, pattern : String) -> Bool {
  let n = text.length()
  let m = pattern.length()
  let dp = Array::make(m + 1, false)
  dp[0] = true

  // Initialize dp for empty text and pattern prefix of '*'.
  for j in 1..<=m {
    if pattern[j - 1] == '*' {
      dp[j] = dp[j - 1]
    } else {
      dp[j] = false
    }
  } where {
    proof_invariant: j >= 1 && j <= m + 1,
    proof_reasoning: (
      #|INVARIANT (init dp):
      #|dp[j] is true iff pattern[0..j) consists only of '*' characters.
      #|MAINTENANCE:
      #|Extend dp using dp[j-1] when pattern[j-1] is '*'.
      #|TERMINATION:
      #|At j = m, dp encodes matches for empty text.
    ),
  }
  for i in 1..<=n {
    let old_dp0 = dp[0]
    dp[0] = false
    let _ = for j = 1, prev = old_dp0; j <= m; {
      let tmp = dp[j]
      let p = pattern[j - 1]
      if p == '*' {
        dp[j] = dp[j] || dp[j - 1]
      } else if p == '?' || p == text[i - 1] {
        dp[j] = prev
      } else {
        dp[j] = false
      }
      continue j + 1, tmp
    } nobreak {
      prev
    } where {
      proof_invariant: j >= 1 && j <= m + 1,
      proof_reasoning: (
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
    proof_invariant: i >= 1 && i <= n + 1,
    proof_reasoning: (
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
