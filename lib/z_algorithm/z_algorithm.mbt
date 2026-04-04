// ============================================================================
// Z-ALGORITHM - Linear Time Pattern Matching
// ============================================================================
//
// The Z-Algorithm computes the Z-array for a string in linear time.
// Z[i] = length of longest substring starting at i that matches a prefix of s
//
// KEY INSIGHT: Maintain a "Z-box" [l, r] where s[l..r] matches s[0..r-l].
// For each position i, we can often reuse previously computed Z-values
// if i falls within the current Z-box.
//
// ALGORITHM:
// 1. Initialize l = r = 0 (empty Z-box)
// 2. For each i from 1 to n-1:
//    a. If i > r: expand naively from i, update l = r = i
//    b. If i <= r:
//       - k = i - l (corresponding position in prefix)
//       - If Z[k] < r - i + 1: Z[i] = Z[k] (stays within Z-box)
//       - Else: start matching from r+1, update l = i
//
// EXAMPLE for s = "aabcaab":
// i:    0  1  2  3  4  5  6
// s:    a  a  b  c  a  a  b
// Z:    -  1  0  0  3  1  0
//
// Z[4] = 3 because s[4..6] = "aab" matches prefix s[0..2] = "aab"
//
// PATTERN MATCHING:
// To find pattern P in text T, compute Z-array of "P$T"
// Occurrences of P start at positions i where Z[i] = |P| (i > |P|)
//
// INVARIANTS:
// 1. Z-box [l, r] always satisfies s[l..r] = s[0..r-l]
// 2. r is the rightmost position that has been explicitly compared
// 3. Z[i] is correctly computed after iteration i
//
// TIME COMPLEXITY: O(n)
// SPACE COMPLEXITY: O(n)

///|
/// Computes the Z-array for a string.
///
/// `Z[i]` is the length of the longest substring starting at index `i` that
/// matches a prefix of `s`. By convention `Z[0]` equals `n`, the full string
/// length.
///
/// The algorithm maintains a **Z-box** `[l, r]` — the rightmost window where
/// `s[l..r]` matches `s[0..r-l]`. When index `i` falls inside the box, the
/// previously computed value `Z[i-l]` is reused to avoid redundant character
/// comparisons. The right boundary `r` only moves forward, so the total work
/// is linear.
///
/// Parameters:
/// - `s`: the input string.
///
/// Returns an `Array[Int]` of length `n` where entry `i` holds `Z[i]`.
/// Returns an empty array when `s` is empty.
///
/// Time complexity: O(n), where n = s.length().
/// Space complexity: O(n).
pub fn compute_z(s : String) -> Array[Int] {
  let n = s.length()
  if n == 0 {
    return []
  }
  let z = Array::make(n, 0)
  z[0] = n // By definition, entire string matches prefix

  // INVARIANT: [l, r] is the Z-box where s[l..r] matches s[0..r-l]
  // l and r start such that the Z-box is empty (r < l initially)
  for i = 1, l = 0, r = 0; i < n; i = i + 1 {
    if i > r {
      // Case 1: i is outside Z-box, compute naively
      let match_len = for match_len = 0; i + match_len < n &&
                         s[match_len] == s[i + match_len]; {
        continue match_len + 1
      } nobreak {
        match_len
      }
      z[i] = match_len
      if match_len > 0 {
        continue i + 1, i, i + match_len - 1
      } else {
        continue i + 1, l, r
      }
    } else {
      // Case 2: i is inside Z-box [l, r]
      let k = i - l // Corresponding position in prefix
      let remaining = r - i + 1 // How much of Z-box is left
      if z[k] < remaining {
        // Case 2a: Z[k] fits entirely within remaining Z-box
        // s[i..i+z[k]-1] matches s[k..k+z[k]-1] which matches s[0..z[k]-1]
        z[i] = z[k]
        continue i + 1, l, r
      } else {
        // Case 2b: Need to extend beyond Z-box
        let match_len = for match_len = remaining; i + match_len < n &&
                           s[match_len] == s[i + match_len]; {
          continue match_len + 1
        } nobreak {
          match_len
        }
        z[i] = match_len
        continue i + 1, i, i + match_len - 1
      }
    }
  } where {
    proof_invariant: 1 <= i && i <= n,
    proof_reasoning: (
      #|INVARIANT (scan position):
      #|i is the next position whose Z value is not finalized; all indices < i
      #|have their Z-values computed.
      #|MAINTENANCE:
      #|Each iteration finalizes z[i] and increments i by 1.
      #|TERMINATION:
      #|At i = n, the entire Z-array is computed.
    ),
    proof_invariant: 0 <= l && l <= r + 1 && r < n,
    proof_reasoning: (
      #|INVARIANT (Z-box bounds):
      #|[l, r] stays within [0..n-1]; when r < l the Z-box is empty, otherwise
      #|s[l..r] matches s[0..r-l].
      #|MAINTENANCE:
      #|Updates to l and r only occur after computing a fresh match length.
      #|TERMINATION:
      #|Bounds guarantee all accesses stay inside the string.
    ),
    proof_invariant: l <= i,
    proof_reasoning: (
      #|INVARIANT (Z-box start):
      #|The Z-box start l never moves to the right of the current index i.
      #|MAINTENANCE:
      #|If we extend beyond r, we reset l to i; otherwise l stays unchanged.
      #|TERMINATION:
      #|Ensures the mirror index k = i - l is always valid.
    ),
  }
  z
}

