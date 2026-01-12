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
}

///|
/// Compute palindrome radii using Manacher's algorithm
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
  for i = 0; i < n; i = i + 1 {
    t[2 * i + 1] = s[i]
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
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
    reasoning: (
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
fn min(a : Int, b : Int) -> Int {
  if a < b {
    a
  } else {
    b
  }
}

///|
/// Compute odd/even palindrome radii for each center in the original string.
/// d1[i] = radius of odd palindrome centered at i (length = 2*d1[i] - 1)
/// d2[i] = radius of even palindrome centered between i-1 and i (length = 2*d2[i])
pub fn manacher_radii(s : String) -> (Array[Int], Array[Int]) {
  let n = s.length()
  if n == 0 {
    return ([], [])
  }
  let d1 = Array::make(n, 0)
  for i = 0, l = 0, r = -1; i < n; {
    let mut curr_l = l
    let mut curr_r = r
    let k = if i > curr_r {
      1
    } else {
      min(d1[curr_l + curr_r - i], curr_r - i + 1)
    }
    let len = for t = k {
      if i - t >= 0 && i + t < n && s[i - t] == s[i + t] {
        continue t + 1
      } else {
        break t
      }
    } where {
      invariant: t >= k && t <= n,
      reasoning: (
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
    if right > curr_r {
      curr_l = i - len + 1
      curr_r = right
    }
    continue i + 1, curr_l, curr_r
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (odd scan):
      #|Odd radii d1[0..i) are finalized.
      #|MAINTENANCE:
      #|Seed the radius from the mirror when i is inside [l, r], then expand.
      #|TERMINATION:
      #|At i = n, all odd centers are processed.
    ),
    invariant: r >= -1 && r < n && l >= 0 && l <= i,
    reasoning: (
      #|INVARIANT (odd window bounds):
      #|[l, r] is the rightmost odd palindrome window; r may be -1 if empty.
      #|MAINTENANCE:
      #|When a longer palindrome is found at i, update (l, r) accordingly.
      #|TERMINATION:
      #|Bounds ensure mirror indices stay valid when i <= r.
    ),
    invariant: r < 0 || l <= r,
    reasoning: (
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
    let mut curr_l = l
    let mut curr_r = r
    let k = if i > curr_r {
      0
    } else {
      min(d2[curr_l + curr_r - i + 1], curr_r - i + 1)
    }
    let len = for t = k {
      if i - t - 1 >= 0 && i + t < n && s[i - t - 1] == s[i + t] {
        continue t + 1
      } else {
        break t
      }
    } where {
      invariant: t >= k && t <= n,
      reasoning: (
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
    if right > curr_r {
      curr_l = i - len
      curr_r = right
    }
    continue i + 1, curr_l, curr_r
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (even scan):
      #|Even radii d2[0..i) are finalized.
      #|MAINTENANCE:
      #|Seed radius from the mirror window, then expand around the center.
      #|TERMINATION:
      #|At i = n, all even centers are processed.
    ),
    invariant: r >= -1 && r < n && l >= 0 && l <= i + 1,
    reasoning: (
      #|INVARIANT (even window bounds):
      #|[l, r] is the rightmost even palindrome window; r may be -1 if empty.
      #|MAINTENANCE:
      #|When a longer even palindrome is found, update (l, r) accordingly.
      #|TERMINATION:
      #|Bounds keep the mirror index valid when i <= r.
    ),
    invariant: r < 0 || l <= r + 1,
    reasoning: (
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
    reasoning: (
      #|INVARIANT (max radius):
      #|max_len is the largest radius among centers in [0, i), and max_center
      #|records its position.
      #|MAINTENANCE:
      #|Update max_len and max_center when a larger radius is found.
      #|TERMINATION:
      #|At i = radii.length(), max_center marks the longest palindrome.
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
/// Get length of longest palindrome centered at position i in original string
/// For odd-length palindromes, i is the center character
/// For even-length palindromes, i is between the two center characters
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
/// Check if substring [l, r) is a palindrome
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
    reasoning: (
      #|INVARIANT (palindrome count):
      #|count equals the total number of palindromic substrings contributed by
      #|centers in [0, i).
      #|MAINTENANCE:
      #|Each center adds (radii[i] + 1) / 2 palindromes in the original string.
      #|TERMINATION:
      #|At i = radii.length(), count is the total number of palindromic substrings.
    ),
  }
  count
}

///|
/// Get all maximal palindromes (not contained in larger palindrome at same center)
fn ManacherResult::get_all_palindromes(
  self : ManacherResult,
) -> Array[(Int, Int)] {
  let result : Array[(Int, Int)] = []
  for i = 0; i < self.radii.length(); i = i + 1 {
    if self.radii[i] > 0 {
      let start = (i - self.radii[i]) / 2
      let end = start + self.radii[i]
      result.push((start, end))
    }
  } where {
    invariant: i >= 0 && i <= self.radii.length(),
    reasoning: (
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
/// Return the longest palindromic substring in s.
pub fn longest_palindrome(s : String) -> String {
  manacher(s).longest_palindrome()
}

///|
/// Return the length of the longest palindromic substring in s.
pub fn longest_palindrome_len(s : String) -> Int {
  let (d1, d2) = manacher_radii(s)
  let n = d1.length()
  let mut best = 0
  for i in 0..<n {
    let odd = d1[i] * 2 - 1
    if odd > best {
      best = odd
    }
    let even = d2[i] * 2
    if even > best {
      best = even
    }
  }
  best
}

///|
/// Count all palindromic substrings in s.
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
  inspect(longest.length(), content="3")
  inspect(result.palindrome_length_at(0, true) >= 1, content="true")
  inspect(result.get_all_palindromes().length() > 0, content="true")
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

///|
test "manacher radii" {
  let (d1, d2) = manacher_radii("abba")
  inspect(d1, content="[1, 1, 1, 1]")
  inspect(d2, content="[0, 0, 2, 0]")
}

///|
test "manacher longest length" {
  inspect(longest_palindrome_len("abacaba"), content="7")
  inspect(longest_palindrome_len("babad"), content="3")
  inspect(longest_palindrome_len("cbbd"), content="2")
}
