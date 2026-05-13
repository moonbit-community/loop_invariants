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
/// Internal result produced by the core Manacher scan.
///
/// `radii[i]` is the palindrome radius at position `i` in the transformed
/// string (original with `#` sentinels interleaved).  `original` is the
/// input string kept for index conversion and substring extraction.
priv struct ManacherResult {
  radii : Array[Int] // Palindrome radii in transformed string
  original : String
}

///|
/// Run Manacher's algorithm on `s` and return the radius array together with
/// the original string.
///
/// The string is first transformed by inserting `#` sentinels so that every
/// palindrome has odd length and a unique center.  The radius array `P` is
/// then filled left to right, reusing previously computed values via the
/// mirror property to keep the total work linear.
///
/// Time: O(n).  Space: O(n).
fn manacher(s : String) -> ManacherResult {
  let n = s.length()
  if n == 0 {
    return { radii: [], original: s }
  }

  // Transform string: "abc" -> "#a#b#c#"
  // Use UInt16 array since string indexing returns UInt16
  let t_len = 2 * n + 1
  let separator : UInt16 = '#'
  let t : Array[UInt16] = Array::make(t_len, separator)
  for i in 0..<n {
    t[2 * i + 1] = s[i]
  } where {
    proof_invariant: i >= 0 && i <= n,
    proof_reasoning: (
      #|INVARIANT (transform):
      #|t is filled with separators, and positions 2*j+1 for j in [0, i)
      #|contain s[j]. Even positions remain separators.
      #|MAINTENANCE:
      #|Place s[i] at position 2*i+1, preserving the separator pattern.
      #|TERMINATION:
      #|At i = n, t interleaves separators and characters: "#a#b#...#".
    ),
  }
  let p = Array::make(t_len, 0) // p[i] = radius of palindrome centered at i
  for i = 0, c = 0, r = 0; i < t_len; {
    // Use mirror property if inside known palindrome
    let mirror = 2 * c - i
    if i < r {
      p[i] = min(r - i, if mirror >= 0 { p[mirror] } else { 0 })
    }

    // Expand around center i
    for expand_next = i - p[i] - 1 >= 0 &&
          i + p[i] + 1 < t_len &&
          t[i - p[i] - 1] == t[i + p[i] + 1]; expand_next; {
      p[i] = p[i] + 1
      continue i - p[i] - 1 >= 0 &&
        i + p[i] + 1 < t_len &&
        t[i - p[i] - 1] == t[i + p[i] + 1]
    }

    // Update rightmost boundary
    let (c, r) = if i + p[i] > r { (i, i + p[i]) } else { (c, r) }
    continue i + 1, c, r
  } where {
    proof_invariant: i >= 0 && i <= t_len && c >= 0 && r >= 0 && r <= t_len,
    proof_reasoning: (
      #|INVARIANT (Manacher scan):
      #|For all centers < i, p is the correct palindrome radius, and (c, r)
      #|marks the rightmost palindrome boundary seen so far.
      #|MAINTENANCE:
      #|If i < r, initialize p[i] using the mirror radius and the boundary.
      #|Then expand around i while characters match. If the expansion crosses
      #|r, update (c, r) to the new rightmost palindrome.
      #|TERMINATION:
      #|At i = t_len, every center has its maximal radius; r only increases,
      #|so total comparisons are linear.
    ),
  }
  { radii: p, original: s }
}

///|
/// Return the smaller of two integers.
fn min(a : Int, b : Int) -> Int {
  if a < b {
    a
  } else {
    b
  }
}

