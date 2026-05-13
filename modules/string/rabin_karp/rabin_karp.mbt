// ============================================================================
// RABIN-KARP - Rolling Hash String Matching
// ============================================================================
//
// Rabin-Karp uses rolling hash to find pattern occurrences in O(n+m) average time.
// Hash is computed in O(1) per position using rolling technique.
//
// KEY INSIGHT: For hash H of s[i..i+m-1], hash of s[i+1..i+m] can be computed as:
// H' = (H - s[i] * base^(m-1)) * base + s[i+m]
//
// ROLLING HASH FORMULA:
// hash(s[l..r]) = s[l]*base^(r-l) + s[l+1]*base^(r-l-1) + ... + s[r]*base^0
//
// SPURIOUS HITS: Hash collision may cause false positives, verify with actual
// string comparison when hashes match.
//
// INVARIANTS:
// 1. Hash of pattern computed once
// 2. Text hash updated in O(1) per position
// 3. On hash match, verify actual strings
//
// TIME COMPLEXITY: O(n+m) average, O(nm) worst case
// SPACE COMPLEXITY: O(1)

///|
/// The base used for polynomial rolling hash computation.
///
/// Characters are mapped to values 1..26 (where `'a'` maps to 1) before
/// being multiplied by powers of this base, so the base must be at least 27
/// to avoid confusing distinct characters.  31 is the conventional choice for
/// lowercase ASCII alphabets.
const RK_BASE : Int64 = 31L

///|
/// The prime modulus used to keep intermediate hash values within Int64 range.
///
/// All hash arithmetic is performed modulo this value.  1_000_000_007 is a
/// standard Mersenne-like prime that makes collisions unlikely while fitting
/// comfortably in a 64-bit integer.
const RK_MOD : Int64 = 1000000007L

///|
/// Compute the polynomial rolling hash of `s[start..<start+len]`.
///
/// Each character `c` is mapped to `c.to_int() - 96` (so `'a'` -> 1,
/// `'b'` -> 2, ...) before being accumulated into the hash with base
/// `RK_BASE` and modulus `RK_MOD`.
///
/// Parameters:
/// - `s`     - the source string
/// - `start` - the index of the first character to include
/// - `len`   - the number of characters to hash
///
/// Returns the hash value in the range `[0, RK_MOD)`.
///
/// Time complexity: O(len)
fn compute_hash(s : String, start : Int, len : Int) -> Int64 {
  for offset in 0..<len; h = 0L {
    let c = s[start + offset].to_int() - 96 // 'a' = 97, so 'a' -> 1
    continue (h * RK_BASE + c.to_int64()) % RK_MOD
  } nobreak {
    h
  }
}

///|
/// Compute `base^exp mod m` using fast binary exponentiation (square-and-multiply).
///
/// Used internally to precompute the leading-digit weight `RK_BASE^(m-1)`,
/// which is needed when removing the leftmost character during a rolling
/// hash update.
///
/// Parameters:
/// - `base` - the base value
/// - `exp`  - the non-negative exponent
/// - `m`    - the modulus (must be positive)
///
/// Returns `base^exp mod m`.
///
/// Time complexity: O(log exp)
fn pow_mod(base : Int64, exp : Int, m : Int64) -> Int64 {
  for result = 1L, b = base % m, e = exp; e > 0; {
    let next_result = if e % 2 == 1 { result * b % m } else { result }
    continue next_result, b * b % m, e / 2
  } nobreak {
    result
  }
}

