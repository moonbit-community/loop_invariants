// ============================================================================
// ROLLING HASH / POLYNOMIAL HASH - O(1) Substring Hash Queries
// ============================================================================
//
// Rolling Hash (Rabin-Karp style) enables O(1) substring hash computation
// after O(n) preprocessing, useful for string matching and comparison.
//
// KEY INSIGHT: Use polynomial hashing where:
// hash(s) = sum(s[i] * base^(n-1-i)) mod p
//
// With precomputed prefix hashes and powers of base, any substring hash
// can be computed in O(1).
//
// FORMULA:
// prefix_hash[i] = hash of s[0..i-1]
// hash(s[l..r]) = (prefix_hash[r+1] - prefix_hash[l] * base^(r-l+1)) mod p
//
// EXAMPLE for s = "abc" with base = 31:
// hash("abc") = 'a'*31^2 + 'b'*31 + 'c' = 97*961 + 98*31 + 99
//             = 93217 + 3038 + 99 = 96354
//
// prefix_hash[0] = 0
// prefix_hash[1] = 97 (just 'a')
// prefix_hash[2] = 97*31 + 98 = 3105
// prefix_hash[3] = 3105*31 + 99 = 96354
//
// hash("bc") = prefix_hash[3] - prefix_hash[1] * 31^2
//            = 96354 - 97*961 = 96354 - 93217 = 3137
// Verify: 'b'*31 + 'c' = 98*31 + 99 = 3137 ✓
//
// COLLISION HANDLING:
// - Use large prime modulus (e.g., 10^9 + 7)
// - For critical applications, use double hashing with different bases
//
// APPLICATIONS:
// - Pattern matching (Rabin-Karp)
// - Find longest common substring
// - Count distinct substrings
// - Lexicographic comparison of substrings
//
// TIME COMPLEXITY:
// - Preprocessing: O(n)
// - Query: O(1)
//
// SPACE COMPLEXITY: O(n)

///|
/// The base used in the polynomial hash formula.
///
/// Character values are treated as coefficients of a polynomial evaluated
/// at `HASH_BASE`.  A value of 31 works well for lowercase ASCII strings
/// because it is larger than the 26-letter alphabet and is a small prime.
const HASH_BASE : Int64 = 31L

///|
/// The modulus used to keep hash values bounded.
///
/// 10^9 + 7 is a well-known large prime.  Using a prime modulus makes
/// collisions unlikely for random strings (probability ~1/MOD per pair).
const HASH_MOD : Int64 = 1000000007L

///|
/// Precomputed polynomial hash table for a single string.
///
/// After construction, any substring hash can be retrieved in O(1) using
/// the prefix-hash subtraction formula:
///
/// ```
/// hash(s[l..r]) = (prefix_hash[r+1] - prefix_hash[l] * base^(r-l+1)) mod p
/// ```
///
/// Fields:
/// - `n`           : length of the original string
/// - `prefix_hash` : `prefix_hash[i]` = hash of `s[0..i-1]` (1-indexed end)
/// - `pow_base`    : `pow_base[i]` = `HASH_BASE^i mod HASH_MOD`
priv struct RollingHash {
  n : Int
  prefix_hash : Array[Int64] // prefix_hash[i] = hash of s[0..i-1]
  pow_base : Array[Int64] // pow_base[i] = base^i mod p
}