///|
/// Compute the odd and even palindrome radii for every center in `s`.
///
/// Returns a pair `(d1, d2)` of arrays with the same length as `s`:
///
/// - `d1[i]` is the radius of the longest **odd-length** palindrome centered
///   at index `i`.  The palindrome covers `s[i - d1[i] + 1 .. i + d1[i]]`
///   and has length `2 * d1[i] - 1`.  A single character has `d1[i] = 1`.
///
/// - `d2[i]` is the radius of the longest **even-length** palindrome whose
///   center gap falls between `s[i-1]` and `s[i]`.  The palindrome covers
///   `s[i - d2[i] .. i + d2[i]]` and has length `2 * d2[i]`.  A value of
///   zero means no even palindrome is centered there.
///
/// Both arrays are filled in O(n) time using the same rightmost-boundary
/// reuse trick as the full Manacher scan.
///
/// Example:
/// ```
/// let (d1, d2) = manacher_radii("abba")
/// // d1 = [1, 1, 1, 1]  -- every char is a trivial odd palindrome
/// // d2 = [0, 0, 2, 0]  -- "bb" and "abba" are centered between index 1 and 2
/// ```
pub fn manacher_radii(s : String) -> (Array[Int], Array[Int]) {
  let n = s.length()
  if n == 0 {
    return ([], [])
  }
  let d1 = Array::make(n, 0)
  for i = 0, l = 0, r = -1; i < n; {
    let k = if i > r { 1 } else { min(d1[l + r - i], r - i + 1) }
    let len = for t = k {
      if i - t >= 0 && i + t < n && s[i - t] == s[i + t] {
        continue t + 1
      } else {
        break t
      }
    } where {
      proof_invariant: t >= k && t <= n,
      proof_reasoning: (
        #|INVARIANT (odd expand):
        #|t is the current odd radius such that s[i-t..i+t] is a palindrome.
        #|MAINTENANCE:
        #|If both sides match, extend by one; otherwise stop.
        #|TERMINATION:
        #|When the loop ends, t is the maximal odd radius at center i.
      ),
    }
    d1[i] = len
    let right = i + len - 1
    let (l, r) = if right > r { (i - len + 1, right) } else { (l, r) }
    continue i + 1, l, r
  } where {
    proof_invariant: i >= 0 && i <= n,
    proof_reasoning: (
      #|INVARIANT (odd scan):
      #|Odd radii d1[0..i) are finalized.
      #|MAINTENANCE:
      #|Seed the radius from the mirror when i is inside [l, r], then expand.
      #|TERMINATION:
      #|At i = n, all odd centers are processed.
    ),
    proof_invariant: r >= -1 && r < n && l >= 0 && l <= i,
    proof_reasoning: (
      #|INVARIANT (odd window bounds):
      #|[l, r] is the rightmost odd palindrome window; r may be -1 if empty.
      #|MAINTENANCE:
      #|When a longer palindrome is found at i, update (l, r) accordingly.
      #|TERMINATION:
      #|Bounds ensure mirror indices stay valid when i <= r.
    ),
    proof_invariant: r < 0 || l <= r,
    proof_reasoning: (
      #|INVARIANT (odd window order):
      #|When the window is non-empty, its left boundary does not exceed r.
      #|MAINTENANCE:
      #|Updates maintain a valid interval for the current rightmost palindrome.
      #|TERMINATION:
      #|Guarantees the window is well-formed for mirror lookup.
    ),
  }
  let d2 = Array::make(n, 0)
  for i = 0, l = 0, r = -1; i < n; {
    let k = if i > r { 0 } else { min(d2[l + r - i + 1], r - i + 1) }
    let len = for t = k {
      if i - t - 1 >= 0 && i + t < n && s[i - t - 1] == s[i + t] {
        continue t + 1
      } else {
        break t
      }
    } where {
      proof_invariant: t >= k && t <= n,
      proof_reasoning: (
        #|INVARIANT (even expand):
        #|t is the current even radius such that s[i-t..i+t-1] is a palindrome.
        #|MAINTENANCE:
        #|Extend when both sides match; otherwise stop.
        #|TERMINATION:
        #|When the loop ends, t is the maximal even radius at center i.
      ),
    }
    d2[i] = len
    let right = i + len - 1
    let (l, r) = if right > r { (i - len, right) } else { (l, r) }
    continue i + 1, l, r
  } where {
    proof_invariant: i >= 0 && i <= n,
    proof_reasoning: (
      #|INVARIANT (even scan):
      #|Even radii d2[0..i) are finalized.
      #|MAINTENANCE:
      #|Seed radius from the mirror window, then expand around the center.
      #|TERMINATION:
      #|At i = n, all even centers are processed.
    ),
    proof_invariant: r >= -1 && r < n && l >= 0 && l <= i + 1,
    proof_reasoning: (
      #|INVARIANT (even window bounds):
      #|[l, r] is the rightmost even palindrome window; r may be -1 if empty.
      #|MAINTENANCE:
      #|When a longer even palindrome is found, update (l, r) accordingly.
      #|TERMINATION:
      #|Bounds keep the mirror index valid when i <= r.
    ),
    proof_invariant: r < 0 || l <= r + 1,
    proof_reasoning: (
      #|INVARIANT (even window order):
      #|When the window is non-empty, its left boundary is at most r + 1.
      #|MAINTENANCE:
      #|Updates preserve a valid interval for mirror-based initialization.
      #|TERMINATION:
      #|Guarantees window consistency for the even case.
    ),
  }
  (d1, d2)
}

