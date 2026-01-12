// ============================================================================
// Advanced String Algorithm Examples
// Featuring linear-time algorithms with elegant invariants
// ============================================================================

// ============================================================================
// Example S1: Z-Algorithm
// Compute Z-array where Z[i] = length of longest substring starting at i
// that matches a prefix of the string. O(n) time.
// ============================================================================

///|
/// Compute Z-array: Z[i] = length of longest common prefix of s and s[i..].
/// Z[0] is undefined (conventionally 0 or n).
#warnings("+missing_invariant+missing_reasoning")
fn z_algorithm(s : ArrayView[Char]) -> Array[Int] {
  let n = s.length()
  guard n > 0 else { return [] }
  let z : Array[Int] = Array::make(n, 0)
  z[0] = n // By convention, entire string matches itself

  // [l, r) is the "Z-box": rightmost interval where s[l..r) == s[0..r-l)
  for i = 1, l = 0, r = 0 {
    if i >= n {
      break z
    } else if i >= r {
      // Case 1: i is outside current Z-box, compute from scratch
      let mut len = 0
      while i + len < n && s[len] == s[i + len] {
        len = len + 1
      }
      z[i] = len
      if len > 0 {
        continue i + 1, i, i + len
      } else {
        continue i + 1, l, r
      }
    } else {
      // Case 2: i is inside Z-box [l, r)
      // s[i..r) == s[i-l..r-l) because we're in the Z-box
      let k = i - l // Corresponding position in prefix
      let remaining = r - i // How much of Z-box is left
      if z[k] < remaining {
        // Case 2a: Z[k] fits entirely within remaining Z-box
        z[i] = z[k]
        continue i + 1, l, r
      } else {
        // Case 2b: Z[k] reaches or exceeds Z-box boundary
        // Need to extend by comparing beyond r
        let mut len = remaining
        while r + len - i < n && i + len < n && s[r - i + len] == s[i + len] {
          len = len + 1
        }
        z[i] = len
        continue i + 1, i, i + len
      }
    }
  } where {
    invariant: i >= 1 && i <= n && l >= 0 && r >= l && r <= n,
    reasoning: (
      #|INVARIANT 1 (Bounds and progress):
      #|i advances left-to-right, and [l, r) always denotes a valid Z-box
      #|within the string. This ensures every access into s is in range and
      #|the loop terminates when i reaches n.
      #|MAINTENANCE:
      #|Advance i and update (l, r) whenever a longer Z-box is found.
      #|TERMINATION:
      #|At i == n, all Z-values have been computed.
    ),
    invariant: l < i,
    reasoning: (
      #|INVARIANT 2 (Z-box property):
      #|If r > l, then s[l..r) == s[0..r-l).
      #|
      #|The Z-box [l, r) tracks the rightmost interval we've found
      #|where the substring starting at l matches a prefix of s.
      #|
      #|KEY INSIGHT: When i is inside the Z-box (i < r), we know:
      #|  s[i..r) == s[i-l..r-l)
      #|
      #|This means the answer at position i is related to the answer
      #|at position (i-l) in the prefix, which we've already computed!
      #|
      #|CASE ANALYSIS:
      #|
      #|Case 2a (Z[k] < remaining):
      #|  The match at position k ends before the Z-box boundary.
      #|  Since s[i..r) == s[k..r-l), and Z[k] characters match at k,
      #|  exactly Z[k] characters match at i too.
      #|  No extension needed, Z[i] = Z[k].
      #|
      #|Case 2b (Z[k] >= remaining):
      #|  The match at position k reaches or exceeds the boundary.
      #|  We know at least 'remaining' characters match at i.
      #|  But there might be more! We must extend beyond r.
      #|
      #|AMORTIZED O(n) ANALYSIS:
      #|  - r only increases (never decreases)
      #|  - Each comparison either increments r or is "free" (Case 2a)
      #|  - Total comparisons ≤ 2n
      #|
      #|APPLICATION: Pattern matching in O(n+m) time.
      #|Concatenate pattern + sentinel + text, compute Z-array.
      #|Positions where Z[i] >= pattern.length() are matches.
      #|MAINTENANCE:
      #|If i < r, reuse or extend from the Z-box; if i >= r, start a new box.
      #|TERMINATION:
      #|At i == n, every position has its correct Z value.
    ),
  }
}

