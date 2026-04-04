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
const RK_BASE : Int64 = 31L

///|
const RK_MOD : Int64 = 1000000007L

///|
/// Compute hash of string
fn compute_hash(s : String, start : Int, len : Int) -> Int64 {
  for offset in 0..<len; h = 0L {
    let c = s[start + offset].to_int() - 96 // 'a' = 97, so 'a' -> 1
    continue (h * RK_BASE + c.to_int64()) % RK_MOD
  } nobreak {
    h
  }
}

///|
/// Compute base^exp mod m
fn pow_mod(base : Int64, exp : Int, m : Int64) -> Int64 {
  for result = 1L, b = base % m, e = exp; e > 0; {
    let next_result = if e % 2 == 1 { result * b % m } else { result }
    continue next_result, b * b % m, e / 2
  } nobreak {
    result
  }
}

///|
/// Find all occurrences of pattern in text using Rabin-Karp
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
    invariant: i >= 0 && i <= n - m + 1,
    reasoning: (
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
/// Count pattern occurrences
pub fn rabin_karp_count(text : String, pattern : String) -> Int {
  rabin_karp_search(text, pattern).length()
}

// ============================================================================
// MULTIPLE PATTERN SEARCH
// ============================================================================

///|
/// Search for multiple patterns simultaneously
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
        invariant: j >= 0 && j <= pattern_list.length(),
        reasoning: (
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
      invariant: i >= 0 && i <= n - len + 1,
      reasoning: (
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
/// Precompute prefix hashes for O(1) substring hash queries
priv struct HashArray {
  prefix_hash : Array[Int64]
  powers : Array[Int64]
  n : Int
}

///|
fn HashArray::new(s : String) -> HashArray {
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
/// Get hash of substring s[l..r) in O(1)
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
/// Compare two substrings using hashes
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
  inspect(matches.length(), content="3")
  inspect(matches[0], content="0")
  inspect(matches[1], content="2")
  inspect(matches[2], content="4")
}

///|
test "rabin_karp no match" {
  let matches = rabin_karp_search("abcdef", "xyz")
  inspect(matches.length(), content="0")
}

///|
test "rabin_karp full match" {
  let matches = rabin_karp_search("abc", "abc")
  inspect(matches.length(), content="1")
  inspect(matches[0], content="0")
}

///|
test "rabin_karp count" {
  inspect(rabin_karp_count("aaaa", "aa"), content="3")
  inspect(rabin_karp_count("abcabc", "abc"), content="2")
}

///|
test "rabin_karp multi" {
  let text = "abcabcabc"
  let patterns : Array[String] = ["abc", "cab", "bc"]
  let matches = rabin_karp_multi(text, patterns)
  // Should find multiple matches
  inspect(matches.length() >= 5, content="true")
}

///|
test "hash_array basic" {
  let ha = HashArray::new("abcabc")
  // Hash of "abc" at positions 0-3 and 3-6 should be same
  inspect(ha.compare(0, 3, 3, 6), content="true")
  // Different substrings should differ
  inspect(ha.compare(0, 2, 1, 3), content="false")
}

///|
test "hash_array get_hash" {
  let ha = HashArray::new("abcd")
  let h1 = ha.get_hash(0, 2) // "ab"
  let h2 = ha.get_hash(2, 4) // "cd"
  inspect(h1 != h2, content="true")
}

///|
test "rabin_karp empty pattern" {
  let matches = rabin_karp_search("abc", "")
  inspect(matches.length(), content="0")
}

///|
test "rabin_karp pattern longer" {
  let matches = rabin_karp_search("ab", "abcd")
  inspect(matches.length(), content="0")
}

///|
test "pow_mod" {
  inspect(pow_mod(2L, 10, 1000L), content="24") // 1024 % 1000
  inspect(pow_mod(3L, 0, 100L), content="1")
  inspect(pow_mod(5L, 3, 1000L), content="125")
}