///|
/// Return the longest palindromic substring encoded in `self`.
///
/// Scans the radius array for the maximum value, converts the
/// `(center, radius)` pair back to original-string indices, and returns the
/// corresponding slice.  When multiple centers share the maximum radius, the
/// leftmost one is returned.  Returns `""` for an empty input.
fn ManacherResult::longest_palindrome(self : ManacherResult) -> String {
  if self.radii.length() == 0 {
    return ""
  }
  // Find max radius and its center using functional for loop
  let (max_center, max_len) = for i = 0, best = (0, 0); i < self.radii.length(); {
    if self.radii[i] > best.1 {
      continue i + 1, (i, self.radii[i])
    } else {
      continue i + 1, best
    }
  } nobreak {
    best
  } where {
    proof_invariant: i >= 0 && i <= self.radii.length(),
    proof_reasoning: (
      #|INVARIANT (max radius):
      #|best is (center, length) of the longest palindrome in radii[0..i).
      #|MAINTENANCE:
      #|Update best when a larger radius is found.
      #|TERMINATION:
      #|At i = radii.length(), best holds the global maximum.
    ),
  }

  // Convert back to original string indices
  // In transformed string, position i corresponds to original position (i-1)/2
  // Radius r in transformed = length r in original
  let start = (max_center - max_len) / 2
  let end = start + max_len
  self.original.unsafe_substring(start~, end~)
}