///|
/// Build a `RollingHash` from string `s` in O(n) time.
///
/// After this call, `prefix_hash` and `pow_base` are fully populated so
/// that `get_hash` and `substrings_equal` work in O(1).
fn RollingHash::RollingHash(s : String) -> RollingHash {
  let n = s.length()

  // Compute powers of base
  let pow_base = Array::make(n + 1, 1L)
  for i in 1..<=n {
    pow_base[i] = pow_base[i - 1] * HASH_BASE % HASH_MOD
  } where {
    proof_invariant: i >= 1 && i <= n + 1,
    proof_reasoning: (
      #|INVARIANT (powers table):
      #|pow_base contains correct base powers for indices [0, i). In
      #|particular, pow_base[0] = 1 and each pow_base[k] represents
      #|HASH_BASE^k mod HASH_MOD.
      #|MAINTENANCE:
      #|Compute pow_base[i] from pow_base[i - 1] * HASH_BASE mod HASH_MOD,
      #|extending the table by one exponent while preserving prior entries.
      #|TERMINATION:
      #|At i = n + 1, powers for 0..n are available for all substring lengths.
    ),
  }

  // Compute prefix hashes
  // INVARIANT: prefix_hash[i] = hash of s[0..i-1]
  let prefix_hash = Array::make(n + 1, 0L)
  for i in 0..<n {
    let char_val = (s[i].to_int() - 'a'.to_int() + 1).to_int64()
    prefix_hash[i + 1] = (prefix_hash[i] * HASH_BASE + char_val) % HASH_MOD
  } where {
    proof_invariant: i >= 0 && i <= n,
    proof_reasoning: (
      #|INVARIANT (prefix hashes):
      #|prefix_hash[k] equals hash(s[0..k)) for all k in [0, i]. This
      #|includes prefix_hash[0] = 0 and correctness up to length i.
      #|MAINTENANCE:
      #|Extend the polynomial hash by one character:
      #|prefix_hash[i+1] = prefix_hash[i] * base + char_val (mod HASH_MOD).
      #|TERMINATION:
      #|At i = n, prefix_hash holds hashes for every prefix length 0..n.
    ),
  }
  { n, prefix_hash, pow_base }
}

///|
/// Return the polynomial hash of the substring `s[l..r]` (inclusive,
/// 0-indexed), or `None` if the range is invalid.
///
/// Formula:
/// ```
/// hash = (prefix_hash[r+1] - prefix_hash[l] * base^(r-l+1)) mod p
/// ```
/// Adding `HASH_MOD` before the final `mod` avoids negative results from
/// the subtraction.
fn RollingHash::get_hash(self : RollingHash, l : Int, r : Int) -> Int64? {
  if l < 0 || r >= self.n || l > r {
    return None
  }
  let len = r - l + 1
  let hash = (
      self.prefix_hash[r + 1] -
      self.prefix_hash[l] * self.pow_base[len] % HASH_MOD +
      HASH_MOD
    ) %
    HASH_MOD
  Some(hash)
}

///|
/// Return `true` when substrings `s[l1..r1]` and `s[l2..r2]` (inclusive)
/// have the same polynomial hash.
///
/// Lengths are compared first; different-length substrings always return
/// `false`.  Equal hashes are a strong (but not guaranteed) indicator of
/// equal strings under a single modulus.
fn RollingHash::substrings_equal(
  self : RollingHash,
  l1 : Int,
  r1 : Int,
  l2 : Int,
  r2 : Int,
) -> Bool {
  if r1 - l1 != r2 - l2 {
    return false
  }
  match (self.get_hash(l1, r1), self.get_hash(l2, r2)) {
    (Some(h1), Some(h2)) => h1 == h2
    _ => false
  }
}

///|
/// Return the length of the string this `RollingHash` was built from.
fn RollingHash::length(self : RollingHash) -> Int {
  self.n
}

// ============================================================================
// DOUBLE HASHING (Reduced collision probability)
// ============================================================================

///|
/// Secondary base for the double-hashing scheme.
///
/// Chosen to be different from `HASH_BASE` (31) so that the two hash
/// functions are independent.
const HASH_BASE2 : Int64 = 37L

///|
/// Secondary modulus for the double-hashing scheme.
///
/// 10^9 + 9 is another large prime.  With two independent hashes the
/// collision probability drops to approximately 1/(MOD1 * MOD2).
const HASH_MOD2 : Int64 = 1000000009L