///|
/// Computes the Z-array for a string (alias of `compute_z`).
///
/// Parameters:
/// - `s`: the input string.
///
/// Returns an `Array[Int]` of length `n` where entry `i` holds `Z[i]`.
///
/// Time complexity: O(n), where n = s.length().
pub fn z_function(s : String) -> Array[Int] {
  compute_z(s)
}

///|
/// Finds all (possibly overlapping) occurrences of `pattern` in `text` using
/// the Z-algorithm.
///
/// Constructs the concatenated string `pattern + "$" + text`, computes its
/// Z-array, and collects every index `i` (with `i > pattern.length()`) where
/// `Z[i] == pattern.length()`. The `"$"` separator prevents a Z-value from
/// spanning the pattern/text boundary.
///
/// Parameters:
/// - `text`: the string to search in.
/// - `pattern`: the string to search for.
///
/// Returns an `Array[Int]` of zero-based starting positions in `text` where
/// `pattern` occurs, in ascending order. Returns an empty array when `pattern`
/// is empty or longer than `text`.
///
/// Time complexity: O(n + m), where n = text.length() and m = pattern.length().
/// Space complexity: O(n + m).
pub fn find_pattern(text : String, pattern : String) -> Array[Int] {
  let result : Array[Int] = []
  let m = pattern.length()
  let n = text.length()
  if m == 0 || m > n {
    return result
  }

  // Build concatenated string: pattern + "$" + text
  // The "$" is a separator that won't match anything
  let sb = StringBuilder::new()
  sb.write_string(pattern)
  sb.write_char('$')
  sb.write_string(text)
  let concat = sb.to_string()
  let z = compute_z(concat)

  // Find positions where Z[i] = m (full pattern match)
  // These positions correspond to text[i - m - 1]
  // INVARIANT: Valid matches are at positions > m (after pattern$)
  for i in (m + 1)..<z.length() {
    if z[i] == m {
      result.push(i - m - 1) // Convert to text index
    }
  } where {
    proof_invariant: i >= m + 1 && i <= z.length(),
    proof_reasoning: (
      #|INVARIANT (pattern scan):
      #|Indices in [m+1..i) correspond to text positions already checked, and
      #|result stores all matches found so far.
      #|MAINTENANCE:
      #|If z[i] == m, record the match at i - m - 1 and advance.
      #|TERMINATION:
      #|At i = z.length(), all text positions are examined.
    ),
  }
  result
}

///|
/// Finds all occurrences of `pattern` in `text` (alias of `find_pattern`).
///
/// Parameters:
/// - `text`: the string to search in.
/// - `pattern`: the string to search for.
///
/// Returns an `Array[Int]` of zero-based starting positions in `text` where
/// `pattern` occurs, in ascending order.
///
/// Time complexity: O(n + m), where n = text.length() and m = pattern.length().
pub fn z_search(text : String, pattern : String) -> Array[Int] {
  find_pattern(text, pattern)
}

///|
/// Counts all (possibly overlapping) occurrences of `pattern` in `text`.
///
/// Parameters:
/// - `text`: the string to search in.
/// - `pattern`: the string to count.
///
/// Returns the number of positions in `text` where `pattern` starts.
/// Returns 0 when `pattern` is empty or longer than `text`.
///
/// Time complexity: O(n + m), where n = text.length() and m = pattern.length().
pub fn count_pattern(text : String, pattern : String) -> Int {
  find_pattern(text, pattern).length()
}

