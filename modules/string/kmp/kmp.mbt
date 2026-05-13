// ============================================================================
// KMP (Knuth-Morris-Pratt) String Matching Algorithm
// ============================================================================
//
// KMP finds all occurrences of a pattern in a text in O(n + m) time,
// where n = text length and m = pattern length.
//
// KEY INSIGHT: When a mismatch occurs at position j in the pattern, we don't
// need to restart from scratch. The failure function tells us the longest
// proper prefix of pattern[0..j) that is also a suffix. We can continue
// matching from there.
//
// FAILURE FUNCTION (also called "partial match table" or "LPS array"):
// fail[i] = length of longest proper prefix of pattern[0..i+1) that is also a suffix
//
// EXAMPLE for pattern "ABAB":
// i=0: "A" → fail[0] = 0 (no proper prefix)
// i=1: "AB" → fail[1] = 0 (no match)
// i=2: "ABA" → fail[2] = 1 ("A" is both prefix and suffix)
// i=3: "ABAB" → fail[3] = 2 ("AB" is both prefix and suffix)
//
// MATCHING PROCESS:
// When comparing text[i] with pattern[j]:
// - If match: advance both i and j
// - If mismatch: set j = fail[j-1] (or 0 if j=0), keep i
//
// WHY IT WORKS:
// If pattern[0..j) matched text[i-j..i), and we have a mismatch at j,
// then pattern[0..fail[j-1]) = pattern[j-fail[j-1]..j) = text[i-fail[j-1]..i),
// so we can continue matching pattern[fail[j-1]] against text[i].
//
// INVARIANTS:
// 1. fail[i] < i for all i (proper prefix)
// 2. fail[i] = length of longest border of pattern[0..i+1)
// 3. During matching: pattern[0..j) matches text[i-j..i)
//
// TIME COMPLEXITY: O(n + m)
// SPACE COMPLEXITY: O(m) for failure function

///|
/// Compute the failure function (also called LPS array or partial match table)
/// for a pattern string.
///
/// `fail[i]` is the length of the longest proper prefix of `pattern[0..i+1)`
/// that is also a suffix of `pattern[0..i+1)`.  This value tells the KMP
/// matcher how far back to jump in the pattern after a mismatch, so no
/// text character ever needs to be re-examined.
///
/// Parameters:
/// - `pattern` - the pattern string to preprocess
///
/// Returns an `Array[Int]` of length `pattern.length()`, or an empty array
/// when the pattern is empty.
///
/// Time complexity: O(m), where m = `pattern.length()`
/// Space complexity: O(m)
///
/// Example:
/// ```
/// // Pattern "ABAB":
/// //   fail[0] = 0  ("A"    - no proper prefix/suffix match)
/// //   fail[1] = 0  ("AB"   - no match)
/// //   fail[2] = 1  ("ABA"  - "A" is both prefix and suffix)
/// //   fail[3] = 2  ("ABAB" - "AB" is both prefix and suffix)
/// let fail = compute_failure("ABAB")
/// // fail == [0, 0, 1, 2]
/// ```
pub fn compute_failure(pattern : String) -> Array[Int] {
  let m = pattern.length()
  if m == 0 {
    return []
  }
  let fail = Array::make(m, 0)
  for i in 1..<m; k = 0 {
    let curr_k = for curr_k = k; curr_k > 0 && pattern[curr_k] != pattern[i]; {
      continue fail[curr_k - 1]
    } nobreak {
      curr_k
    }
    let next_k = if pattern[curr_k] == pattern[i] { curr_k + 1 } else { curr_k }
    fail[i] = next_k
    continue next_k
  }
  fail
}

///|
/// Alias for `compute_failure`.  Returns the prefix function (pi array) for
/// the given pattern, where `pi[i]` equals the length of the longest proper
/// prefix of `pattern[0..i+1)` that is also a suffix.
///
/// Parameters:
/// - `pattern` - the pattern string to preprocess
///
/// Returns an `Array[Int]` identical to `compute_failure(pattern)`.
///
/// Time complexity: O(m), where m = `pattern.length()`
///
/// Example:
/// ```
/// let pi = prefix_function("ababa")
/// // pi == [0, 0, 1, 2, 3]
/// ```
pub fn prefix_function(pattern : String) -> Array[Int] {
  compute_failure(pattern)
}