///|
/// Precomputed pair of independent polynomial hash tables for a string.
///
/// Using two separate (base, modulus) pairs makes accidental collisions
/// astronomically unlikely.  The combined hash of a substring is the
/// pair `(hash1, hash2)` — two substrings are equal when both components
/// match.
///
/// Fields mirror those of `RollingHash` but are duplicated for each
/// hashing scheme:
/// - `prefix_hash1 / pow_base1` : scheme (HASH_BASE,  HASH_MOD)
/// - `prefix_hash2 / pow_base2` : scheme (HASH_BASE2, HASH_MOD2)
priv struct DoubleRollingHash {
  n : Int
  prefix_hash1 : Array[Int64]
  prefix_hash2 : Array[Int64]
  pow_base1 : Array[Int64]
  pow_base2 : Array[Int64]
}

///|
/// Build a `DoubleRollingHash` from string `s` in O(n) time.
///
/// Both power tables and both prefix-hash arrays are populated in a single
/// pass, giving O(1) `get_hash` queries thereafter.
fn DoubleRollingHash::DoubleRollingHash(s : String) -> DoubleRollingHash {
  let n = s.length()
  let pow_base1 = Array::make(n + 1, 1L)
  let pow_base2 = Array::make(n + 1, 1L)
  for i in 1..<=n {
    pow_base1[i] = pow_base1[i - 1] * HASH_BASE % HASH_MOD
    pow_base2[i] = pow_base2[i - 1] * HASH_BASE2 % HASH_MOD2
  } where {
    proof_invariant: i >= 1 && i <= n + 1,
    proof_reasoning: (
      #|INVARIANT (dual powers):
      #|pow_base1 and pow_base2 are correct for all exponents in [0, i),
      #|with pow_base1[0] = pow_base2[0] = 1 and each table storing its
      #|respective base^k modulo its prime.
      #|MAINTENANCE:
      #|Extend both tables by one exponent using their previous entry and
      #|the corresponding base/mod pair.
      #|TERMINATION:
      #|At i = n + 1, both power tables are filled for all lengths 0..n.
    ),
  }
  let prefix_hash1 = Array::make(n + 1, 0L)
  let prefix_hash2 = Array::make(n + 1, 0L)
  for i in 0..<n {
    let char_val = (s[i].to_int() - 'a'.to_int() + 1).to_int64()
    prefix_hash1[i + 1] = (prefix_hash1[i] * HASH_BASE + char_val) % HASH_MOD
    prefix_hash2[i + 1] = (prefix_hash2[i] * HASH_BASE2 + char_val) % HASH_MOD2
  } where {
    proof_invariant: i >= 0 && i <= n,
    proof_reasoning: (
      #|INVARIANT (dual prefix hashes):
      #|prefix_hash1/2 are correct for all prefix lengths in [0, i]. This
      #|means both hashing schemes agree with their definitions up to i.
      #|MAINTENANCE:
      #|Extend both hashes by the next character using their base/mod pairs.
      #|TERMINATION:
      #|At i = n, both prefix hash arrays cover every prefix length 0..n.
    ),
  }
  { n, prefix_hash1, prefix_hash2, pow_base1, pow_base2 }
}

///|
/// Return the double hash `(hash1, hash2)` of substring `s[l..r]`
/// (inclusive, 0-indexed), or `None` if the range is invalid.
///
/// Both components are computed independently using the same subtraction
/// formula as `RollingHash::get_hash` but with their own base and modulus.
fn DoubleRollingHash::get_hash(
  self : DoubleRollingHash,
  l : Int,
  r : Int,
) -> (Int64, Int64)? {
  if l < 0 || r >= self.n || l > r {
    return None
  }
  let len = r - l + 1
  let h1 = (
      self.prefix_hash1[r + 1] -
      self.prefix_hash1[l] * self.pow_base1[len] % HASH_MOD +
      HASH_MOD
    ) %
    HASH_MOD
  let h2 = (
      self.prefix_hash2[r + 1] -
      self.prefix_hash2[l] * self.pow_base2[len] % HASH_MOD2 +
      HASH_MOD2
    ) %
    HASH_MOD2
  Some((h1, h2))
}