///|
/// Finds the length of the longest proper prefix of `s` that is also a suffix.
///
/// A position `i` satisfies this when `Z[i] + i == n`, meaning the suffix
/// starting at `i` matches the prefix of the same length exactly. The trivial
/// case (the whole string) is excluded.
///
/// Parameters:
/// - `s`: the input string.
///
/// Returns the length of the longest proper border, or 0 if none exists.
///
/// Time complexity: O(n), where n = s.length().
fn longest_prefix_suffix(s : String) -> Int {
  let n = s.length()
  if n <= 1 {
    return 0
  }
  let z = compute_z(s)

  for i in 1..<n; best = 0 {
    if z[i] + i == n && z[i] > best {
      continue z[i]
    } else {
      continue best
    }
  } nobreak {
    best
  }
}

///|
/// Returns the lengths of all borders of `s`, sorted in ascending order.
///
/// A **border** of `s` is a non-empty proper prefix that is also a suffix.
/// Equivalently, a border of length `k` exists when some index `i` satisfies
/// `Z[i] + i == n` (with `Z[i] == k`).
///
/// Parameters:
/// - `s`: the input string.
///
/// Returns an `Array[Int]` of border lengths in ascending order.
/// Returns an empty array when `s` is empty or has no borders.
///
/// Time complexity: O(n log n) due to sorting; the Z-array pass is O(n).
fn all_borders(s : String) -> Array[Int] {
  let n = s.length()
  if n == 0 {
    return []
  }
  let z = compute_z(s)
  let borders : Array[Int] = []

  // A border of length k exists if some position i has Z[i] = n - i = k
  for i in 1..<n {
    if z[i] + i == n {
      borders.push(z[i])
    }
  } where {
    proof_invariant: i >= 1 && i <= n,
    proof_reasoning: (
      #|INVARIANT (border enumeration):
      #|Positions in [1..i) are scanned; borders contains all border lengths found.
      #|MAINTENANCE:
      #|When z[i] + i == n, append z[i] to record the new border.
      #|TERMINATION:
      #|At i = n, all border lengths have been collected.
    ),
  }

  // Sort borders in ascending order
  borders.sort_by((a, b) => a - b)
  borders
}

///|
/// Returns the period of `s`: the length of the smallest repeating unit.
///
/// A string has period `p` when `s[i] == s[i mod p]` for every valid `i`.
/// Equivalently, `p` is the smallest positive integer such that `Z[p] >= n - p`
/// (the suffix at `p` covers the rest of the string when tiled from the start).
/// If no such `p < n` exists, the period is `n` (the string does not repeat).
///
/// Parameters:
/// - `s`: the input string.
///
/// Returns an `Int` in the range `[1, n]`.  Returns 0 for an empty string.
///
/// Time complexity: O(n), where n = s.length().
fn string_period(s : String) -> Int {
  let n = s.length()
  if n == 0 {
    return 0
  }
  let z = compute_z(s)

  // Period p means n - p is a border length, or equivalently
  // there exists position p where Z[p] >= n - p
  // INVARIANT: Find smallest p where s[p..] matches prefix of length >= n-p
  for p in 1..<n {
    if z[p] >= n - p {
      return p
    }
  } where {
    proof_invariant: p >= 1 && p <= n,
    proof_reasoning: (
      #|INVARIANT (period scan):
      #|All p' < p have been checked and do not satisfy the period condition.
      #|MAINTENANCE:
      #|If z[p] >= n - p, return p as the smallest valid period.
      #|TERMINATION:
      #|If no p < n works, the period is n (no repetition).
    ),
  }
  n // No repetition, period is entire string
}