///|
/// Search for all (possibly overlapping) occurrences of `pattern` in `text`
/// using the Knuth-Morris-Pratt algorithm.
///
/// The search runs in O(n) time after an O(m) preprocessing step, so the
/// total cost is O(n + m) regardless of the characters involved.  Each
/// character in `text` is examined at most a constant number of times; the
/// text index `i` never moves backward.
///
/// Parameters:
/// - `text`    - the string to search in (length n)
/// - `pattern` - the string to search for (length m)
///
/// Returns an `Array[Int]` of starting indices (0-based) at which `pattern`
/// begins in `text`.  The array is empty when there are no matches, when
/// `pattern` is empty, or when `pattern` is longer than `text`.
///
/// Time complexity: O(n + m)
/// Space complexity: O(m) for the failure table, O(k) for the result where k
/// is the number of matches
///
/// Example:
/// ```
/// // "ABAB" appears at positions 0, 10, and 15
/// let matches = kmp_search("ABABDABACDABABCABAB", "ABAB")
/// // matches == [0, 10, 15]
///
/// // Overlapping matches are included
/// let overlapping = kmp_search("AAAA", "AA")
/// // overlapping == [0, 1, 2]
/// ```
pub fn kmp_search(text : String, pattern : String) -> Array[Int] {
  let n = text.length()
  let m = pattern.length()
  let matches : Array[Int] = []
  if m == 0 || m > n {
    return matches
  }
  let fail = compute_failure(pattern)
  for i in 0..<n; j = 0 {
    let curr_j = for curr_j = j; curr_j > 0 && pattern[curr_j] != text[i]; {
      continue fail[curr_j - 1]
    } nobreak {
      curr_j
    }
    let curr_j = if pattern[curr_j] == text[i] { curr_j + 1 } else { curr_j }
    let next_j = if curr_j == m {
      matches.push(i - m + 1)
      fail[curr_j - 1]
    } else {
      curr_j
    }
    continue next_j
  }
  matches
}

///|
/// Return the index of the first occurrence of `pattern` in `text`, or `-1`
/// if the pattern does not appear.
///
/// This is a convenience wrapper around `kmp_search` that avoids allocating
/// the full match list when only the first match is needed.
///
/// Parameters:
/// - `text`    - the string to search in
/// - `pattern` - the string to search for
///
/// Returns the 0-based starting index of the first match, or `-1` if no
/// match exists.
///
/// Time complexity: O(n + m)
/// Space complexity: O(m)
///
/// Example:
/// ```
/// let idx = kmp_find_first("HELLO WORLD", "WORLD")
/// // idx == 6
///
/// let missing = kmp_find_first("HELLO WORLD", "XYZ")
/// // missing == -1
/// ```
pub fn kmp_find_first(text : String, pattern : String) -> Int {
  let matches = kmp_search(text, pattern)
  if matches.length() > 0 {
    matches[0]
  } else {
    -1
  }
}

///|
/// Count the total number of (possibly overlapping) occurrences of `pattern`
/// in `text`.
///
/// Parameters:
/// - `text`    - the string to search in
/// - `pattern` - the string to search for
///
/// Returns the number of times `pattern` appears in `text`, counting
/// overlapping occurrences.  Returns `0` when the pattern is empty or longer
/// than the text.
///
/// Time complexity: O(n + m)
/// Space complexity: O(m)
///
/// Example:
/// ```
/// // Three overlapping "AA" matches in "AAAA"
/// let count = kmp_count("AAAA", "AA")
/// // count == 3
///
/// let none = kmp_count("HELLO", "XYZ")
/// // none == 0
/// ```
pub fn kmp_count(text : String, pattern : String) -> Int {
  kmp_search(text, pattern).length()
}

// ============================================================================
// Z-FUNCTION
// ============================================================================

///|
/// Compute the Z-function (Z-array) for a string.
///
/// `z[i]` is the length of the longest substring starting at position `i`
/// that matches a prefix of `s`.  By convention `z[0]` equals `s.length()`.
///
/// The Z-function is maintained efficiently with a "Z-box" `[l, r]`: the
/// interval `[l, r)` is the rightmost window known to match `s[0..r-l)`.
/// When `i` falls inside the box, previously computed values are reused
/// before extending, giving the O(n) amortised bound.
///
/// Parameters:
/// - `s` - the input string (length n)
///
/// Returns an `Array[Int]` of length `n`, or an empty array when `s` is
/// empty.
///
/// Time complexity: O(n)
/// Space complexity: O(n)
///
/// Example:
/// ```
/// // "AABXAAB":
/// //  z[0] = 7  (full string)
/// //  z[1] = 1  ("A" matches prefix "A")
/// //  z[4] = 3  ("AAB" matches prefix "AAB")
/// let z = compute_z_function("AABXAAB")
/// // z == [7, 1, 0, 0, 3, 1, 0]
/// ```
pub fn compute_z_function(s : String) -> Array[Int] {
  let n = s.length()
  if n == 0 {
    return []
  }
  let z = Array::make(n, 0)
  z[0] = n
  for i in 1..<n; l = 0, r = 0 {
    let z_i = if i < r {
      if z[i - l] < r - i {
        z[i - l]
      } else {
        r - i
      }
    } else {
      0
    }
    let z_i = for z_i = z_i; i + z_i < n && s[z_i] == s[i + z_i]; {
      continue z_i + 1
    } nobreak {
      z_i
    }
    z[i] = z_i
    if i + z_i > r {
      continue i, i + z_i
    } else {
      continue l, r
    }
  }
  z
}

