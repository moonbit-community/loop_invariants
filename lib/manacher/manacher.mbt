// ============================================================================
// MANACHER'S ALGORITHM - Longest Palindromic Substring in O(n)
// ============================================================================
//
// Manacher's algorithm finds the longest palindromic substring and all
// palindrome radii in linear time O(n).
//
// KEY INSIGHT: When we're inside a known palindrome, we can use symmetry
// to avoid redundant comparisons.
//
// TRANSFORMATION:
// To handle both odd and even length palindromes uniformly, we insert
// separators: "abba" -> "#a#b#b#a#"
// Now every palindrome has odd length and a unique center.
//
// ALGORITHM:
// Maintain the rightmost palindrome boundary (center c, right edge r).
// For each position i:
// 1. If i < r, use mirror position (2*c - i) to initialize p[i]
// 2. Expand around i while characters match
// 3. If i + p[i] > r, update c and r
//
// WHY IT WORKS:
// - If i < r, then i is inside palindrome centered at c
// - Mirror position i' = 2*c - i has p[i'] already computed
// - If i' palindrome fits entirely inside c's palindrome, p[i] = p[i']
// - Otherwise, we can at least say p[i] >= r - i (up to boundary)
// - Expansion beyond r discovers new territory
//
// INVARIANTS:
// 1. r = c + p[c] is the rightmost boundary seen so far
// 2. For all j < i: p[j] is the palindrome radius at j
// 3. p[i] >= min(p[2*c - i], r - i) when i < r
//
// TIME COMPLEXITY: O(n) - each position expanded at most once past r
// SPACE COMPLEXITY: O(n)

///|
priv struct ManacherResult {
  radii : Array[Int] // Palindrome radii in transformed string
  original : String
  transformed : String
}

///|
/// Compute palindrome radii using Manacher's algorithm
fn manacher(s : String) -> ManacherResult {
  let n = s.length()
  if n == 0 {
    return { radii: [], original: s, transformed: "" }
  }

  // Transform string: "abc" -> "#a#b#c#"
  // Use UInt16 array since string indexing returns UInt16
  let t_len = 2 * n + 1
  let separator : UInt16 = '#'
  let t : Array[UInt16] = Array::make(t_len, separator)
  for i = 0; i < n; i = i + 1 {
    t[2 * i + 1] = s[i]
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: "I: t filled with '#'. M: Place s[i] at position 2*i+1, leaving separators at even positions. T: After i = n, t = ['#', s[0], '#', s[1], '#', ..., s[n-1], '#'], interleaving chars with separators.",
  }

  let transformed = t.iter().map(fn(c) { Char::from_int(c.to_int()).to_string() }).collect().join("")
  let p = Array::make(t_len, 0) // p[i] = radius of palindrome centered at i

  for i = 0, c = 0, r = 0; i < t_len; {
    let mut curr_c = c
    let mut curr_r = r

    // Use mirror property if inside known palindrome
    let mirror = 2 * curr_c - i
    if i < curr_r {
      p[i] = min(curr_r - i, if mirror >= 0 { p[mirror] } else { 0 })
    }

    // Expand around center i
    while i - p[i] - 1 >= 0 &&
          i + p[i] + 1 < t_len &&
          t[i - p[i] - 1] == t[i + p[i] + 1] {
      p[i] = p[i] + 1
    }

    // Update rightmost boundary
    if i + p[i] > curr_r {
      curr_c = i
      curr_r = i + p[i]
    }

    continue i + 1, curr_c, curr_r
  } where {
    invariant: i >= 0 && i <= t_len && c >= 0 && r >= 0 && r <= t_len,
    reasoning: "I: i=0, c=0, r=0; no palindromes computed. M: For position i, if i < r, use symmetry: p[i] >= min(p[mirror], r-i). Then expand greedily while chars match. If new right boundary i+p[i] > r, update c=i, r=i+p[i]. Key insight: r only increases, and each comparison that fails is at position > r, so it contributes to increasing r. Total comparisons O(n). T: After i = t_len, p[j] contains radius of longest palindrome centered at j.",
  }

  { radii: p, original: s, transformed }
}

///|
fn min(a : Int, b : Int) -> Int {
  if a < b { a } else { b }
}

///|
fn max(a : Int, b : Int) -> Int {
  if a > b { a } else { b }
}

