// ============================================================================
// Challenge: KMP String Matching
// ============================================================================

///|
#warnings("+missing_invariant+missing_reasoning")
pub fn prefix_function(pattern : StringView) -> Array[Int] {
  let m = pattern.length()
  if m == 0 {
    return []
  }
  let pi = Array::make(m, 0)
  for i = 1, j = 0 {
    if i >= m {
      break
    }
    let new_j = for k = j {
      if k > 0 && pattern[k] != pattern[i] {
        continue pi[k - 1]
      } else {
        break k
      }
    } where {
      invariant: k >= 0 && k <= i,
      reasoning: (
        #|INVARIANT (border fallback):
        #|k is a candidate border length for pattern[0..i). Each step replaces
        #|k with a shorter border pi[k-1], so we only consider valid borders.
        #|MAINTENANCE:
        #|If pattern[k] mismatches pattern[i], drop to the next border.
        #|TERMINATION:
        #|Loop ends with k = 0 or pattern[k] == pattern[i], ready to extend.
      ),
    }
    let j2 = if pattern[new_j] == pattern[i] { new_j + 1 } else { new_j }
    pi[i] = j2
    continue i + 1, j2
  } where {
    invariant: i >= 1 && i <= m && j >= 0 && j <= i,
    reasoning: (
      #|INVARIANT (prefix function):
      #|pi[0..i) is correct, and j is the length of the longest border of
      #|pattern[0..i). This means pattern[0..j) is a suffix of pattern[0..i).
      #|MAINTENANCE:
      #|Fallback via pi until the next character can extend the border, then
      #|set pi[i] to the extended border length.
      #|TERMINATION:
      #|At i = m, pi encodes the longest proper prefix that is also a suffix
      #|for every prefix of the pattern.
    ),
  }
  pi
}

///|
#warnings("+missing_invariant+missing_reasoning")
pub fn kmp_search(text : StringView, pattern : StringView) -> Array[Int] {
  let n = text.length()
  let m = pattern.length()
  let matches : Array[Int] = []
  if m == 0 || m > n {
    return matches
  }
  let pi = prefix_function(pattern)
  for i = 0, j = 0 {
    if i >= n {
      break
    }
    let new_j = for k = j {
      if k > 0 && pattern[k] != text[i] {
        continue pi[k - 1]
      } else {
        break k
      }
    } where {
      invariant: k >= 0 && k <= m,
      reasoning: (
        #|INVARIANT (match fallback):
        #|k is a border length of pattern[0..j) that could still match the
        #|current text position. We only move to shorter borders via pi.
        #|MAINTENANCE:
        #|If pattern[k] mismatches text[i], drop to pi[k-1].
        #|TERMINATION:
        #|Ends with the longest border that can match text[i], or k = 0.
      ),
    }
    let j2 = if pattern[new_j] == text[i] { new_j + 1 } else { new_j }
    if j2 == m {
      matches.push(i - m + 1)
      continue i + 1, pi[j2 - 1]
    } else {
      continue i + 1, j2
    }
  } where {
    invariant: i >= 0 && i <= n && j >= 0 && j <= m,
    reasoning: (
      #|INVARIANT (KMP scan):
      #|pattern[0..j) matches text[i-j..i). Thus j tracks the current matched
      #|prefix length at position i.
      #|MAINTENANCE:
      #|On mismatch, fall back using pi; on match, extend by one. When j == m,
      #|record a match and fall back to continue searching.
      #|TERMINATION:
      #|At i = n, all occurrences have been reported in linear time.
    ),
  }
  matches
}

///|
/// Return the first index of pattern in text, or -1 if absent.
pub fn kmp_find_first(text : StringView, pattern : StringView) -> Int {
  let matches = kmp_search(text, pattern)
  if matches.length() > 0 {
    matches[0]
  } else {
    -1
  }
}

///|
/// Count how many times pattern occurs in text.
pub fn kmp_count(text : StringView, pattern : StringView) -> Int {
  kmp_search(text, pattern).length()
}

///|
test "kmp_prefix_function" {
  assert_eq(prefix_function("ababa"[:]), [0, 0, 1, 2, 3])
  assert_eq(prefix_function("aaaa"[:]), [0, 1, 2, 3])
}

///|
test "kmp_search_basic" {
  let text = "ababcababa"
  let pattern = "aba"
  assert_eq(kmp_search(text[:], pattern[:]), [0, 5, 7])
  assert_eq(kmp_find_first(text[:], "cab"[:]), 4)
  assert_eq(kmp_find_first(text[:], "xyz"[:]), -1)
  assert_eq(kmp_count(text[:], pattern[:]), 3)
}
