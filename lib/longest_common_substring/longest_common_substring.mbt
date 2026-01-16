// ============================================================================
// LONGEST COMMON SUBSTRING - Dynamic Programming
// ============================================================================
//
// We compute the length of the longest common suffix ending at positions i-1
// and j-1, and track the best length/end position seen so far.
//
// dp[i][j] = (a[i-1] == b[j-1]) ? dp[i-1][j-1] + 1 : 0
//
// TIME COMPLEXITY: O(n * m)
// SPACE COMPLEXITY: O(m)

///|
pub(all) struct LCSResult {
  substring : String
  length : Int
}

///|
fn slice_string(s : String, start : Int, end : Int) -> String {
  let sb = StringBuilder::new()
  for idx in start..<end {
    let ch = s[idx].to_int()
    sb.write_char(ch.unsafe_to_char())
  }
  sb.to_string()
}

///|
/// Compute the longest common substring of a and b.
/// If no common substring exists, returns empty string with length 0.
pub fn longest_common_substring(a : String, b : String) -> LCSResult {
  let n = a.length()
  let m = b.length()
  if n == 0 || m == 0 {
    return { substring: "", length: 0 }
  }
  let mut prev = Array::make(m + 1, 0)
  let mut curr = Array::make(m + 1, 0)
  let mut best_len = 0
  let mut best_end = 0
  for i = 1; i <= n; i = i + 1 {
    for j = 1; j <= m; j = j + 1 {
      if a[i - 1] == b[j - 1] {
        curr[j] = prev[j - 1] + 1
        if curr[j] > best_len {
          best_len = curr[j]
          best_end = i
        }
      } else {
        curr[j] = 0
      }
    } where {
      invariant: j >= 1 && j <= m + 1,
      reasoning: (
        #|INVARIANT (row update):
        #|curr[1..j) stores longest common suffix lengths for a[0..i) and
        #|b[0..j), and best_len/best_end track the best substring seen so far.
        #|MAINTENANCE:
        #|If a[i-1] == b[j-1], extend the suffix; otherwise reset to 0.
        #|TERMINATION:
        #|At j = m, the entire row for i is computed.
      ),
    }
    let tmp = prev
    prev = curr
    curr = tmp
    curr.fill(0)
  } where {
    invariant: i >= 1 && i <= n + 1,
    reasoning: (
      #|INVARIANT (outer DP):
      #|prev holds the DP row for a[0..i), and best_len/best_end record the
      #|longest common substring within prefixes a[0..i) and b[0..m).
      #|MAINTENANCE:
      #|Compute the next row into curr, then swap into prev.
      #|TERMINATION:
      #|At i = n, best_len/best_end describe the global LCS.
    ),
  }
  if best_len == 0 {
    { substring: "", length: 0 }
  } else {
    let start = best_end - best_len
    { substring: slice_string(a, start, best_end), length: best_len }
  }
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "lcs banana ananas" {
  let result = longest_common_substring("banana", "ananas")
  inspect(result.substring, content="anana")
  inspect(result.length, content="5")
}

///|
test "lcs no match" {
  let result = longest_common_substring("abc", "xyz")
  inspect(result.substring, content="")
  inspect(result.length, content="0")
}
