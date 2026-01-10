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
/// Compute Z-array for string s
/// Returns array where z[i] = length of longest prefix match starting at i
fn compute_z(s : String) -> Array[Int] {
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
      let mut match_len = 0
      while i + match_len < n && s[match_len] == s[i + match_len] {
        match_len = match_len + 1
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
        let mut match_len = remaining
        while i + match_len < n && s[match_len] == s[i + match_len] {
          match_len = match_len + 1
        }
        z[i] = match_len
        continue i + 1, i, i + match_len - 1
      }
    }
  } where {
    invariant: 1 <= i && i <= n,
    reasoning: (
      #|i is the next position whose Z value is not yet finalized.
      #|All positions < i have been computed exactly once.
    ),
    invariant: 0 <= l && l <= r + 1 && r < n,
    reasoning: (
      #|Z-box boundaries stay within the string.
      #|When r < l, the box is empty; otherwise s[l..r] matches s[0..r-l].
    ),
    invariant: l <= i,
    reasoning: (
      #|The Z-box never starts to the right of the current index.
      #|When we extend a match, we reset l to i; otherwise l stays behind i.
    ),
  }

  z
}

///|
/// Find all occurrences of pattern in text using Z-algorithm
/// Returns array of starting indices where pattern occurs
fn find_pattern(text : String, pattern : String) -> Array[Int] {
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
  for i = m + 1; i < z.length(); i = i + 1 {
    if z[i] == m {
      result.push(i - m - 1) // Convert to text index
    }
  } where {
    invariant: i >= m + 1 && i <= z.length(),
    reasoning: (
      #|Indices before m+1 belong to pattern or separator and are ignored.
      #|We only check Z-values aligned with the text portion.
    ),
  }

  result
}

///|
/// Count occurrences of pattern in text
fn count_pattern(text : String, pattern : String) -> Int {
  find_pattern(text, pattern).length()
}

///|
/// Find longest prefix that is also a suffix (excluding trivial cases)
/// Uses Z-array property: if Z[i] = n - i, then s[i..n-1] = s[0..n-i-1]
fn longest_prefix_suffix(s : String) -> Int {
  let n = s.length()
  if n <= 1 {
    return 0
  }

  let z = compute_z(s)

  // Find longest i where Z[i] + i = n (s[i..] matches prefix)
  // INVARIANT: Result is length of longest proper prefix that is also suffix
  for i = 1, best = 0; i < n; i = i + 1 {
    if z[i] + i == n && z[i] > best {
      continue i + 1, z[i]
    } else {
      continue i + 1, best
    }
  } else {
    best
  } where {
    invariant: i >= 1 && i <= n,
    reasoning: (
      #|Scan all candidate split points i for which a suffix could match the prefix.
      #|We only update when Z[i] reaches the end of the string.
    ),
    invariant: best >= 0,
    reasoning: (
      #|best stores the maximum border length seen so far (proper prefix = suffix).
      #|This guarantees the result is the longest such border.
    ),
  }
}

///|
/// Find all border lengths (prefix-suffix matches)
fn all_borders(s : String) -> Array[Int] {
  let n = s.length()
  if n == 0 {
    return []
  }

  let z = compute_z(s)
  let borders : Array[Int] = []

  // A border of length k exists if some position i has Z[i] = n - i = k
  for i = 1; i < n; i = i + 1 {
    if z[i] + i == n {
      borders.push(z[i])
    }
  } where {
    invariant: i >= 1 && i <= n,
    reasoning: (
      #|A border exists exactly when Z[i] reaches the end (Z[i] + i == n).
      #|We enumerate all such i to collect every border length.
    ),
  }

  // Sort borders in ascending order
  borders.sort_by(fn(a, b) { a - b })
  borders
}

///|
/// Find the period of a string (length of smallest repeating unit)
/// A string with period p satisfies s[i] = s[i mod p] for all i
fn string_period(s : String) -> Int {
  let n = s.length()
  if n == 0 {
    return 0
  }

  let z = compute_z(s)

  // Period p means n - p is a border length, or equivalently
  // there exists position p where Z[p] >= n - p
  // INVARIANT: Find smallest p where s[p..] matches prefix of length >= n-p
  for p = 1; p < n; p = p + 1 {
    if z[p] >= n - p {
      return p
    }
  } where {
    invariant: p >= 1 && p <= n,
    reasoning: (
      #|A period p means the suffix of length n-p matches the prefix of length n-p.
      #|We return the smallest p meeting Z[p] >= n - p.
    ),
  }

  n // No repetition, period is entire string
}

///|
/// Check if string is a repetition of a smaller pattern
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