///|
/// Find all (possibly overlapping) starting positions of `pattern` in `text`
/// using the Rabin-Karp rolling hash algorithm.
///
/// The algorithm maintains a hash of the current length-`m` window in the
/// text.  After each comparison, the hash is updated in O(1) by removing the
/// contribution of the leftmost character and adding the next character:
///
/// ```
/// new_hash = (old_hash - text[i] * base^(m-1)) * base + text[i+m]
/// ```
///
/// When the window hash equals the pattern hash, the actual characters are
/// compared to rule out spurious hits caused by hash collisions.
///
/// Parameters:
/// - `text`    - the string to search in (length n)
/// - `pattern` - the string to search for (length m)
///
/// Returns an `Array[Int]` of 0-based starting indices at which `pattern`
/// begins in `text`.  Returns an empty array when `pattern` is empty or
/// longer than `text`.
///
/// Time complexity: O(n + m) expected, O(nm) worst case (all hashes collide)
/// Space complexity: O(1) working space, O(k) for the result (k = match count)
///
/// Example:
/// ```
/// // Overlapping occurrences are all reported
/// let positions = rabin_karp_search("abababab", "aba")
/// // positions == [0, 2, 4]
/// ```
pub fn rabin_karp_search(text : String, pattern : String) -> Array[Int] {
  let result : Array[Int] = []
  let n = text.length()
  let m = pattern.length()
  if m == 0 || m > n {
    return result
  }
  let pattern_hash = compute_hash(pattern, 0, m)
  let base_pow = pow_mod(RK_BASE, m - 1, RK_MOD) // base^(m-1)
  for i = 0, text_hash = compute_hash(text, 0, m); i <= n - m; {
    if text_hash == pattern_hash {
      // Verify match to handle collisions
      let match_found = for j in 0..<m {
        if text[i + j] != pattern[j] {
          break false
        }
      } nobreak {
        true
      }
      if match_found {
        result.push(i)
      }
    }

    // Roll hash to next position
    let next_hash = if i < n - m {
      let old_char = (text[i].to_int() - 96).to_int64()
      let new_char = (text[i + m].to_int() - 96).to_int64()
      ((text_hash - old_char * base_pow % RK_MOD + RK_MOD) * RK_BASE + new_char) %
      RK_MOD
    } else {
      text_hash
    }
    continue i + 1, next_hash
  } where {
    proof_invariant: i >= 0 && i <= n - m + 1,
    proof_reasoning: (
      #|INVARIANT (window scan):
      #|text_hash equals hash(text[i..i+m)), and all positions in [0, i) have
      #|been checked for matches.
      #|MAINTENANCE:
      #|Compare hashes (verify on collision), then roll the hash by removing
      #|the leftmost character and adding the next character.
      #|TERMINATION:
      #|At i = n - m + 1, all candidate positions have been processed.
    ),
  }
  result
}

///|
/// Count the number of (possibly overlapping) occurrences of `pattern` in
/// `text`.
///
/// This is a convenience wrapper around `rabin_karp_search` that discards
/// the position list and returns only the count.
///
/// Parameters:
/// - `text`    - the string to search in
/// - `pattern` - the string to search for
///
/// Returns the total number of occurrences, including overlapping ones.
/// Returns 0 when the pattern is empty or longer than the text.
///
/// Time complexity: O(n + m) expected
/// Space complexity: O(k) for the intermediate match list (k = match count)
///
/// Example:
/// ```
/// // Three overlapping "aa" windows in "aaaa"
/// let count = rabin_karp_count("aaaa", "aa")
/// // count == 3
/// ```
pub fn rabin_karp_count(text : String, pattern : String) -> Int {
  rabin_karp_search(text, pattern).length()
}

// ============================================================================
// MULTIPLE PATTERN SEARCH
// ============================================================================

