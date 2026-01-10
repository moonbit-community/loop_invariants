// ============================================================================
// MANACHER'S ALGORITHM - Longest Palindromic Substring
// ============================================================================
//
// Finds all palindromic substrings in linear time by exploiting
// the symmetric property of palindromes.
//
// KEY INSIGHT: Transform string by inserting separators (#a#b#c#).
// This unifies odd and even length palindromes.
// Use a "palindrome box" similar to Z-algorithm.
//
// INVARIANTS:
// 1. p[i] = radius of palindrome centered at i in transformed string
// 2. Maintain rightmost palindrome boundary (center c, right r)
// 3. Mirror property: p[i] >= min(p[mirror], r - i) when i < r
//
// TIME COMPLEXITY: O(n)
// SPACE COMPLEXITY: O(n)

///|
/// Transform string by inserting # between characters
fn transform(s : String) -> Array[Char] {
  let n = s.length()
  let result = Array::make(2 * n + 3, '#')
  result[0] = '^' // Sentinel start
  result[2 * n + 2] = '$' // Sentinel end
  for i = 0; i < n; i = i + 1 {
    result[2 * i + 2] = s[i].to_int().to_char().unwrap()
  }
  result
}

///|
/// Manacher's algorithm - returns palindrome radii array
fn manacher(s : String) -> Array[Int] {
  let t = transform(s)
  let n = t.length()
  let p = Array::make(n, 0)

  // Functional for loop with center and right boundary
  for i = 1, c = 0, r = 0; i < n - 1; {
    let mirror = 2 * c - i

    // Use mirror if inside boundary
    let initial_p = if i < r {
      let min_val = if p[mirror] < r - i { p[mirror] } else { r - i }
      min_val
    } else {
      0
    }

    // Expand palindrome
    let expanded = for rad = initial_p; t[i + rad + 1] == t[i - rad - 1]; {
      continue rad + 1
    } else {
      rad
    }

    p[i] = expanded

    // Update center and right if needed
    let (new_c, new_r) = if i + expanded > r {
      (i, i + expanded)
    } else {
      (c, r)
    }

    continue i + 1, new_c, new_r
  } else {
    p
  }
}

///|
/// Find longest palindromic substring
fn longest_palindrome(s : String) -> String {
  if s.length() == 0 {
    return ""
  }

  let p = manacher(s)

  // Find maximum radius using functional for
  let (max_len, center_idx) = for i = 1, best_len = 0, best_center = 0; i < p.length() - 1; {
    if p[i] > best_len {
      continue i + 1, p[i], i
    } else {
      continue i + 1, best_len, best_center
    }
  } else {
    (best_len, best_center)
  }

  // Convert back to original string indices
  let start = (center_idx - max_len - 1) / 2
  s.substring(start=start, end=start + max_len)
}

///|
/// Count total number of palindromic substrings
fn count_palindromes(s : String) -> Int {
  if s.length() == 0 {
    return 0
  }

  let p = manacher(s)

  // Each p[i] contributes (p[i] + 1) / 2 palindromes for odd positions
  // and p[i] / 2 for even positions
  for i = 1, total = 0; i < p.length() - 1; {
    // In transformed string, odd i corresponds to character centers
    // even i corresponds to gap centers
    let contribution = (p[i] + 1) / 2
    continue i + 1, total + contribution
  } else {
    total
  }
}

///|
/// Check if string is a palindrome
fn is_palindrome(s : String) -> Bool {
  let n = s.length()
  for i = 0; i < n / 2; {
    if s[i] != s[n - 1 - i] {
      break false
    }
    continue i + 1
  } else {
    true
  }
}

///|
/// Find all distinct palindromic substrings (returns their lengths)
fn palindrome_lengths(s : String) -> Array[Int] {
  if s.length() == 0 {
    return []
  }

  let p = manacher(s)
  let lengths : Array[Int] = []

  for i = 1; i < p.length() - 1; {
    if p[i] > 0 {
      // Add palindrome length
      lengths.push(p[i])
    }
    continue i + 1
  }

  lengths
}

///|
/// Find the longest palindromic prefix
fn longest_palindromic_prefix(s : String) -> String {
  let n = s.length()
  if n == 0 {
    return ""
  }

  // Check each possible prefix length
  for len = n; len >= 1; {
    let prefix = s.substring(start=0, end=len)
    if is_palindrome(prefix) {
      break prefix
    }
    continue len - 1
  } else {
    s.substring(start=0, end=1) // Single char is always palindrome
  }
}

///|
/// Find the longest palindromic suffix
fn longest_palindromic_suffix(s : String) -> String {
  let n = s.length()
  if n == 0 {
    return ""
  }

  for start = 0; start < n; {
    let suffix = s.substring(start=start)
    if is_palindrome(suffix) {
      break suffix
    }
    continue start + 1
  } else {
    s.substring(start=n - 1) // Single char is always palindrome
  }
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "longest palindrome odd" {
  let result = longest_palindrome("babad")
  // Either "bab" or "aba" is valid
  inspect(result.length(), content="3")
}

///|
test "longest palindrome even" {
  let result = longest_palindrome("cbbd")
  inspect(result, content="bb")
}

///|
test "longest palindrome single" {
  let result = longest_palindrome("a")
  inspect(result, content="a")
}

///|
test "longest palindrome all same" {
  let result = longest_palindrome("aaaa")
  inspect(result, content="aaaa")
}

///|
test "count palindromes" {
  // "abc": a, b, c = 3
  inspect(count_palindromes("abc"), content="3")
  // "aaa": a(3) + aa(2) + aaa(1) = 6
  inspect(count_palindromes("aaa"), content="6")
}

///|
test "is palindrome" {
  inspect(is_palindrome("racecar"), content="true")
  inspect(is_palindrome("hello"), content="false")
  inspect(is_palindrome("a"), content="true")
  inspect(is_palindrome(""), content="true")
}

///|
test "longest palindromic prefix" {
  inspect(longest_palindromic_prefix("abacd"), content="aba")
  inspect(longest_palindromic_prefix("abcd"), content="a")
}

///|
test "longest palindromic suffix" {
  inspect(longest_palindromic_suffix("dcaba"), content="aba")
  inspect(longest_palindromic_suffix("abcd"), content="d")
}

///|
test "empty string" {
  inspect(longest_palindrome(""), content="")
  inspect(count_palindromes(""), content="0")
}

///|
test "manacher complex" {
  let result = longest_palindrome("forgeeksskeegfor")
  inspect(result, content="geeksskeeg")
}