///|
test "z_algorithm" {
  let s : Array[Char] = ['a', 'a', 'b', 'a', 'a', 'b', 'a', 'a']
  let z = z_algorithm(s[:])
  // s = "aabaaaba"
  // Z = [8, 1, 0, 5, 1, 0, 2, 1]
  assert_eq(z[0], 8) // Entire string
  assert_eq(z[1], 1) // "a" matches prefix "a"
  assert_eq(z[2], 0) // "b" doesn't match "a"
  assert_eq(z[3], 5) // "aabaa" matches prefix
}

// ============================================================================
// Example S2: Manacher's Algorithm
// Find all palindromic substrings in O(n) time
// ============================================================================

///|
/// Manacher's algorithm: compute palindrome radii centered at each position.
/// Uses transformed string with separators to handle even-length palindromes.
/// Returns array where p[i] = radius of palindrome centered at position i
/// in the transformed string (including the center).
#warnings("+missing_invariant+missing_reasoning")
fn manacher(s : ArrayView[Char]) -> Array[Int] {
  let n = s.length()
  guard n > 0 else { return [] }

  // Transform: "abc" -> "#a#b#c#" (length 2n+1)
  // This handles both odd and even length palindromes uniformly
  let t_len = 2 * n + 1
  let p : Array[Int] = Array::make(t_len, 0)

  // Helper to get character at position in transformed string
  fn get_char(i : Int) -> Char {
    if i % 2 == 0 {
      '#'
    } else {
      s[i / 2]
    }
  }

  // c = center of rightmost palindrome, r = right boundary
  for i = 0, c = 0, r = 0 {
    if i >= t_len {
      break p
    } else {
      // Mirror position of i with respect to center c
      let mirror = 2 * c - i
      if i < r && mirror >= 0 {
        // Use mirror's palindrome radius as starting point
        let min_radius = if p[mirror] < r - i { p[mirror] } else { r - i }
        p[i] = min_radius
      }

      // Try to expand palindrome centered at i
      let mut left = i - p[i] - 1
      let mut right = i + p[i] + 1
      while left >= 0 && right < t_len && get_char(left) == get_char(right) {
        p[i] = p[i] + 1
        left = left - 1
        right = right + 1
      }

      // Update center and right boundary if we expanded past r
      if i + p[i] > r {
        continue i + 1, i, i + p[i]
      } else {
        continue i + 1, c, r
      }
    }
  } where {
    invariant: i >= 0 && i <= t_len && c >= 0 && c < t_len && r >= c,
    reasoning: (
      #|INVARIANT 1 (Bounds and center validity):
      #|c and r identify the rightmost palindrome seen so far, and i never
      #|exceeds t_len. This keeps all computed radii inside the transformed
      #|string and ensures every extension check is safe.
      #|MAINTENANCE:
      #|Update p[i] and adjust (c, r) when the palindrome expands.
      #|TERMINATION:
      #|At i == t_len, all radii are computed.
    ),
    invariant: c <= i,
    reasoning: (
      #|INVARIANT 2 (Palindrome boundary):
      #|r is the rightmost boundary we've seen: t[c-p[c]..c+p[c]+1) is
      #|a palindrome, and r = c + p[c].
      #|
      #|MANACHER'S KEY INSIGHT:
      #|When computing p[i], if i < r, then i has a "mirror" position
      #|mirror = 2*c - i within the palindrome centered at c.
      #|
      #|Since palindromes are symmetric:
      #|  t[i..r) == reverse(t[2c-r..mirror])
      #|
      #|The palindrome at mirror gives us a lower bound for p[i]:
      #|  - If p[mirror] < r - i: The mirror's palindrome fits entirely
      #|    within the big palindrome. By symmetry, p[i] = p[mirror].
      #|  - If p[mirror] >= r - i: The mirror's palindrome reaches or
      #|    exceeds the boundary. We know p[i] >= r - i, but we must
      #|    check beyond r.
      #|
      #|VISUAL REPRESENTATION:
      #|  |<-------- palindrome centered at c -------->|
      #|  [     mirror    c           i           r    ]
      #|  |<-- p[mirror] -->|         |<-- p[i] -->|
      #|
      #|The region from i to r is guaranteed to be palindromic (mirrors
      #|the region from mirror to 2c-r). Beyond r, we must verify.
      #|
      #|AMORTIZED O(n) ANALYSIS:
      #|  - r only increases
      #|  - Each character comparison either extends r or is "free"
      #|    (using mirror information)
      #|  - Total comparisons ≤ 2 * t_len = O(n)
      #|
      #|TRANSFORMATION INSIGHT:
      #|By inserting '#' between characters, every palindrome (odd or even
      #|length in original) becomes odd-length in transformed string,
      #|with a definite center. This unifies the two cases elegantly.
      #|
      #|Original palindrome length = p[i] (for positions in transformed string)
      #|MAINTENANCE:
      #|Use the mirror radius when inside the current boundary and extend if needed.
      #|TERMINATION:
      #|At i == t_len, the rightmost boundary information is complete.
    ),
  }
}