///|
/// Search for multiple patterns simultaneously in `text` using Rabin-Karp.
///
/// Patterns are grouped by length so that each distinct length requires only
/// a single rolling hash pass over the text.  At each window position, the
/// window hash is compared against the hashes of every pattern of that length;
/// actual character comparison is performed only on hash matches to eliminate
/// false positives.
///
/// This approach is more practical than KMP or Aho-Corasick when:
/// - the set of patterns is not known in advance, or
/// - the patterns have many distinct lengths.
///
/// Parameters:
/// - `text`     - the string to search in (length n)
/// - `patterns` - the array of patterns to search for
///
/// Returns an `Array[(Int, Int)]` of `(pattern_index, position)` pairs, where
/// `pattern_index` is the 0-based index of the matched pattern in `patterns`
/// and `position` is the 0-based starting index in `text`.  Pairs are
/// reported in the order they are discovered (by length group, then by
/// position within each group).
///
/// Patterns that are empty or longer than `text` are silently skipped.
///
/// Time complexity: O(n * L + sum_m) expected, where L is the number of
/// distinct pattern lengths and sum_m is the total length of all patterns
/// Space complexity: O(P) for the hash table (P = number of patterns)
///
/// Example:
/// ```
/// let patterns = ["aba", "bab", "ab"]
/// let hits = rabin_karp_multi("ababab", patterns)
/// // hits == [(0, 0), (1, 1), (0, 2), (1, 3), (2, 0), (2, 2), (2, 4)]
/// ```
pub fn rabin_karp_multi(
  text : String,
  patterns : Array[String],
) -> Array[(Int, Int)] {
  // Returns (pattern_index, position) pairs
  let result : Array[(Int, Int)] = []
  let n = text.length()
  if patterns.length() == 0 {
    return result
  }

  // Group patterns by length
  let by_length : Map[Int, Array[(Int, Int64)]] = {} // length -> [(pattern_idx, hash)]
  for i, pat in patterns {
    let m = pat.length()
    if m > 0 && m <= n {
      let h = compute_hash(pat, 0, m)
      if !by_length.contains(m) {
        by_length[m] = []
      }
      by_length[m].push((i, h))
    }
  }

  // For each pattern length, do rolling hash
  for len, pattern_list in by_length {
    let base_pow = pow_mod(RK_BASE, len - 1, RK_MOD)
    for i = 0, text_hash = compute_hash(text, 0, len); i <= n - len; {
      // Check against all patterns of this length
      for j in 0..<pattern_list.length() {
        let (pat_idx, pat_hash) = pattern_list[j]
        if text_hash == pat_hash {
          // Verify
          let match_found = for k in 0..<len {
            if text[i + k] != patterns[pat_idx][k] {
              break false
            }
          } nobreak {
            true
          }
          if match_found {
            result.push((pat_idx, i))
          }
        }
      } where {
        proof_invariant: j >= 0 && j <= pattern_list.length(),
        proof_reasoning: (
          #|INVARIANT (check patterns):
          #|All patterns in pattern_list[0..j) have been checked against the
          #|current text window at position i.
          #|MAINTENANCE:
          #|Compare hashes and verify on matches to avoid collisions.
          #|TERMINATION:
          #|At j = pattern_list.length(), all patterns of this length are tested.
        ),
      }

      // Roll hash
      let next_hash = if i < n - len {
        let old_char = (text[i].to_int() - 96).to_int64()
        let new_char = (text[i + len].to_int() - 96).to_int64()
        (
          (text_hash - old_char * base_pow % RK_MOD + RK_MOD) * RK_BASE +
          new_char
        ) %
        RK_MOD
      } else {
        text_hash
      }
      continue i + 1, next_hash
    } where {
      proof_invariant: i >= 0 && i <= n - len + 1,
      proof_reasoning: (
        #|INVARIANT (window scan):
        #|text_hash corresponds to text[i..i+len), and all positions in [0, i)
        #|have been processed for this length.
        #|MAINTENANCE:
        #|Check all patterns of this length at position i, then roll the hash
        #|to advance the window by one.
        #|TERMINATION:
        #|At i = n - len + 1, all positions have been processed.
      ),
    }
  }
  result
}

// ============================================================================
// SUBSTRING HASH FOR COMPARISON
// ============================================================================

///|
/// Prefix hash table for O(1) substring hash queries on a fixed string.
///
/// `prefix_hash[i]` stores the hash of `s[0..<i]`, and `powers[i]` stores
/// `RK_BASE^i mod RK_MOD`.  Together they allow the hash of any substring
/// `s[l..<r]` to be computed in O(1) using the formula:
///
/// ```
/// hash(s[l..r)) = prefix_hash[r] - prefix_hash[l] * RK_BASE^(r-l)
/// ```
///
/// (with appropriate modular arithmetic to keep the result non-negative).
///
/// This structure is private; create one with `HashArray::new` and query it
/// with `get_hash` or `compare`.
priv struct HashArray {
  prefix_hash : Array[Int64]
  powers : Array[Int64]
  n : Int
}

///|
/// Build a `HashArray` from the string `s`.
///
/// Precomputes `prefix_hash` and `powers` arrays of length `n + 1` in O(n)
/// time, after which any substring hash can be retrieved in O(1).
///
/// Parameters:
/// - `s` - the string to preprocess
///
/// Returns a `HashArray` ready for `get_hash` and `compare` queries.
///
/// Time complexity: O(n)
/// Space complexity: O(n)
fn HashArray::HashArray(s : String) -> HashArray {
  let n = s.length()
  let prefix_hash = Array::make(n + 1, 0L)
  let powers = Array::make(n + 1, 1L)
  for i in 0..<n {
    let c = (s[i].to_int() - 96).to_int64()
    prefix_hash[i + 1] = (prefix_hash[i] * RK_BASE + c) % RK_MOD
    powers[i + 1] = powers[i] * RK_BASE % RK_MOD
  }
  { prefix_hash, powers, n }
}