///|
/// Return `true` when substrings `s[l1..r1]` and `s[l2..r2]` (inclusive)
/// have equal double hashes.
///
/// Both hash components must agree for the function to return `true`,
/// making false positives extremely rare in practice.
fn DoubleRollingHash::substrings_equal(
  self : DoubleRollingHash,
  l1 : Int,
  r1 : Int,
  l2 : Int,
  r2 : Int,
) -> Bool {
  if r1 - l1 != r2 - l2 {
    return false
  }
  match (self.get_hash(l1, r1), self.get_hash(l2, r2)) {
    (Some((h1a, h1b)), Some((h2a, h2b))) => h1a == h2a && h1b == h2b
    _ => false
  }
}

///|
/// Return the length of the string this `DoubleRollingHash` was built from.
fn DoubleRollingHash::length(self : DoubleRollingHash) -> Int {
  self.n
}

// ============================================================================
// PATTERN MATCHING (Rabin-Karp)
// ============================================================================

///|
/// Find all start positions where `pattern` appears in `text`, using the
/// Rabin-Karp rolling-hash algorithm.
///
/// Returns a sorted array of 0-based indices.  Overlapping occurrences are
/// included.  Matches are confirmed by a character-by-character scan to
/// eliminate false positives caused by hash collisions.
///
/// Time complexity: O(n + m) expected, O(n * m) worst case (collision storm).
/// Space complexity: O(n) for the prefix-hash table.
///
/// Example:
/// ```
/// find_pattern_rabin_karp("aabcaabxaab", "aab")
/// // => [0, 4, 8]
/// ```
pub fn find_pattern_rabin_karp(text : String, pattern : String) -> Array[Int] {
  let result : Array[Int] = []
  let n = text.length()
  let m = pattern.length()
  if m == 0 || m > n {
    return result
  }
  let text_hash = RollingHash(text)
  let pattern_hash = RollingHash(pattern)

  // Get pattern hash
  let target = match pattern_hash.get_hash(0, m - 1) {
    Some(h) => h
    None => return result
  }

  // Check each position
  // INVARIANT: Check all positions where pattern could start
  for i in 0..<=(n - m) {
    match text_hash.get_hash(i, i + m - 1) {
      Some(h) =>
        if h == target {
          // Verify match to handle collisions
          let matches = for j = 0, matches = true; j < m && matches; {
            continue j + 1, text[i + j] == pattern[j]
          } nobreak {
            matches
          } where {
            proof_invariant: j >= 0 && j <= m,
            proof_reasoning: (
              #|INVARIANT (verification scan):
              #|If matches is true, then text[i..i+j) equals pattern[0..j).
              #|If a mismatch is found, matches becomes false and stays false.
              #|MAINTENANCE:
              #|Compare the next character; on mismatch, record failure by
              #|clearing matches.
              #|TERMINATION:
              #|When j = m or matches is false, matches is true iff the full
              #|pattern matches at position i.
            ),
          }
          if matches {
            result.push(i)
          }
        }
      None => ()
    }
  } where {
    proof_invariant: i >= 0 && i <= n - m + 1,
    proof_reasoning: (
      #|INVARIANT (window scan):
      #|All start positions in [0, i) have been checked, and result contains
      #|exactly those indices where pattern matches the text (after verifying
      #|any hash collisions).
      #|MAINTENANCE:
      #|At position i, compare hashes; on a hit, verify characters and push i.
      #|TERMINATION:
      #|When i = n - m + 1, every valid start position has been processed.
    ),
  }
  result
}

///|
/// Count the number of (possibly overlapping) occurrences of `pattern` in
/// `text`.
///
/// Delegates to `find_pattern_rabin_karp` and returns the length of the
/// result array.
///
/// Example:
/// ```
/// count_pattern_rabin_karp("mississippi", "issi")
/// // => 2
/// ```
pub fn count_pattern_rabin_karp(text : String, pattern : String) -> Int {
  find_pattern_rabin_karp(text, pattern).length()
}

