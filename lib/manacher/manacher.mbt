// ============================================================================
// MANACHER'S ALGORITHM - Linear Time Longest Palindromic Substring
// ============================================================================
//
// Manacher's Algorithm finds the longest palindromic substring in O(n) time.
// It can also compute the palindromic radius at every position efficiently.
//
// KEY INSIGHT: Transform string by adding separators between characters:
// "abc" -> "#a#b#c#"
// This makes all palindromes odd-length in the transformed string.
// Then use a clever technique similar to Z-algorithm to reuse previously
// computed palindrome radii.
//
// ALGORITHM:
// 1. Transform string: insert '#' between characters and at ends
// 2. Maintain center c and right boundary r of rightmost-reaching palindrome
// 3. For each position i:
//    a. If i < r, use mirror position j = 2*c - i to initialize p[i]
//    b. Try to expand palindrome centered at i
//    c. If palindrome reaches past r, update c = i, r = i + p[i]
//
// EXAMPLE for s = "abba":
// Transformed: "#a#b#b#a#"
// Position:     0 1 2 3 4 5 6 7 8
// Char:         # a # b # b # a #
// Radius p:     0 1 0 1 4 1 0 1 0
//
// Longest palindrome has radius 4 at position 4, corresponding to "abba"
//
// INVARIANTS:
// 1. c is center of palindrome with rightmost boundary r
// 2. r = c + p[c] is the rightmost position any palindrome reaches
// 3. For i < r, p[i] >= min(p[2*c - i], r - i) from symmetry
//
// TIME COMPLEXITY: O(n)
// SPACE COMPLEXITY: O(n)

///|
/// Compute palindromic radius array using Manacher's algorithm
/// Returns (transformed_string, radius_array) where radius[i] is the
/// radius of palindrome centered at position i in transformed string
fn manacher(s : String) -> (Array[Int], Array[Int]) {
  let n = s.length()

  // Transform string: "abc" -> "#a#b#c#"
  // Length becomes 2*n + 1
  let transformed : Array[Int] = []
  transformed.push(35) // '#' = 35 in ASCII

  for i = 0; i < n; i = i + 1 {
    transformed.push(s[i].to_int())
    transformed.push(35)
  }

  let m = transformed.length()
  let p = Array::make(m, 0) // Palindrome radius at each position

  // c = center of rightmost palindrome, r = right boundary
  // INVARIANT: r = c + p[c] is rightmost position any palindrome reaches
  for i = 1, c = 0, r = 0; i < m; i = i + 1 {
    if i < r {
      // Mirror position j = 2*c - i
      let j = 2 * c - i
      // p[i] is at least min(p[j], r - i) from symmetry
      let mirror_radius = if p[j] < r - i { p[j] } else { r - i }
      p[i] = mirror_radius
    }

    // Try to expand palindrome centered at i
    // INVARIANT: p[i] is current known radius, try to extend
    while i - p[i] - 1 >= 0 &&
          i + p[i] + 1 < m &&
          transformed[i - p[i] - 1] == transformed[i + p[i] + 1] {
      p[i] = p[i] + 1
    }

    // Update c and r if palindrome reaches further right
    if i + p[i] > r {
      continue i + 1, i, i + p[i]
    } else {
      continue i + 1, c, r
    }
  }

  (transformed, p)
}

///|
/// Find the longest palindromic substring
/// Returns (start_index, length) in original string
fn longest_palindrome(s : String) -> (Int, Int) {
  let n = s.length()
  if n == 0 {
    return (0, 0)
  }

  let (_, p) = manacher(s)

  // Find position with maximum radius
  // INVARIANT: max_pos has largest p[i]
  let (max_pos, max_radius) = for i = 0, max_pos = 0, max_radius = 0; i <
    p.length(); i = i + 1 {
    if p[i] > max_radius {
      continue i + 1, i, p[i]
    } else {
      continue i + 1, max_pos, max_radius
    }
  } else {
    (max_pos, max_radius)
  }

  // Convert back to original string indices
  // In transformed string "#a#b#c#", position i corresponds to:
  // - Original index: (i - 1) / 2 (for character positions)
  // - Radius p[i] in transformed = length in original
  let start = (max_pos - max_radius) / 2
  let length = max_radius

  (start, length)
}

///|
/// Get the longest palindromic substring as a string
fn longest_palindrome_string(s : String) -> String {
  let (start, length) = longest_palindrome(s)
  if length == 0 {
    return ""
  }
  (try? s[start:start + length]).or("").to_string()
}

///|
/// Check if entire string is a palindrome
fn is_palindrome(s : String) -> Bool {
  let n = s.length()
  if n == 0 {
    return true
  }

  let (start, length) = longest_palindrome(s)
  length == n && start == 0
}

///|
/// Count all palindromic substrings (including single characters)
fn count_palindromes(s : String) -> Int {
  let n = s.length()
  if n == 0 {
    return 0
  }

  let (_, p) = manacher(s)

  // Each position contributes (p[i] + 1) / 2 palindromes centered there
  // because radius p[i] in transformed string means floor((p[i]+1)/2)
  // palindromes of different lengths in original string
  for i = 0, count = 0; i < p.length(); i = i + 1 {
    continue i + 1, count + (p[i] + 1) / 2
  } else {
    count
  }
}