///|
/// Get the longest palindromic substring
fn ManacherResult::longest_palindrome(self : ManacherResult) -> String {
  if self.radii.length() == 0 {
    return ""
  }

  let mut max_len = 0
  let mut max_center = 0

  for i = 0; i < self.radii.length(); i = i + 1 {
    if self.radii[i] > max_len {
      max_len = self.radii[i]
      max_center = i
    }
  } where {
    invariant: i >= 0 && i <= self.radii.length(),
    reasoning: "I: max_len=0, no radii examined. M: Track maximum radius and its center. T: After loop, max_center has longest palindrome in transformed string.",
  }

  // Convert back to original string indices
  // In transformed string, position i corresponds to original position (i-1)/2
  // Radius r in transformed = length r in original
  let start = (max_center - max_len) / 2
  let end = start + max_len
  self.original.substring(start=start, end=end)
}

///|
/// Get length of longest palindrome centered at position i in original string
/// For odd-length palindromes, i is the center character
/// For even-length palindromes, i is between the two center characters
fn ManacherResult::palindrome_length_at(self : ManacherResult, i : Int, odd : Bool) -> Int {
  if i < 0 || i >= self.original.length() {
    return 0
  }
  // In transformed string:
  // - Odd palindrome centered at original[i] -> transformed[2*i + 1]
  // - Even palindrome between original[i-1] and original[i] -> transformed[2*i]
  let t_pos = if odd { 2 * i + 1 } else { 2 * i }
  if t_pos < 0 || t_pos >= self.radii.length() {
    return 0
  }
  self.radii[t_pos]
}

///|
/// Check if substring [l, r) is a palindrome
fn ManacherResult::is_palindrome(self : ManacherResult, l : Int, r : Int) -> Bool {
  if l < 0 || r > self.original.length() || l >= r {
    return false
  }
  let len = r - l
  let center = l + r // In transformed string
  if center >= self.radii.length() {
    return false
  }
  self.radii[center] >= len
}

///|
/// Count all palindromic substrings
fn ManacherResult::count_palindromes(self : ManacherResult) -> Int {
  let mut count = 0
  for i = 0; i < self.radii.length(); i = i + 1 {
    // Each center contributes (radius + 1) / 2 palindromes
    // For separator positions (even i), these are even-length palindromes
    // For character positions (odd i), these are odd-length palindromes
    count = count + (self.radii[i] + 1) / 2
  } where {
    invariant: i >= 0 && i <= self.radii.length(),
    reasoning: "I: count=0. M: Each position i in transformed string with radius r contributes ceil((r+1)/2) palindromes: the center itself (if char position) and all expansions. T: Total count of all palindromic substrings.",
  }
  count
}

///|
/// Get all maximal palindromes (not contained in larger palindrome at same center)
fn ManacherResult::get_all_palindromes(self : ManacherResult) -> Array[(Int, Int)] {
  let result : Array[(Int, Int)] = []

  for i = 0; i < self.radii.length(); i = i + 1 {
    if self.radii[i] > 0 {
      let start = (i - self.radii[i]) / 2
      let end = start + self.radii[i]
      result.push((start, end))
    }
  }

  result
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "manacher basic" {
  let result = manacher("babad")
  let longest = result.longest_palindrome()
  // "bab" or "aba" are both valid
  inspect(longest.length(), content="3")
}

///|
test "manacher even palindrome" {
  let result = manacher("cbbd")
  inspect(result.longest_palindrome(), content="bb")
}

///|
test "manacher single char" {
  let result = manacher("a")
  inspect(result.longest_palindrome(), content="a")
}

///|
test "manacher empty" {
  let result = manacher("")
  inspect(result.longest_palindrome(), content="")
}

///|
test "manacher all same" {
  let result = manacher("aaaa")
  inspect(result.longest_palindrome(), content="aaaa")
}

///|
test "manacher no palindrome longer than 1" {
  let result = manacher("abcd")
  inspect(result.longest_palindrome().length(), content="1")
}

///|
test "manacher count palindromes" {
  let result = manacher("aaa")
  // Palindromes: a(3), aa(2), aaa(1) = 6 total
  inspect(result.count_palindromes(), content="6")
}

///|
test "manacher complex" {
  let result = manacher("abacaba")
  inspect(result.longest_palindrome(), content="abacaba")
}

///|
test "manacher is palindrome" {
  let result = manacher("abacaba")
  inspect(result.is_palindrome(0, 7), content="true") // abacaba
  inspect(result.is_palindrome(0, 3), content="true") // aba
  inspect(result.is_palindrome(0, 2), content="false") // ab
}

///|
test "manacher racecar" {
  let result = manacher("racecar")
  inspect(result.longest_palindrome(), content="racecar")
}