// ============================================================================
// LONGEST COMMON SUBSTRING
// ============================================================================

///|
/// Return the length of the longest substring shared by `s1` and `s2`.
///
/// Uses binary search on the candidate length combined with double-hashing
/// to check feasibility in O((n + m) log(min(n, m))) time.
///
/// Example:
/// ```
/// longest_common_substring("abcdef", "bcfghi")
/// // => 2  ("bc")
/// ```
fn longest_common_substring(s1 : String, s2 : String) -> Int {
  let n1 = s1.length()
  let n2 = s2.length()
  if n1 == 0 || n2 == 0 {
    return 0
  }
  let hash1 = DoubleRollingHash(s1)
  let hash2 = DoubleRollingHash(s2)

  // Binary search on length
  // INVARIANT: if length L works, so does any length < L
  fn check_length(
    len : Int,
    hash1 : DoubleRollingHash,
    hash2 : DoubleRollingHash,
    n1 : Int,
    n2 : Int,
  ) -> Bool {
    // Collect all hashes of length `len` from s1
    let hashes : Array[(Int64, Int64)] = []
    for i in 0..<=(n1 - len) {
      match hash1.get_hash(i, i + len - 1) {
        Some(h) => hashes.push(h)
        None => ()
      }
    } where {
      proof_invariant: i >= 0 && i <= n1 - len + 1,
      proof_reasoning: (
        #|INVARIANT (collect s1 hashes):
        #|hashes contains the hash of every length-len substring of s1 with
        #|start index in [0, i). No start in that range is skipped.
        #|MAINTENANCE:
        #|Compute the hash for start i and append it to hashes.
        #|TERMINATION:
        #|At i = n1 - len + 1, all length-len substrings of s1 are collected.
      ),
    }

    // Sort for binary search
    hashes.sort_by((a, b) => {
      let (a1, a2) = a
      let (b1, b2) = b
      if a1 != b1 {
        if a1 < b1 {
          -1
        } else {
          1
        }
      } else if a2 != b2 {
        if a2 < b2 {
          -1
        } else {
          1
        }
      } else {
        0
      }
    })

    // Check if any hash from s2 exists in s1's hashes
    for i in 0..<=(n2 - len) {
      match hash2.get_hash(i, i + len - 1) {
        Some(h) => {
          // Binary search
          let (h1, h2) = h
          let found = for lo = 0, hi = hashes.length() - 1 {
            if lo <= hi {
              let mid = (lo + hi) / 2
              let (m1, m2) = hashes[mid]
              if m1 == h1 && m2 == h2 {
                break true
              } else if m1 < h1 || (m1 == h1 && m2 < h2) {
                continue mid + 1, hi
              } else {
                continue lo, mid - 1
              }
            } else {
              break false
            }
          }
          if found {
            return true
          }
        }
        None => ()
      }
    } where {
      proof_invariant: i >= 0 && i <= n2 - len + 1,
      proof_reasoning: (
        #|INVARIANT (scan s2 hashes):
        #|No substring of s2 with start in [0, i) matches any hash from s1.
        #|MAINTENANCE:
        #|For start i, compute its hash and binary search the sorted hashes;
        #|return true immediately if a match exists.
        #|TERMINATION:
        #|At i = n2 - len + 1, all starts are checked and no match exists.
      ),
    }
    false
  }

  // Binary search for answer
  let max_len = if n1 < n2 { n1 } else { n2 }
  for lo = 0, hi = max_len, result = 0; lo <= hi; {
    let mid = (lo + hi) / 2
    if check_length(mid, hash1, hash2, n1, n2) {
      continue mid + 1, hi, mid
    } else {
      continue lo, mid - 1, result
    }
  } nobreak {
    result
  } where {
    proof_invariant: lo >= 0 && hi <= max_len && result >= 0,
    proof_reasoning: (
      #|INVARIANT (length search):
      #|All lengths <= result are known to be feasible, and any feasible
      #|length must lie in the current search window [lo, hi].
      #|MAINTENANCE:
      #|If mid is feasible, move lo upward and promote result; otherwise,
      #|shrink hi. Monotonicity of check_length preserves correctness.
      #|TERMINATION:
      #|When lo > hi, result is the maximum feasible length.
    ),
  }
}