///|
/// Find longest palindromic substring using Manacher's algorithm.
pub fn longest_palindrome_range(s : ArrayView[Char]) -> (Int, Int) {
  let n = s.length()
  guard n > 0 else { return (0, 0) }
  let p = manacher(s)

  // Find position with maximum radius
  let mut max_radius = 0
  let mut max_center = 0
  for i = 0; i < p.length(); i = i + 1 {
    if p[i] > max_radius {
      max_radius = p[i]
      max_center = i
    }
  } where {
    invariant: i >= 0 && i <= p.length(),
    reasoning: (
      #|INVARIANT (Maximum radius scan):
      #|After processing centers [0..i), max_radius is the maximum p value
      #|seen so far, and max_center is an index achieving that maximum.
      #|
      #|Because p stores the palindrome radius at every center in the
      #|transformed string, the maximum radius corresponds to the longest
      #|palindromic substring in the original string (after conversion).
      #|MAINTENANCE:
      #|Compare p[i] with max_radius and update max_center when larger.
      #|TERMINATION:
      #|At i == p.length(), max_center marks the longest palindrome.
    ),
  }

  // Convert back to original string indices
  // In transformed string, center i corresponds to original position i/2
  // Radius p[i] in transformed = length p[i] in original
  let start = (max_center - max_radius) / 2
  let length = max_radius
  (start, length)
}

///|
test "manacher" {
  // "abacaba" - entire string is palindrome
  let s1 : Array[Char] = ['a', 'b', 'a', 'c', 'a', 'b', 'a']
  let (start1, len1) = longest_palindrome_range(s1[:])
  assert_eq(start1, 0)
  assert_eq(len1, 7)

  // "abba" - even length palindrome
  let s2 : Array[Char] = ['a', 'b', 'b', 'a']
  let (start2, len2) = longest_palindrome_range(s2[:])
  assert_eq(start2, 0)
  assert_eq(len2, 4)

  // "abcbd" - "bcb" is longest
  let s3 : Array[Char] = ['a', 'b', 'c', 'b', 'd']
  let (start3, len3) = longest_palindrome_range(s3[:])
  assert_eq(start3, 1)
  assert_eq(len3, 3)
}

// ============================================================================
// Example S3: Rabin-Karp Rolling Hash
// String matching with O(n+m) expected time using polynomial hashing
// ============================================================================