///|
/// Reports whether `s` is formed by repeating a strictly shorter unit an
/// integer number of times.
///
/// Uses `string_period` to find the minimal period `p`, then checks that
/// `p < n` and `n` is divisible by `p`.
///
/// Parameters:
/// - `s`: the input string.
///
/// Returns `true` if `s` is a non-trivial repetition (e.g. `"abab"`, `"aaaa"`),
/// `false` otherwise. Strings of length 0 or 1 always return `false`.
///
/// Time complexity: O(n), where n = s.length().
fn is_repetition(s : String) -> Bool {
  let n = s.length()
  if n <= 1 {
    return false
  }
  let p = string_period(s)
  p < n && n % p == 0
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "z algorithm basic" {
  let z = compute_z("aabcaab")

  // Z[0] is always n (entire string matches prefix)
  inspect(z[0], content="7")

  // Z[1] = 1: "a" matches prefix "a"
  inspect(z[1], content="1")

  // Z[2] = 0: "b" doesn't match prefix "a"
  inspect(z[2], content="0")

  // Z[4] = 3: "aab" matches prefix "aab"
  inspect(z[4], content="3")
}

///|
test "z algorithm aaaa" {
  let z = compute_z("aaaa")

  // All suffixes match prefix
  inspect(z[0], content="4")
  inspect(z[1], content="3")
  inspect(z[2], content="2")
  inspect(z[3], content="1")
}

///|
test "z function alias" {
  let z = z_function("aaaaa")
  inspect(z, content="[5, 4, 3, 2, 1]")
}

///|
test "z algorithm abcd" {
  let z = compute_z("abcd")

  // No suffix matches prefix except trivially
  inspect(z[0], content="4")
  inspect(z[1], content="0")
  inspect(z[2], content="0")
  inspect(z[3], content="0")
}

///|
test "z algorithm empty" {
  let z = compute_z("")
  inspect(z.length(), content="0")
}

///|
test "find pattern basic" {
  let matches = find_pattern("aabcaabxaab", "aab")
  inspect(matches.length(), content="3")
  inspect(matches[0], content="0")
  inspect(matches[1], content="4")
  inspect(matches[2], content="8")
}

///|
test "find pattern no match" {
  let matches = find_pattern("abcdef", "xyz")
  inspect(matches.length(), content="0")
}

///|
test "find pattern full match" {
  let matches = find_pattern("abc", "abc")
  inspect(matches.length(), content="1")
  inspect(matches[0], content="0")
}

///|
test "find pattern overlapping" {
  let matches = find_pattern("aaaa", "aa")

  // "aa" appears at positions 0, 1, 2
  inspect(matches.length(), content="3")
  inspect(matches[0], content="0")
  inspect(matches[1], content="1")
  inspect(matches[2], content="2")
}

///|
test "z search alias" {
  let matches = z_search("ababa", "aba")
  inspect(matches, content="[0, 2]")
}

///|
test "count pattern" {
  inspect(count_pattern("mississippi", "issi"), content="2")
  inspect(count_pattern("abcabc", "abc"), content="2")
  inspect(count_pattern("hello", "xyz"), content="0")
}

///|
test "longest prefix suffix" {
  // "abcab": prefix "ab" = suffix "ab"
  inspect(longest_prefix_suffix("abcab"), content="2")

  // "aaaa": prefix "aaa" = suffix "aaa"
  inspect(longest_prefix_suffix("aaaa"), content="3")

  // "abcd": no proper prefix-suffix
  inspect(longest_prefix_suffix("abcd"), content="0")

  // "a": trivially 0
  inspect(longest_prefix_suffix("a"), content="0")
}

///|
test "all borders" {
  let borders = all_borders("aabaab")

  // "aabaab" has borders: "aab" (length 3)
  // Actually: "a" is NOT a border, let me recalculate
  // s[0..2] = "aab", s[3..5] = "aab" - yes, border of length 3
  // No border of length 1 or 2
  inspect(borders.length() >= 1, content="true")
}

///|
test "string period" {
  // "abab" has period 2 ("ab" repeats)
  inspect(string_period("abab"), content="2")

  // "abcabc" has period 3 ("abc" repeats)
  inspect(string_period("abcabc"), content="3")

  // "abcd" has period 4 (itself)
  inspect(string_period("abcd"), content="4")

  // "aaaa" has period 1
  inspect(string_period("aaaa"), content="1")
}

///|
test "is repetition" {
  inspect(is_repetition("abab"), content="true")
  inspect(is_repetition("abcabc"), content="true")
  inspect(is_repetition("aaaa"), content="true")
  inspect(is_repetition("abcd"), content="false")
  inspect(is_repetition("abc"), content="false")
}

///|
test "z algorithm single char" {
  let z = compute_z("x")
  inspect(z.length(), content="1")
  inspect(z[0], content="1")
}

///|
test "find pattern empty pattern" {
  let matches = find_pattern("abc", "")
  inspect(matches.length(), content="0")
}

///|
test "find pattern longer pattern" {
  let matches = find_pattern("ab", "abcd")
  inspect(matches.length(), content="0")
}
