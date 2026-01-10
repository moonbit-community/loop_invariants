// ============================================================================
// Z-ALGORITHM - Linear Time Pattern Matching
// ============================================================================
//
// The Z-algorithm computes for each position i the length of the longest
// substring starting at i that matches a prefix of the string.
//
// Z[i] = length of longest string starting at i that is also a prefix
//
// KEY INSIGHT: Maintain a "Z-box" [l, r] where s[l..r] matches s[0..r-l].
// When processing position i, if i is inside the Z-box, we can use
// previously computed values.
//
// INVARIANTS:
// 1. Z[0] = 0 by convention (or n, depending on definition)
// 2. For i > 0: s[0..Z[i]-1] = s[i..i+Z[i]-1]
// 3. Z-box [l, r] is always the rightmost Z-box found so far
//
// TIME COMPLEXITY: O(n)
// SPACE COMPLEXITY: O(n)

///|
/// Compute Z-array for string s
fn z_function(s : String) -> Array[Int] {
  let n = s.length()
  if n == 0 {
    return []
  }

  let z = Array::make(n, 0)
  z[0] = n // By convention, Z[0] = n

  // Functional for loop maintaining Z-box [l, r]
  for i = 1, l = 0, r = 0; i < n; {
    let (new_l, new_r, zi) = if i < r {
      // i is inside Z-box
      let k = i - l
      if z[k] < r - i {
        // Stays inside Z-box
        (l, r, z[k])
      } else {
        // Extends beyond Z-box, need to match further
        // We already know (r - i) characters match, check for more
        let extended = match_from(s, r - i, r)
        let total = (r - i) + extended
        (i, i + total, total)
      }
    } else {
      // i is outside Z-box
      let matched = match_from(s, 0, i)
      if matched > 0 {
        (i, i + matched, matched)
      } else {
        (l, r, 0)
      }
    }
    z[i] = zi
    continue i + 1, new_l, new_r
  } else {
    z
  }
}

///|
/// Match s[0..] with s[start..], return length of match
fn match_from(s : String, prefix_pos : Int, str_pos : Int) -> Int {
  let n = s.length()
  for len = 0; prefix_pos + len < n && str_pos + len < n; {
    if s[prefix_pos + len] == s[str_pos + len] {
      continue len + 1
    } else {
      break len
    }
  } else {
    len
  }
}

///|
/// Find all occurrences of pattern in text using Z-algorithm
fn z_search(text : String, pattern : String) -> Array[Int] {
  let m = pattern.length()
  let n = text.length()

  if m == 0 || n < m {
    return []
  }

  // Concatenate: pattern + "$" + text
  let concat = pattern + "$" + text
  let z = z_function(concat)

  // Collect matches using functional approach
  let results : Array[Int] = []
  for i = m + 1; i < concat.length(); {
    if z[i] >= m {
      results.push(i - m - 1)
    }
    continue i + 1
  }
  results
}

///|
/// Find the longest prefix of s that is also a suffix
fn longest_prefix_suffix(s : String) -> Int {
  let n = s.length()
  if n <= 1 {
    return 0
  }

  let z = z_function(s)

  // Find longest Z[i] such that i + Z[i] = n
  for i = 1, best = 0; i < n; {
    let new_best = if z[i] > 0 && i + z[i] == n && z[i] > best {
      z[i]
    } else {
      best
    }
    continue i + 1, new_best
  } else {
    best
  }
}

///|
/// Count occurrences of pattern in text
fn z_count(text : String, pattern : String) -> Int {
  z_search(text, pattern).length()
}

///|
/// Find the period of string (smallest p such that s[i] = s[i mod p])
fn string_period(s : String) -> Int {
  let n = s.length()
  if n == 0 {
    return 0
  }

  let z = z_function(s)

  // Find smallest i such that i + Z[i] = n
  for i = 1; i < n; {
    if i + z[i] == n {
      break i
    }
    continue i + 1
  } else {
    n // String has no proper period
  }
}

///|
/// Check if pattern occurs in text
fn z_contains(text : String, pattern : String) -> Bool {
  z_search(text, pattern).length() > 0
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "z function basic" {
  let z = z_function("aabxaab")
  inspect(z[0], content="7") // Whole string
  inspect(z[1], content="1") // "a" matches prefix
  inspect(z[4], content="3") // "aab" matches prefix
}

///|
test "z function all same" {
  let z = z_function("aaaa")
  inspect(z[0], content="4")
  inspect(z[1], content="3")
  inspect(z[2], content="2")
  inspect(z[3], content="1")
}

///|
test "z search" {
  let positions = z_search("abracadabra", "abra")
  inspect(positions.length(), content="2")
  inspect(positions[0], content="0")
  inspect(positions[1], content="7")
}

///|
test "z search no match" {
  let positions = z_search("hello", "xyz")
  inspect(positions.length(), content="0")
}

///|
test "z count" {
  inspect(z_count("abababa", "aba"), content="3")
  inspect(z_count("aaaa", "aa"), content="3")
}

///|
test "longest prefix suffix" {
  inspect(longest_prefix_suffix("abcab"), content="2") // "ab"
  inspect(longest_prefix_suffix("aaa"), content="2")   // "aa"
  inspect(longest_prefix_suffix("abcd"), content="0")  // No common
}

///|
test "string period" {
  inspect(string_period("abcabc"), content="3")  // "abc" repeats
  inspect(string_period("aaaa"), content="1")    // "a" repeats
  inspect(string_period("abcd"), content="4")    // No proper period
}

///|
test "z empty" {
  let z = z_function("")
  inspect(z.length(), content="0")
}

///|
test "z single" {
  let z = z_function("a")
  inspect(z[0], content="1")
}

///|
test "z contains" {
  inspect(z_contains("hello world", "world"), content="true")
  inspect(z_contains("hello world", "xyz"), content="false")
}