///|
/// Rabin-Karp string matching using rolling hash.
/// Returns all starting positions where pattern occurs in text.
#warnings("+missing_invariant+missing_reasoning")
fn rabin_karp(text : ArrayView[Char], pattern : ArrayView[Char]) -> Array[Int] {
  let n = text.length()
  let m = pattern.length()
  guard m > 0 && n >= m else { return [] }
  let base = 256 // Number of characters in alphabet
  let modulus = 1000000007 // Large prime for hashing

  // Compute base^(m-1) mod modulus for removing leading digit
  let h = for i = 0, acc = 1 {
    if i >= m - 1 {
      break acc
    } else {
      continue i + 1, acc * base % modulus
    }
  } where {
    invariant: i >= 0 && i <= m - 1 && acc >= 0 && acc < modulus,
    reasoning: (
      #|INVARIANT (Base power):
      #|acc = base^i mod modulus after i steps, so when i reaches m-1,
      #|acc equals base^(m-1) mod modulus. This factor is used to remove the
      #|leading character from a window during rolling updates.
      #|MAINTENANCE:
      #|Multiply acc by base modulo modulus and advance i.
      #|TERMINATION:
      #|At i == m - 1, acc is base^(m-1) mod modulus.
    ),
  }

  // Compute initial hash of pattern and first window of text
  let (pattern_hash, text_hash) = for i = 0, ph = 0, th = 0 {
    if i >= m {
      break (ph, th)
    } else {
      let p_char = pattern[i].to_int()
      let t_char = text[i].to_int()
      let new_ph = (ph * base + p_char) % modulus
      let new_th = (th * base + t_char) % modulus
      continue i + 1, new_ph, new_th
    }
  } where {
    invariant: i >= 0 &&
    i <= m &&
    ph >= 0 &&
    ph < modulus &&
    th >= 0 &&
    th < modulus,
    reasoning: (
      #|INVARIANT (Polynomial hash):
      #|hash(s[0..i)) = Σ(s[j] * base^(i-1-j)) mod modulus
      #|
      #|This is Horner's method for polynomial evaluation.
      #|Each character contributes to the hash weighted by its position.
      #|MAINTENANCE:
      #|Update ph/th with the next character and advance i.
      #|TERMINATION:
      #|At i == m, both initial hashes are computed.
    ),
  }
  let results : Array[Int] = []

  // Slide the pattern over text
  for i = 0, th = text_hash {
    if i > n - m {
      break results
    } else {
      // Check if hashes match
      if th == pattern_hash {
        // Verify actual match (to handle hash collisions)
        let mut match_found = true
        for j = 0; j < m; j = j + 1 {
          if text[i + j] != pattern[j] {
            match_found = false
            break
          }
        } where {
          invariant: j >= 0 && j <= m,
          reasoning: (
            #|INVARIANT (Verification scan):
            #|After j comparisons, match_found is true iff the prefix
            #|text[i..i+j) equals pattern[0..j). Any mismatch sets it to false
            #|and we break early, so a true result means exact match.
            #|MAINTENANCE:
            #|Compare text[i+j] with pattern[j] and advance j.
            #|TERMINATION:
            #|At j == m, the entire pattern matches this window.
          ),
        }
        if match_found {
          results.push(i)
        }
      }

      // Compute hash for next window: remove text[i], add text[i+m]
      if i < n - m {
        let old_char = text[i].to_int()
        let new_char = text[i + m].to_int()
        // rolling_hash = (old_hash - old_char * h) * base + new_char
        let mut new_th = (th - old_char * h % modulus + modulus) % modulus
        new_th = (new_th * base + new_char) % modulus
        continue i + 1, new_th
      } else {
        continue i + 1, th
      }
    }
  } where {
    invariant: i >= 0 && i <= n - m + 1 && th >= 0 && th < modulus,
    reasoning: (
      #|INVARIANT (Rolling hash correctness):
      #|th = hash(text[i..i+m))
      #|
      #|ROLLING HASH UPDATE:
      #|To move from window [i..i+m) to [i+1..i+m+1):
      #|
      #|old_hash = text[i] * base^(m-1) + text[i+1] * base^(m-2) + ... + text[i+m-1]
      #|
      #|Remove contribution of text[i]:
      #|  temp = old_hash - text[i] * base^(m-1)
      #|       = text[i+1] * base^(m-2) + ... + text[i+m-1]
      #|
      #|Shift and add new character:
      #|  new_hash = temp * base + text[i+m]
      #|           = text[i+1] * base^(m-1) + ... + text[i+m-1] * base + text[i+m]
      #|           = hash(text[i+1..i+m+1))
      #|
      #|This gives O(1) hash update per position!
      #|
      #|WHY VERIFY MATCHES?
      #|Hash collisions: different strings can have same hash.
      #|With a good hash function and large modulus, probability of
      #|false positive is very low (≈ 1/modulus per comparison).
      #|
      #|Expected time: O(n + m) when few matches.
      #|Worst case: O(nm) if many hash collisions (rare with good params).
      #|
      #|FINGERPRINTING INSIGHT:
      #|The hash acts as a "fingerprint" of the window.
      #|Most non-matching windows have different fingerprints.
      #|Only matching fingerprints need expensive character-by-character check.
      #|MAINTENANCE:
      #|Advance i and update th to the next window hash.
      #|TERMINATION:
      #|At i == n - m + 1, all windows have been processed.
    ),
  }
}

///|
test "rabin_karp" {
  let text : Array[Char] = ['a', 'b', 'c', 'a', 'b', 'c', 'a', 'b', 'd']
  let pattern : Array[Char] = ['a', 'b', 'c']
  let matches = rabin_karp(text[:], pattern[:])
  assert_eq(matches, [0, 3])
  let text2 : Array[Char] = ['a', 'a', 'a', 'a', 'a']
  let pattern2 : Array[Char] = ['a', 'a']
  let matches2 = rabin_karp(text2[:], pattern2[:])
  assert_eq(matches2, [0, 1, 2, 3])
}

// ============================================================================
// Example S4: Longest Common Subsequence (Space-Optimized)
// Classic DP problem with careful invariant tracking
// ============================================================================

