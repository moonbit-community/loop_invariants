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
/// The result returned by `longest_common_substring`.
///
/// Fields:
/// - `substring` : the actual longest common contiguous substring (may be
///                 empty when no characters match).
/// - `length`    : the length of `substring` in UTF-16 code units; equals
///                 `0` when `substring` is empty.
///
/// When multiple substrings tie for the maximum length the first one
/// encountered while scanning `a` left to right is returned.
pub(all) struct LCSResult {
  substring : String
  length : Int
}

///|
/// Build a fresh `String` from code units `s[start..<end]`.
///
/// Uses a `StringBuilder` so the result is always a new allocation
/// independent of the source string.  This helper exists because MoonBit
/// `String` does not expose a direct slice constructor.
fn slice_string(s : String, start : Int, end : Int) -> String {
  let sb = StringBuilder::new()
  for idx in start..<end {
    let ch = s[idx].to_int()
    sb.write_char(ch.unsafe_to_char())
  }
  sb.to_string()
}

///|
/// Return the longest contiguous substring that appears in both `a` and `b`.
///
/// Uses a space-optimised dynamic programming approach that keeps only two
/// rows of the DP table at a time (O(m) space instead of O(n * m)).
///
/// The recurrence is:
///
/// ```
/// dp[i][j] = dp[i-1][j-1] + 1   if a[i-1] == b[j-1]
///          = 0                   otherwise
/// ```
///
/// The value `dp[i][j]` is the length of the longest common suffix of the
/// prefixes `a[0..i)` and `b[0..j)` that ends exactly at `a[i-1]` and
/// `b[j-1]`.  The answer is the maximum over all cells, together with the
/// position in `a` where that maximum ends.
///
/// Parameters:
/// - `a` : first input string (UTF-16, indexed by code unit).
/// - `b` : second input string (UTF-16, indexed by code unit).
///
/// Returns an `LCSResult` with the substring and its length.  If either
/// input is empty, or if the strings share no characters, the result has
/// `substring = ""` and `length = 0`.
///
/// Time: O(n * m) where `n = a.length()` and `m = b.length()`.
/// Space: O(m).
pub fn longest_common_substring(a : String, b : String) -> LCSResult {
  let n = a.length()
  let m = b.length()
  if n == 0 || m == 0 {
    return { substring: "", length: 0 }
  }
  let init_prev = Array::make(m + 1, 0)
  let init_curr = Array::make(m + 1, 0)
  let (best_len, best_end) = for
    i in 1..<=n
    prev = init_prev, curr = init_curr, best_len = 0, best_end = 0 {
    let (best_len, best_end) = for
      j in 1..<=m
      best_len = best_len, best_end = best_end {
      if a[i - 1] == b[j - 1] {
        curr[j] = prev[j - 1] + 1
        if curr[j] > best_len {
          continue curr[j], i
        } else {
          continue best_len, best_end
        }
      } else {
        curr[j] = 0
        continue best_len, best_end
      }
    } nobreak {
      (best_len, best_end)
    }
    prev.fill(0)
    continue curr, prev, best_len, best_end
  } nobreak {
    (best_len, best_end)
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
  debug_inspect(result.substring, content=(
    #|"anana"
  ))
  debug_inspect(result.length, content="5")
}

///|
test "lcs no match" {
  let result = longest_common_substring("abc", "xyz")
  debug_inspect(result.substring, content=(
    #|""
  ))
  debug_inspect(result.length, content="0")
}

///|
test "lcs identical strings" {
  let result = longest_common_substring("hello", "hello")
  debug_inspect(result.substring, content=(
    #|"hello"
  ))
  debug_inspect(result.length, content="5")
}