// ============================================================================
// COUNT DISTINCT SUBSTRINGS
// ============================================================================

///|
/// Return the number of distinct substrings of `s`.
///
/// Collects double hashes for every substring, sorts them, then counts
/// unique pairs.  Time complexity is O(n^2 log n); suitable for moderate
/// string lengths.
///
/// Example:
/// ```
/// count_distinct_substrings("abc")
/// // => 6  ("a", "b", "c", "ab", "bc", "abc")
/// ```
fn count_distinct_substrings(s : String) -> Int {
  let n = s.length()
  if n == 0 {
    return 0
  }
  let hash = DoubleRollingHash(s)
  let seen : Array[(Int64, Int64)] = []

  // Collect all substring hashes
  for len in 1..<=n {
    for i in 0..<=(n - len) {
      match hash.get_hash(i, i + len - 1) {
        Some(h) => seen.push(h)
        None => ()
      }
    } where {
      proof_invariant: i >= 0 && i <= n - len + 1,
      proof_reasoning: (
        #|INVARIANT (fixed length):
        #|seen holds hashes for all length-len substrings starting in [0, i).
        #|MAINTENANCE:
        #|Append the hash for the substring starting at i.
        #|TERMINATION:
        #|At i = n - len + 1, all length-len substrings are collected.
      ),
    }
  } where {
    proof_invariant: len >= 1 && len <= n + 1,
    proof_reasoning: (
      #|INVARIANT (all lengths):
      #|seen contains hashes for all substring lengths in [1, len). Duplicates
      #|are allowed since different substrings may collide in the hash.
      #|MAINTENANCE:
      #|Collect all hashes of the current length len.
      #|TERMINATION:
      #|At len = n + 1, seen holds hashes for every substring length.
    ),
  }

  // Sort and count unique
  seen.sort_by((a, b) => {
    let (a1, a2) = a
    let (b1, b2) = b
    if a1 != b1 {
      if a1 < b1 {
        -1
      } else {
        1
      }
    } else if a2 != b2 {
      if a2 < b2 {
        -1
      } else {
        1
      }
    } else {
      0
    }
  })

  // Count distinct
  if seen.length() == 0 {
    return 0
  }
  for i = 1, count = 1; i < seen.length(); i = i + 1 {
    let (prev1, prev2) = seen[i - 1]
    let (curr1, curr2) = seen[i]
    if prev1 != curr1 || prev2 != curr2 {
      continue i + 1, count + 1
    } else {
      continue i + 1, count
    }
  } nobreak {
    count
  } where {
    proof_invariant: i >= 1 && i <= seen.length() && count >= 1,
    proof_reasoning: (
      #|INVARIANT (distinct count):
      #|Because seen is sorted, equal hashes are contiguous. count equals the
      #|number of distinct hash values in seen[0..i).
      #|MAINTENANCE:
      #|If the current hash differs from the previous one, increment count.
      #|TERMINATION:
      #|At i = seen.length(), count is the number of distinct substrings.
    ),
  }
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "rolling hash basic" {
  let rh = RollingHash("abcabc")

  // Same substrings should have same hash
  let h1 = rh.get_hash(0, 2) // "abc"
  let h2 = rh.get_hash(3, 5) // "abc"
  inspect(h1 is Some(_), content="true")
  inspect(h1 == h2, content="true")
}

///|
test "rolling hash different" {
  let rh = RollingHash("abcdef")
  let h1 = rh.get_hash(0, 2) // "abc"
  let h2 = rh.get_hash(3, 5) // "def"
  inspect(h1 != h2, content="true")
}

///|
test "rolling hash substrings equal" {
  let rh = RollingHash("abcabcabc")
  inspect(rh.substrings_equal(0, 2, 3, 5), content="true") // "abc" == "abc"
  inspect(rh.substrings_equal(0, 2, 6, 8), content="true") // "abc" == "abc"
  inspect(rh.substrings_equal(0, 2, 1, 3), content="false") // "abc" != "bca"
}

///|
test "rolling hash invalid range" {
  let rh = RollingHash("abc")
  debug_inspect(rh.get_hash(-1, 0), content="None")
  debug_inspect(rh.get_hash(0, 10), content="None")
  debug_inspect(rh.get_hash(2, 1), content="None")
}

///|
test "double rolling hash" {
  let drh = DoubleRollingHash("abcabc")
  let h1 = drh.get_hash(0, 2)
  let h2 = drh.get_hash(3, 5)
  inspect(h1 == h2, content="true")
  inspect(drh.substrings_equal(0, 2, 3, 5), content="true")
}

///|
test "rabin karp find pattern" {
  let matches = find_pattern_rabin_karp("aabcaabxaab", "aab")
  inspect(matches.length(), content="3")
  inspect(matches[0], content="0")
  inspect(matches[1], content="4")
  inspect(matches[2], content="8")
}

///|
test "rabin karp no match" {
  let matches = find_pattern_rabin_karp("abcdef", "xyz")
  inspect(matches.length(), content="0")
}

///|
test "rabin karp full match" {
  let matches = find_pattern_rabin_karp("abc", "abc")
  inspect(matches.length(), content="1")
  inspect(matches[0], content="0")
}

///|
test "rabin karp overlapping" {
  let matches = find_pattern_rabin_karp("aaaa", "aa")
  inspect(matches.length(), content="3")
  inspect(matches[0], content="0")
  inspect(matches[1], content="1")
  inspect(matches[2], content="2")
}

///|
test "count pattern" {
  inspect(count_pattern_rabin_karp("mississippi", "issi"), content="2")
  inspect(count_pattern_rabin_karp("abcabc", "abc"), content="2")
  inspect(count_pattern_rabin_karp("hello", "xyz"), content="0")
}

///|
test "longest common substring" {
  inspect(longest_common_substring("abcdef", "bcfghi"), content="2") // "bc"
  inspect(longest_common_substring("abcabc", "abc"), content="3") // "abc"
  inspect(longest_common_substring("xyz", "abc"), content="0") // none
}

///|
test "longest common substring same" {
  inspect(longest_common_substring("abc", "abc"), content="3")
}

///|
test "count distinct substrings" {
  // "abc" has: "a", "b", "c", "ab", "bc", "abc" = 6 distinct
  inspect(count_distinct_substrings("abc"), content="6")

  // "aaa" has: "a", "aa", "aaa" = 3 distinct
  inspect(count_distinct_substrings("aaa"), content="3")
}

///|
test "count distinct substrings abab" {
  // "abab": "a"(x2), "b"(x2), "ab"(x2), "ba", "aba", "bab", "abab"
  // Distinct: "a", "b", "ab", "ba", "aba", "bab", "abab" = 7
  inspect(count_distinct_substrings("abab"), content="7")
}

///|
test "rolling hash empty" {
  let rh = RollingHash("")
  inspect(rh.length(), content="0")
  debug_inspect(rh.get_hash(0, 0), content="None")
}

///|
test "rolling hash single" {
  let rh = RollingHash("a")
  inspect(rh.length(), content="1")
  inspect(rh.get_hash(0, 0) is Some(_), content="true")
}

///|
test "double hash length" {
  let drh = DoubleRollingHash("hello")
  inspect(drh.length(), content="5")
}

///|
test "pattern empty" {
  let matches = find_pattern_rabin_karp("abc", "")
  inspect(matches.length(), content="0")
}

///|
test "pattern longer than text" {
  let matches = find_pattern_rabin_karp("ab", "abcd")
  inspect(matches.length(), content="0")
}