///|
/// LCS length using space-optimized DP (two rows).
#warnings("+missing_invariant+missing_reasoning")
pub fn lcs_length(s1 : ArrayView[Char], s2 : ArrayView[Char]) -> Int {
  let m = s1.length()
  let n = s2.length()
  guard m > 0 && n > 0 else { return 0 }
  let mut prev : Array[Int] = Array::make(n + 1, 0)
  let mut curr : Array[Int] = Array::make(n + 1, 0)
  for i = 1 {
    if i > m {
      break prev[n]
    } else {
      for j = 1 {
        if j > n {
          break
        } else {
          if s1[i - 1] == s2[j - 1] {
            curr[j] = prev[j - 1] + 1
          } else {
            curr[j] = if prev[j] > curr[j - 1] { prev[j] } else { curr[j - 1] }
          }
          continue j + 1
        }
      } where {
        invariant: j >= 1 && j <= n + 1,
        reasoning: (
          #|INVARIANT (Row update):
          #|After processing columns [1..j), curr[t] for t < j equals
          #|LCS(s1[0..i), s2[0..t)). The recurrence uses prev (row i-1)
          #|and curr (row i) so each update is based on already-computed
          #|subproblems.
          #|MAINTENANCE:
          #|Compute curr[j] from prev and curr[j-1], then advance j.
          #|TERMINATION:
          #|At j == n + 1, row i is fully computed in curr.
        ),
      }
      let tmp = prev
      prev = curr
      curr = tmp
      curr[0] = 0 // Reset first element for next row
      continue i + 1
    }
  } where {
    invariant: i >= 1 && i <= m + 1,
    reasoning: (
      #|INVARIANT (LCS DP):
      #|After processing row i, prev[j] = LCS(s1[0..i), s2[0..j)).
      #|
      #|LCS RECURRENCE:
      #|Let L[i][j] = length of LCS of s1[0..i) and s2[0..j).
      #|
      #|Base: L[0][j] = L[i][0] = 0 (empty sequence has no subsequence)
      #|
      #|Recurrence:
      #|  If s1[i-1] == s2[j-1]:
      #|    L[i][j] = L[i-1][j-1] + 1
      #|    (Extend LCS by matching this character)
      #|
      #|  Else:
      #|    L[i][j] = max(L[i-1][j], L[i][j-1])
      #|    (Best of: excluding s1[i-1], or excluding s2[j-1])
      #|
      #|PROOF OF RECURRENCE:
      #|
      #|Case s1[i-1] == s2[j-1]:
      #|  Any LCS of s1[0..i) and s2[0..j) either:
      #|  1. Doesn't use this match: length ≤ max(L[i-1][j], L[i][j-1])
      #|  2. Uses this match: length = L[i-1][j-1] + 1
      #|
      #|  Claim: L[i-1][j-1] + 1 ≥ max(L[i-1][j], L[i][j-1])
      #|
      #|  Proof: L[i-1][j] ≤ L[i-1][j-1] + 1 (adding one char can increase
      #|  LCS by at most 1). Similarly for L[i][j-1].
      #|  So the match case gives optimal. ✓
      #|
      #|Case s1[i-1] != s2[j-1]:
      #|  Any LCS cannot use both s1[i-1] and s2[j-1] (they're different
      #|  and a subsequence must maintain order).
      #|  So optimal is max of excluding one or the other. ✓
      #|
      #|SPACE OPTIMIZATION:
      #|L[i][j] only depends on L[i-1][j-1], L[i-1][j], L[i][j-1].
      #|We only need previous row and current row: O(n) space.
      #|MAINTENANCE:
      #|Fill curr from prev, then swap so prev holds row i for the next step.
      #|TERMINATION:
      #|At i == m + 1, prev[n] is the LCS length of the full strings.
    ),
  }
}

///|
test "lcs_length" {
  let s1 : Array[Char] = ['A', 'B', 'C', 'D', 'E', 'F']
  let s2 : Array[Char] = ['A', 'C', 'B', 'C', 'F']
  assert_eq(lcs_length(s1[:], s2[:]), 4) // "ABCF" or "ACDF" etc.
  let s3 : Array[Char] = ['A', 'B', 'C']
  let s4 : Array[Char] = ['D', 'E', 'F']
  assert_eq(lcs_length(s3[:], s4[:]), 0) // No common subsequence
  let s5 : Array[Char] = ['A', 'A', 'A']
  let s6 : Array[Char] = ['A', 'A']
  assert_eq(lcs_length(s5[:], s6[:]), 2)
}