///|
/// Get all palindromic substrings (with their positions)
/// Returns array of (start, length) pairs
fn all_palindromes(s : String) -> Array[(Int, Int)] {
  let n = s.length()
  let result : Array[(Int, Int)] = []

  if n == 0 {
    return result
  }

  let (_, p) = manacher(s)

  // For each center, enumerate all palindromes of increasing length
  for i = 0; i < p.length(); i = i + 1 {
    // Position i in transformed string
    // For odd-length original palindromes (center on character)
    // and even-length (center between characters)
    for r = 1; r <= p[i]; r = r + 1 {
      // Check if this radius corresponds to valid palindrome
      let start = (i - r) / 2
      let length = r
      if (i - r) % 2 == 0 && length > 0 {
        result.push((start, length))
      }
    }
    // Also include single characters if centered on them
    if i % 2 == 1 {
      // Odd position = character in original
      result.push(((i - 1) / 2, 1))
    }
  }

  result
}

///|
/// Find longest palindrome that is also a prefix
fn longest_palindromic_prefix(s : String) -> Int {
  let n = s.length()
  if n == 0 {
    return 0
  }

  let (_, p) = manacher(s)

  // Check palindromes that start at position 0
  // In transformed string, position 1 is first character
  // A palindrome starting at 0 is centered somewhere and includes position 1
  // INVARIANT: Find largest length where substring [0, len) is palindrome
  for i = 0, best = 1; i < p.length(); i = i + 1 {
    // Check if palindrome centered at i reaches position 1 (first char)
    // and starts at or before position 0
    let left_bound = i - p[i]
    let right_bound = i + p[i]
    if left_bound <= 1 {
      // This palindrome includes the start
      // Length in original string
      let end_in_original = right_bound / 2
      if end_in_original > best {
        continue i + 1, end_in_original
      } else {
        continue i + 1, best
      }
    } else {
      continue i + 1, best
    }
  } else {
    best
  }
}

///|
/// Find longest palindrome that is also a suffix
fn longest_palindromic_suffix(s : String) -> Int {
  let n = s.length()
  if n == 0 {
    return 0
  }

  let (_, p) = manacher(s)
  let m = p.length()
  let last_pos = m - 2 // Position of last character in transformed string

  // Find palindrome that includes the last character
  // INVARIANT: Find largest length where substring [n-len, n) is palindrome
  for i = 0, best = 1; i < m; i = i + 1 {
    let right_bound = i + p[i]
    if right_bound >= last_pos {
      // This palindrome includes the end
      let start_in_transformed = i - p[i]
      let start_in_original = start_in_transformed / 2
      let length = n - start_in_original
      if length > best {
        continue i + 1, length
      } else {
        continue i + 1, best
      }
    } else {
      continue i + 1, best
    }
  } else {
    best
  }
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "manacher basic" {
  let (start, length) = longest_palindrome("babad")

  // Either "bab" or "aba" is valid
  inspect(length, content="3")
  inspect(start == 0 || start == 1, content="true")
}

///|
test "manacher even palindrome" {
  let (start, length) = longest_palindrome("cbbd")

  inspect(start, content="1")
  inspect(length, content="2") // "bb"
}

///|
test "manacher abba" {
  let (start, length) = longest_palindrome("abba")

  inspect(start, content="0")
  inspect(length, content="4") // "abba"
}

///|
test "manacher single char" {
  let (start, length) = longest_palindrome("a")

  inspect(start, content="0")
  inspect(length, content="1")
}

///|
test "manacher empty" {
  let (start, length) = longest_palindrome("")

  inspect(start, content="0")
  inspect(length, content="0")
}

///|
test "manacher all same" {
  let (start, length) = longest_palindrome("aaaa")

  inspect(start, content="0")
  inspect(length, content="4")
}

///|
test "longest palindrome string" {
  inspect(longest_palindrome_string("babad") is ("bab" | "aba"), content="true")
  inspect(longest_palindrome_string("cbbd"), content="bb")
  inspect(longest_palindrome_string("a"), content="a")
}

///|
test "is palindrome" {
  inspect(is_palindrome("aba"), content="true")
  inspect(is_palindrome("abba"), content="true")
  inspect(is_palindrome("abc"), content="false")
  inspect(is_palindrome("a"), content="true")
  inspect(is_palindrome(""), content="true")
}

///|
test "count palindromes" {
  // "abc" has 3 single-char palindromes
  inspect(count_palindromes("abc"), content="3")

  // "aaa" has "a"(3) + "aa"(2) + "aaa"(1) = 6
  inspect(count_palindromes("aaa"), content="6")

  // "aba" has "a"(2) + "b"(1) + "aba"(1) = 4
  inspect(count_palindromes("aba"), content="4")
}

///|
test "longest palindromic prefix" {
  // "abacaba" - prefix "abacaba" is a palindrome
  inspect(longest_palindromic_prefix("abacaba"), content="7")

  // "abcd" - only "a" is palindrome prefix
  inspect(longest_palindromic_prefix("abcd"), content="1")

  // "aab" - "aa" is palindrome prefix
  inspect(longest_palindromic_prefix("aab"), content="2")
}

///|
test "longest palindromic suffix" {
  // "abacaba" - suffix "abacaba" is a palindrome
  inspect(longest_palindromic_suffix("abacaba"), content="7")

  // "dcba" - only "a" is palindrome suffix
  inspect(longest_palindromic_suffix("dcba"), content="1")
}

///|
test "manacher racecar" {
  let (start, length) = longest_palindrome("racecar")

  inspect(start, content="0")
  inspect(length, content="7") // "racecar" itself
}

///|
test "manacher banana" {
  let (start, length) = longest_palindrome("banana")

  // "anana" is the longest palindrome
  inspect(start, content="1")
  inspect(length, content="5")
}

///|
test "all palindromes count" {
  let pals = all_palindromes("aba")

  // Should include: "a" at 0, "b" at 1, "a" at 2, "aba" at 0
  inspect(pals.length() >= 4, content="true")
}