///|
/// Return the radius of the palindrome at a specific center in the original
/// string.
///
/// When `odd` is `true`, `i` is the index of the center character of an
/// odd-length palindrome; the returned value is `P[2*i+1]` in the
/// transformed string.
///
/// When `odd` is `false`, `i` marks the position just right of the gap
/// between the two center characters of an even-length palindrome; the
/// returned value is `P[2*i]`.
///
/// Returns 0 if `i` is out of range.
fn ManacherResult::palindrome_length_at(
  self : ManacherResult,
  i : Int,
  odd : Bool,
) -> Int {
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
/// Return `true` if the half-open interval `[l, r)` of the original string
/// is a palindrome.
///
/// Uses the precomputed radius array: the center of `[l, r)` in the
/// transformed string is `l + r`, and the palindrome covers the interval when
/// `P[l+r] >= r - l`.  Returns `false` for invalid or empty intervals.
fn ManacherResult::is_palindrome(
  self : ManacherResult,
  l : Int,
  r : Int,
) -> Bool {
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
/// Count all distinct palindromic substrings (by position, not by value).
///
/// Each transformed-string center with radius `r` contributes `(r + 1) / 2`
/// palindromes to the original string: one for each odd or even length from
/// the minimal palindrome up to the full radius.  The sum over all centers
/// gives the total count in O(n).
fn ManacherResult::count_palindromes(self : ManacherResult) -> Int {
  // Each center contributes (radius + 1) / 2 palindromes
  // For separator positions (even i), these are even-length palindromes
  // For character positions (odd i), these are odd-length palindromes
  self.radii[:].fold(init=0, (count, r) => count + (r + 1) / 2)
}

///|
/// Collect the maximal palindrome span for every center that has a positive
/// radius.
///
/// Returns an array of `(start, end)` pairs in half-open notation `[start,
/// end)` in the original string, one entry per transformed-string center with
/// `P[i] > 0`.  The pairs are in order of increasing center index.
///
/// Note: this does not enumerate every palindromic substring; it returns only
/// the longest palindrome for each center.
fn ManacherResult::get_all_palindromes(
  self : ManacherResult,
) -> Array[(Int, Int)] {
  let result : Array[(Int, Int)] = []
  for i in 0..<self.radii.length() {
    if self.radii[i] > 0 {
      let start = (i - self.radii[i]) / 2
      let end = start + self.radii[i]
      result.push((start, end))
    }
  } where {
    proof_invariant: i >= 0 && i <= self.radii.length(),
    proof_reasoning: (
      #|INVARIANT (collect spans):
      #|result contains maximal palindrome spans for centers in [0, i).
      #|MAINTENANCE:
      #|If a center has positive radius, add its maximal span.
      #|TERMINATION:
      #|At i = radii.length(), all maximal spans are collected.
    ),
  }
  result
}

///|
/// Return the longest palindromic substring of `s`.
///
/// Runs the Manacher scan in O(n) and extracts the substring corresponding to
/// the maximum radius.  When multiple centers tie for the longest palindrome,
/// the leftmost one is returned.  Returns `""` for an empty string.
///
/// Example:
/// ```
/// longest_palindrome("cbbd")    // "bb"
/// longest_palindrome("racecar") // "racecar"
/// longest_palindrome("abcdef")  // any single character, e.g. "a"
/// ```
pub fn longest_palindrome(s : String) -> String {
  manacher(s).longest_palindrome()
}

///|
/// Return the length of the longest palindromic substring of `s`.
///
/// Uses `manacher_radii` to compute odd and even radii, then iterates over
/// every center in O(n) to find the maximum.  Returns 1 for a non-empty
/// string with no palindrome longer than a single character, and 0 for the
/// empty string.
///
/// Example:
/// ```
/// longest_palindrome_len("abacaba") // 7
/// longest_palindrome_len("cbbd")    // 2
/// longest_palindrome_len("abcdef")  // 1
/// ```
pub fn longest_palindrome_len(s : String) -> Int {
  let (d1, d2) = manacher_radii(s)
  // Find max length by comparing odd and even palindromes at each center
  for i = 0, best = 0; i < d1.length(); {
    let odd = d1[i] * 2 - 1
    let even = d2[i] * 2
    let max_at_i = if odd > even { odd } else { even }
    let new_best = if max_at_i > best { max_at_i } else { best }
    continue i + 1, new_best
  } nobreak {
    best
  } where {
    proof_invariant: i >= 0 && i <= d1.length(),
    proof_reasoning: (
      #|INVARIANT (max palindrome length):
      #|best is the maximum palindrome length in [0..i).
      #|MAINTENANCE:
      #|Compare odd and even lengths at center i and update best.
      #|TERMINATION:
      #|At i = n, best holds the global maximum palindrome length.
    ),
  }
}

///|
/// Count all palindromic substrings of `s` (by position, not by value).
///
/// Two occurrences of the same palindrome at different positions are counted
/// separately.  The result is computed in O(n) via the Manacher radius array.
///
/// Example:
/// ```
/// count_palindromes("aaa")  // 6  ("a"x3, "aa"x2, "aaa"x1)
/// count_palindromes("aaaa") // 10
/// count_palindromes("abcd") // 4  (only single characters)
/// ```
pub fn count_palindromes(s : String) -> Int {
  manacher(s).count_palindromes()
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "manacher basic" {
  let result = manacher("babad")
  let longest = result.longest_palindrome()
  // "bab" or "aba" are both valid
  debug_inspect(longest.length(), content="3")
  debug_inspect(result.palindrome_length_at(0, true) >= 1, content="true")
  debug_inspect(result.get_all_palindromes().length() > 0, content="true")
}

///|
test "manacher even palindrome" {
  let result = manacher("cbbd")
  debug_inspect(result.longest_palindrome(), content=(
    #|"bb"
  ))
}

///|
test "manacher single char" {
  let result = manacher("a")
  debug_inspect(result.longest_palindrome(), content=(
    #|"a"
  ))
}

///|
test "manacher empty" {
  let result = manacher("")
  debug_inspect(result.longest_palindrome(), content=(
    #|""
  ))
}

///|
test "manacher all same" {
  let result = manacher("aaaa")
  debug_inspect(result.longest_palindrome(), content=(
    #|"aaaa"
  ))
}

///|
test "manacher no palindrome longer than 1" {
  let result = manacher("abcd")
  debug_inspect(result.longest_palindrome().length(), content="1")
}

///|
test "manacher count palindromes" {
  let result = manacher("aaa")
  // Palindromes: a(3), aa(2), aaa(1) = 6 total
  debug_inspect(result.count_palindromes(), content="6")
}

///|
test "manacher complex" {
  let result = manacher("abacaba")
  debug_inspect(result.longest_palindrome(), content=(
    #|"abacaba"
  ))
}

///|
test "manacher is palindrome" {
  let result = manacher("abacaba")
  debug_inspect(result.is_palindrome(0, 7), content="true") // abacaba
  debug_inspect(result.is_palindrome(0, 3), content="true") // aba
  debug_inspect(result.is_palindrome(0, 2), content="false") // ab
}

///|
test "manacher racecar" {
  let result = manacher("racecar")
  debug_inspect(result.longest_palindrome(), content=(
    #|"racecar"
  ))
}

///|
test "manacher radii" {
  let (d1, d2) = manacher_radii("abba")
  debug_inspect(d1, content="[1, 1, 1, 1]")
  debug_inspect(d2, content="[0, 0, 2, 0]")
}

///|
test "manacher longest length" {
  debug_inspect(longest_palindrome_len("abacaba"), content="7")
  debug_inspect(longest_palindrome_len("babad"), content="3")
  debug_inspect(longest_palindrome_len("cbbd"), content="2")
}