// ============================================================================
// Example S5: Booth's Algorithm - Lexicographically Smallest Rotation
// Find the rotation of a string that is lexicographically smallest in O(n)
// ============================================================================

///|
/// Booth's algorithm: find starting index of lexicographically smallest rotation.
/// For string s of length n, there are n rotations. We find the smallest one.
#warnings("+missing_invariant+missing_reasoning")
fn booth_smallest_rotation(s : ArrayView[Char]) -> Int {
  let n = s.length()
  guard n > 0 else { return 0 }

  // Concatenate s with itself conceptually (use modular indexing)
  fn get(i : Int) -> Char {
    s[i % n]
  }

  // failure[i] similar to KMP failure function for doubled string
  let failure : Array[Int] = Array::make(2 * n, -1)
  for i = 1, k = 0 {
    if i >= 2 * n {
      break k
    } else {
      let j = failure[i - k - 1]

      // Find the longest suffix of s[k..i) that matches a prefix of s[k..)
      let new_j = for jj = j {
        if jj >= 0 && get(i) != get(k + jj + 1) {
          if get(i) < get(k + jj + 1) {
            // Current rotation starting at k is not optimal
            // Reset to start new candidate at position i - jj - 1 or i
            break -2 // Special marker: need to update k
          }
          continue failure[jj]
        } else {
          break jj
        }
      } where {
        invariant: jj >= -1,
        reasoning: (
          #|INVARIANT (Failure link walk):
          #|jj represents the length of the longest prefix of the current
          #|candidate rotation s[k..] that matches a suffix ending at i-1.
          #|We follow failure links to shorten this candidate when the next
          #|character mismatches, exactly like KMP.
          #|
          #|If we encounter a mismatch where get(i) < get(k + jj + 1),
          #|then the rotation starting at k is lexicographically larger than
          #|the rotation starting at i - jj - 1, so we signal a candidate change.
          #|MAINTENANCE:
          #|Follow failure[jj] on mismatch until a valid extension or -1.
          #|TERMINATION:
          #|At jj == -1 or a match, the longest extendable prefix is found.
        ),
      }
      if new_j == -2 {
        // Found a smaller rotation, restart from here
        continue i + 1, i - j - 1
      } else if get(i) != get(k + new_j + 1) {
        if get(i) < get(k + new_j + 1) {
          continue i + 1, i
        } else {
          failure[i - k] = -1
          continue i + 1, k
        }
      } else {
        failure[i - k] = new_j + 1
        continue i + 1, k
      }
    }
  } where {
    invariant: i >= 1 && i <= 2 * n && k >= 0 && k < n,
    reasoning: (
      #|INVARIANT (Booth's algorithm):
      #|k is the starting position of the current best candidate for
      #|the lexicographically smallest rotation.
      #|
      #|At each step, we either:
      #|1. Confirm k is still the best candidate (k unchanged)
      #|2. Find a better candidate at position i (k updated)
      #|
      #|KEY INSIGHT:
      #|Instead of comparing all n rotations (O(n²)), we use failure
      #|function ideas to skip impossible candidates.
      #|
      #|When comparing s[k..] with s[i..]:
      #|  - If s[k+j] < s[i+j] for some j: s[k..] is still best
      #|  - If s[k+j] > s[i+j] for some j: s[i..] becomes new best
      #|  - If equal for n characters: same rotation (handled by k < i)
      #|
      #|The failure function lets us skip redundant comparisons,
      #|giving O(n) total time.
      #|
      #|APPLICATIONS:
      #|  - Canonical form for cyclic strings (useful in DNA analysis)
      #|  - String equality under rotation
      #|  - Burrows-Wheeler Transform preprocessing
      #|MAINTENANCE:
      #|Advance i and update k when a smaller candidate is found.
      #|TERMINATION:
      #|At i == 2 * n, k is the smallest rotation start.
    ),
  }
}

///|
test "booth_smallest_rotation" {
  // "bca" rotations: "bca", "cab", "abc" -> smallest is "abc" starting at index 2
  let s1 : Array[Char] = ['b', 'c', 'a']
  assert_eq(booth_smallest_rotation(s1[:]), 2)

  // "abab" rotations: "abab", "baba", "abab", "baba" -> smallest is "abab" at 0 or 2
  let s2 : Array[Char] = ['a', 'b', 'a', 'b']
  let result = booth_smallest_rotation(s2[:])
  assert_true(result == 0 || result == 2)

  // Already smallest
  let s3 : Array[Char] = ['a', 'b', 'c']
  assert_eq(booth_smallest_rotation(s3[:]), 0)
}