///|
/// Return the hash of the substring `s[l..<r]` in O(1).
///
/// Uses the prefix hash formula:
///
/// ```
/// hash(s[l..r)) = (prefix_hash[r] - prefix_hash[l] * powers[r-l]) mod RK_MOD
/// ```
///
/// Returns `0L` for degenerate ranges (`l >= r`, `l < 0`, or `r > n`).
///
/// Parameters:
/// - `self` - the precomputed `HashArray`
/// - `l`    - start index (inclusive)
/// - `r`    - end index (exclusive)
///
/// Time complexity: O(1)
fn HashArray::get_hash(self : HashArray, l : Int, r : Int) -> Int64 {
  if l >= r || l < 0 || r > self.n {
    return 0L
  }
  let len = r - l
  (
    (self.prefix_hash[r] - self.prefix_hash[l] * self.powers[len]) % RK_MOD +
    RK_MOD
  ) %
  RK_MOD
}

///|
/// Return `true` when `s[l1..<r1]` and `s[l2..<r2]` have the same hash.
///
/// Both substrings must have the same length for the comparison to be
/// meaningful; the function returns `false` immediately when the lengths
/// differ.
///
/// Note: equal hashes imply equal substrings with high probability, but a
/// full character comparison is needed for a guaranteed-correct result.
///
/// Parameters:
/// - `self`     - the precomputed `HashArray`
/// - `l1`, `r1` - range of the first substring  `[l1, r1)`
/// - `l2`, `r2` - range of the second substring `[l2, r2)`
///
/// Time complexity: O(1)
fn HashArray::compare(
  self : HashArray,
  l1 : Int,
  r1 : Int,
  l2 : Int,
  r2 : Int,
) -> Bool {
  if r1 - l1 != r2 - l2 {
    return false
  }
  self.get_hash(l1, r1) == self.get_hash(l2, r2)
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "rabin_karp basic" {
  let matches = rabin_karp_search("abababab", "aba")
  debug_inspect(matches.length(), content="3")
  debug_inspect(matches[0], content="0")
  debug_inspect(matches[1], content="2")
  debug_inspect(matches[2], content="4")
}

///|
test "rabin_karp no match" {
  let matches = rabin_karp_search("abcdef", "xyz")
  debug_inspect(matches.length(), content="0")
}

///|
test "rabin_karp full match" {
  let matches = rabin_karp_search("abc", "abc")
  debug_inspect(matches.length(), content="1")
  debug_inspect(matches[0], content="0")
}

///|
test "rabin_karp count" {
  debug_inspect(rabin_karp_count("aaaa", "aa"), content="3")
  debug_inspect(rabin_karp_count("abcabc", "abc"), content="2")
}

///|
test "rabin_karp multi" {
  let text = "abcabcabc"
  let patterns : Array[String] = ["abc", "cab", "bc"]
  let matches = rabin_karp_multi(text, patterns)
  // Should find multiple matches
  debug_inspect(matches.length() >= 5, content="true")
}

///|
test "hash_array basic" {
  let ha = HashArray("abcabc")
  // Hash of "abc" at positions 0-3 and 3-6 should be same
  debug_inspect(ha.compare(0, 3, 3, 6), content="true")
  // Different substrings should differ
  debug_inspect(ha.compare(0, 2, 1, 3), content="false")
}

///|
test "hash_array get_hash" {
  let ha = HashArray("abcd")
  let h1 = ha.get_hash(0, 2) // "ab"
  let h2 = ha.get_hash(2, 4) // "cd"
  debug_inspect(h1 != h2, content="true")
}

///|
test "rabin_karp empty pattern" {
  let matches = rabin_karp_search("abc", "")
  debug_inspect(matches.length(), content="0")
}

///|
test "rabin_karp pattern longer" {
  let matches = rabin_karp_search("ab", "abcd")
  debug_inspect(matches.length(), content="0")
}

///|
test "pow_mod" {
  debug_inspect(pow_mod(2L, 10, 1000L), content="24") // 1024 % 1000
  debug_inspect(pow_mod(3L, 0, 100L), content="1")
  debug_inspect(pow_mod(5L, 3, 1000L), content="125")
}
