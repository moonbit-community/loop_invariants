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
/// Compute the failure function (LPS array) for a pattern
/// fail[i] = length of longest proper prefix of pattern[0..i+1) that is also a suffix
pub fn compute_failure(pattern : String) -> Array[Int] {
  let m = pattern.length()
  if m == 0 {
    return []
  }
  let fail = Array::make(m, 0)
  for i = 1, k = 0; i < m; {
    let mut curr_k = k
    while curr_k > 0 && pattern[curr_k] != pattern[i] {
      curr_k = fail[curr_k - 1]
    }
    if pattern[curr_k] == pattern[i] {
      curr_k = curr_k + 1
    }
    fail[i] = curr_k
    continue i + 1, curr_k
  } where {
    invariant: i >= 1 && i <= m,
    reasoning: (
      #|INVARIANT (failure function):
      #|fail[0..i) is correct; k is the length of the longest border for
      #|pattern[0..i).
      #|MAINTENANCE:
      #|Try to extend the border with pattern[i]; on mismatch, fall back to the
      #|next candidate border via fail[k-1].
      #|TERMINATION:
      #|At i = m, fail stores the longest proper prefix that is also a suffix
      #|for each prefix of the pattern.
    ),
  }
  fail
}

///|
/// Find all occurrences of pattern in text using KMP algorithm
pub fn kmp_search(text : String, pattern : String) -> Array[Int] {
  let n = text.length()
  let m = pattern.length()
  let matches : Array[Int] = []
  if m == 0 || m > n {
    return matches
  }
  let fail = compute_failure(pattern)
  for i = 0, j = 0; i < n; {
    let mut curr_j = j
    while curr_j > 0 && pattern[curr_j] != text[i] {
      curr_j = fail[curr_j - 1]
    }
    if pattern[curr_j] == text[i] {
      curr_j = curr_j + 1
    }
    if curr_j == m {
      matches.push(i - m + 1)
      curr_j = fail[curr_j - 1]
    }
    continue i + 1, curr_j
  } where {
    invariant: i >= 0 && i <= n && j >= 0 && j <= m,
    reasoning: (
      #|INVARIANT (KMP scan):
      #|pattern[0..j) matches text[i-j..i), so j is the current match length.
      #|MAINTENANCE:
      #|On match, increment j; on mismatch, fall back using fail[j-1] to the
      #|next viable border without rechecking characters.
      #|TERMINATION:
      #|When i reaches n, all matches are reported; the scan is linear time.
    ),
  }
  matches
}

///|
pub fn kmp_find_first(text : String, pattern : String) -> Int {
  let matches = kmp_search(text, pattern)
  if matches.length() > 0 {
    matches[0]
  } else {
    -1
  }
}

///|
pub fn kmp_count(text : String, pattern : String) -> Int {
  kmp_search(text, pattern).length()
}

// ============================================================================
// Z-FUNCTION
// ============================================================================

///|
/// Compute Z-function for a string
/// z[i] = length of longest substring starting at i that matches prefix
pub fn compute_z_function(s : String) -> Array[Int] {
  let n = s.length()
  if n == 0 {
    return []
  }
  let z = Array::make(n, 0)
  z[0] = n
  for i = 1, l = 0, r = 0; i < n; {
    let mut curr_l = l
    let mut curr_r = r
    let mut z_i = 0
    if i < curr_r {
      z_i = if z[i - curr_l] < curr_r - i { z[i - curr_l] } else { curr_r - i }
    }
    while i + z_i < n && s[z_i] == s[i + z_i] {
      z_i = z_i + 1
    }
    z[i] = z_i
    if i + z_i > curr_r {
      curr_l = i
      curr_r = i + z_i
    }
    continue i + 1, curr_l, curr_r
  } where {
    invariant: i >= 1 && i <= n && l <= r && r <= n,
    reasoning: (
      #|INVARIANT (Z-function):
      #|For all positions < i, z is correct, and [l, r) is the current Z-box.
      #|MAINTENANCE:
      #|If i < r, initialize z[i] from the mirror; then extend by comparisons.
      #|Update [l, r) when a longer match is found.
      #|TERMINATION:
      #|At i = n, all z-values are computed in linear time.
    ),
  }
  z
}

///|
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
  for i = offset; i < concat.length(); i = i + 1 {
    if z[i] == m {
      matches.push(i - offset)
    }
  } where {
    invariant: i >= offset && i <= concat.length(),
    reasoning: (
      #|Scan Z-values after the delimiter; each i with z[i] == m marks a match.
    ),
  }
  matches
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "failure function basic" {
  let fail = compute_failure("ABAB")
  inspect(fail.length(), content="4")
  inspect(fail[0], content="0")
  inspect(fail[1], content="0")
  inspect(fail[2], content="1")
  inspect(fail[3], content="2")
}

///|
test "failure function all same" {
  let fail = compute_failure("AAAA")
  inspect(fail[0], content="0")
  inspect(fail[1], content="1")
  inspect(fail[2], content="2")
  inspect(fail[3], content="3")
}

///|
test "failure function complex" {
  let fail = compute_failure("ABACABA")
  inspect(fail[0], content="0")
  inspect(fail[1], content="0")
  inspect(fail[2], content="1")
  inspect(fail[3], content="0")
  inspect(fail[4], content="1")
  inspect(fail[5], content="2")
  inspect(fail[6], content="3")
}

///|
test "kmp search basic" {
  let matches = kmp_search("ABABDABACDABABCABAB", "ABAB")
  inspect(matches.length(), content="3")
  inspect(matches[0], content="0")
  inspect(matches[1], content="10")
  inspect(matches[2], content="15")
}

///|
test "kmp search no match" {
  let matches = kmp_search("ABABAB", "XYZ")
  inspect(matches.length(), content="0")
}

///|
test "kmp search single char" {
  let matches = kmp_search("AAAAA", "A")
  inspect(matches.length(), content="5")
}

///|
test "kmp search overlapping" {
  let matches = kmp_search("AAAA", "AA")
  inspect(matches.length(), content="3")
}

///|
test "kmp find first" {
  inspect(kmp_find_first("HELLO WORLD", "WORLD"), content="6")
  inspect(kmp_find_first("HELLO WORLD", "XYZ"), content="-1")
}

///|
test "z function basic" {
  let z = compute_z_function("AABXAAB")
  inspect(z[0], content="7")
  inspect(z[1], content="1")
  inspect(z[4], content="3")
}

///|
test "z function all same" {
  let z = compute_z_function("AAAA")
  inspect(z[0], content="4")
  inspect(z[1], content="3")
  inspect(z[2], content="2")
  inspect(z[3], content="1")
}

///|
test "z search basic" {
  let matches = z_search("ABABDABACDABABCABAB", "ABAB")
  inspect(matches.length(), content="3")
}

///|
test "empty pattern" {
  inspect(kmp_search("HELLO", "").length(), content="0")
  inspect(z_search("HELLO", "").length(), content="0")
}

///|
test "empty string" {
  inspect(compute_failure("").length(), content="0")
  inspect(compute_z_function("").length(), content="0")
}