///|
/// Find all occurrences of `pattern` in `text` using the Z-function.
///
/// Builds the concatenated string `pattern + "$" + text`, computes its
/// Z-array, and reports every position where the Z-value equals
/// `pattern.length()`.  The sentinel character `"$"` prevents a prefix
/// match from bridging the boundary between pattern and text.
///
/// Parameters:
/// - `text`    - the string to search in (length n)
/// - `pattern` - the string to search for (length m)
///
/// Returns an `Array[Int]` of 0-based starting indices in `text` where
/// `pattern` begins.  Returns an empty array when `pattern` is empty or
/// longer than `text`.
///
/// Time complexity: O(n + m)
/// Space complexity: O(n + m) for the concatenated string and Z-array
///
/// Example:
/// ```
/// let matches = z_search("ABABDABACDABABCABAB", "ABAB")
/// // matches == [0, 10, 15]
/// ```
pub fn z_search(text : String, pattern : String) -> Array[Int] {
  let n = text.length()
  let m = pattern.length()
  let matches : Array[Int] = []
  if m == 0 || m > n {
    return matches
  }
  let concat = pattern.to_string() + "$" + text.to_string()
  let z = compute_z_function(concat)
  let offset = m + 1
  for i in offset..<concat.length() {
    if z[i] == m {
      matches.push(i - offset)
    }
  }
  matches
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "failure function basic" {
  let fail = compute_failure("ABAB")
  debug_inspect(fail.length(), content="4")
  debug_inspect(fail[0], content="0")
  debug_inspect(fail[1], content="0")
  debug_inspect(fail[2], content="1")
  debug_inspect(fail[3], content="2")
}

///|
test "failure function all same" {
  let fail = compute_failure("AAAA")
  debug_inspect(fail[0], content="0")
  debug_inspect(fail[1], content="1")
  debug_inspect(fail[2], content="2")
  debug_inspect(fail[3], content="3")
}

///|
test "failure function complex" {
  let fail = compute_failure("ABACABA")
  debug_inspect(fail[0], content="0")
  debug_inspect(fail[1], content="0")
  debug_inspect(fail[2], content="1")
  debug_inspect(fail[3], content="0")
  debug_inspect(fail[4], content="1")
  debug_inspect(fail[5], content="2")
  debug_inspect(fail[6], content="3")
}

///|
test "prefix function alias" {
  let pi = prefix_function("ababa")
  debug_inspect(pi, content="[0, 0, 1, 2, 3]")
}

///|
test "kmp search basic" {
  let matches = kmp_search("ABABDABACDABABCABAB", "ABAB")
  debug_inspect(matches.length(), content="3")
  debug_inspect(matches[0], content="0")
  debug_inspect(matches[1], content="10")
  debug_inspect(matches[2], content="15")
}

///|
test "kmp search no match" {
  let matches = kmp_search("ABABAB", "XYZ")
  debug_inspect(matches.length(), content="0")
}

///|
test "kmp search single char" {
  let matches = kmp_search("AAAAA", "A")
  debug_inspect(matches.length(), content="5")
}

///|
test "kmp search overlapping" {
  let matches = kmp_search("AAAA", "AA")
  debug_inspect(matches.length(), content="3")
}

///|
test "kmp find first" {
  debug_inspect(kmp_find_first("HELLO WORLD", "WORLD"), content="6")
  debug_inspect(kmp_find_first("HELLO WORLD", "XYZ"), content="-1")
}

///|
test "z function basic" {
  let z = compute_z_function("AABXAAB")
  debug_inspect(z[0], content="7")
  debug_inspect(z[1], content="1")
  debug_inspect(z[4], content="3")
}

///|
test "z function all same" {
  let z = compute_z_function("AAAA")
  debug_inspect(z[0], content="4")
  debug_inspect(z[1], content="3")
  debug_inspect(z[2], content="2")
  debug_inspect(z[3], content="1")
}

///|
test "z search basic" {
  let matches = z_search("ABABDABACDABABCABAB", "ABAB")
  debug_inspect(matches.length(), content="3")
}

///|
test "empty pattern" {
  debug_inspect(kmp_search("HELLO", "").length(), content="0")
  debug_inspect(z_search("HELLO", "").length(), content="0")
}

///|
test "empty string" {
  debug_inspect(compute_failure("").length(), content="0")
  debug_inspect(compute_z_function("").length(), content="0")
}
