// ============================================================================
// STRING HASHING - Polynomial Rolling Hash
// ============================================================================
//
// String hashing enables O(1) substring comparison after O(n) preprocessing.
// Uses polynomial rolling hash: H(s) = s[0]*base^(n-1) + s[1]*base^(n-2) + ... + s[n-1]
//
// KEY INSIGHT: Prefix hashes allow O(1) extraction of any substring hash:
// H(s[l..r]) = (prefix[r+1] - prefix[l] * base^(r-l+1)) mod p
//
// COLLISION HANDLING:
// - Single hash: 1/p collision probability
// - Double hash: 1/(p1*p2) collision probability
// - Use large primes for better distribution
//
// INVARIANTS:
// 1. prefix[i] = hash of s[0..i-1]
// 2. powers[i] = base^i mod p
// 3. Substring hash is computed using prefix difference
//
// TIME COMPLEXITY: O(n) preprocessing, O(1) per query
// SPACE COMPLEXITY: O(n)

///|
const HASH_BASE : Int64 = 31L

///|
const HASH_MOD : Int64 = 1000000007L

///|
priv struct StringHash {
  prefix : Array[Int64]
  powers : Array[Int64]
  n : Int
}

///|
fn StringHash::new(s : String) -> StringHash {
  let n = s.length()
  let prefix = Array::make(n + 1, 0L)
  let powers = Array::make(n + 1, 1L)
  for i = 0; i < n; i = i + 1 {
    let c = (s[i].to_int() - 96).to_int64() // 'a' = 97, so 'a' -> 1
    prefix[i + 1] = (prefix[i] * HASH_BASE + c) % HASH_MOD
    powers[i + 1] = powers[i] * HASH_BASE % HASH_MOD
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (prefix tables):
      #|prefix and powers are correct for all prefix lengths in [0, i].
      #|MAINTENANCE:
      #|Extend the prefix hash and power tables with s[i].
      #|TERMINATION:
      #|At i = n, all prefix hashes and base powers are computed.
    ),
  }
  { prefix, powers, n }
}

///|
/// Get hash of substring s[l..r) (0-indexed, exclusive end)
fn StringHash::get_hash(self : StringHash, l : Int, r : Int) -> Int64 {
  if l >= r || l < 0 || r > self.n {
    return 0L
  }
  let len = r - l
  ((self.prefix[r] - self.prefix[l] * self.powers[len]) % HASH_MOD + HASH_MOD) %
  HASH_MOD
}

///|
/// Compare two substrings
fn StringHash::compare(
  self : StringHash,
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

///|
/// Get length of string
fn StringHash::length(self : StringHash) -> Int {
  self.n
}

// ============================================================================
// DOUBLE HASH - For higher collision resistance
// ============================================================================

///|
const HASH_BASE2 : Int64 = 37L

///|
const HASH_MOD2 : Int64 = 1000000009L

///|
priv struct DoubleHash {
  prefix1 : Array[Int64]
  prefix2 : Array[Int64]
  powers1 : Array[Int64]
  powers2 : Array[Int64]
  n : Int
}

///|
fn DoubleHash::new(s : String) -> DoubleHash {
  let n = s.length()
  let prefix1 = Array::make(n + 1, 0L)
  let prefix2 = Array::make(n + 1, 0L)
  let powers1 = Array::make(n + 1, 1L)
  let powers2 = Array::make(n + 1, 1L)
  for i = 0; i < n; i = i + 1 {
    let c = (s[i].to_int() - 96).to_int64()
    prefix1[i + 1] = (prefix1[i] * HASH_BASE + c) % HASH_MOD
    prefix2[i + 1] = (prefix2[i] * HASH_BASE2 + c) % HASH_MOD2
    powers1[i + 1] = powers1[i] * HASH_BASE % HASH_MOD
    powers2[i + 1] = powers2[i] * HASH_BASE2 % HASH_MOD2
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (double prefix tables):
      #|prefix1/2 and powers1/2 are correct for all prefix lengths in [0, i].
      #|MAINTENANCE:
      #|Extend both hashes and power tables with s[i] using their bases/mods.
      #|TERMINATION:
      #|At i = n, both prefix hashes and power tables are computed.
    ),
  }
  { prefix1, prefix2, powers1, powers2, n }
}

///|
/// Get double hash of substring s[l..r)
fn DoubleHash::get_hash(self : DoubleHash, l : Int, r : Int) -> (Int64, Int64) {
  if l >= r || l < 0 || r > self.n {
    return (0L, 0L)
  }
  let len = r - l
  let h1 = (
      (self.prefix1[r] - self.prefix1[l] * self.powers1[len]) % HASH_MOD +
      HASH_MOD
    ) %
    HASH_MOD
  let h2 = (
      (self.prefix2[r] - self.prefix2[l] * self.powers2[len]) % HASH_MOD2 +
      HASH_MOD2
    ) %
    HASH_MOD2
  (h1, h2)
}

///|
/// Compare two substrings using double hash
fn DoubleHash::compare(
  self : DoubleHash,
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
// LONGEST COMMON PREFIX using Binary Search + Hashing
// ============================================================================

///|
/// Find longest common prefix length between substrings starting at i and j
fn StringHash::lcp(self : StringHash, i : Int, j : Int) -> Int {
  let max_len = if self.n - i < self.n - j { self.n - i } else { self.n - j }
  let mut lo = 0
  let mut hi = max_len
  while lo < hi {
    let mid = (lo + hi + 1) / 2
    if self.get_hash(i, i + mid) == self.get_hash(j, j + mid) {
      lo = mid
    } else {
      hi = mid - 1
    }
  }
  lo
}

// ============================================================================
// HASH-BASED PATTERN MATCHING
// ============================================================================

///|
/// Find all occurrences of pattern in text
fn hash_pattern_match(text : String, pattern : String) -> Array[Int] {
  let result : Array[Int] = []
  let n = text.length()
  let m = pattern.length()
  if m == 0 || m > n {
    return result
  }
  let text_hash = StringHash::new(text)
  let pattern_hash = StringHash::new(pattern)
  let target = pattern_hash.get_hash(0, m)
  for i = 0; i <= n - m; i = i + 1 {
    if text_hash.get_hash(i, i + m) == target {
      result.push(i)
    }
  } where {
    invariant: i >= 0 && i <= n - m + 1,
    reasoning: (
      #|INVARIANT (pattern scan):
      #|All positions in [0, i) have been checked against the target hash.
      #|MAINTENANCE:
      #|Compare the hash at position i and record a match if it equals target.
      #|TERMINATION:
      #|At i = n - m + 1, all candidate positions are processed.
    ),
  }
  result
}

///|
/// Count distinct substrings of length k
fn count_distinct_substrings(s : String, k : Int) -> Int {
  let n = s.length()
  if k <= 0 || k > n {
    return 0
  }
  let hash = StringHash::new(s)
  let seen : Map[Int64, Bool] = {}
  for i = 0; i <= n - k; i = i + 1 {
    let h = hash.get_hash(i, i + k)
    seen[h] = true
  } where {
    invariant: i >= 0 && i <= n - k + 1,
    reasoning: (
      #|INVARIANT (distinct length-k):
      #|seen contains hashes for substrings starting in [0, i).
      #|MAINTENANCE:
      #|Insert the hash for the substring starting at i.
      #|TERMINATION:
      #|At i = n - k + 1, all length-k substrings are recorded.
    ),
  }
  seen.length()
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "string_hash basic" {
  let sh = StringHash::new("abcabc")
  // Hash of "abc" at positions 0-3 and 3-6 should be same
  inspect(sh.compare(0, 3, 3, 6), content="true")
  // Different substrings should differ
  inspect(sh.compare(0, 2, 1, 3), content="false")
}

///|
test "string_hash get_hash" {
  let sh = StringHash::new("abcd")
  let h1 = sh.get_hash(0, 2) // "ab"
  let h2 = sh.get_hash(2, 4) // "cd"
  inspect(h1 != h2, content="true")
}

///|
test "string_hash lcp" {
  let sh = StringHash::new("abcabcabc")
  inspect(sh.lcp(0, 3), content="6") // "abcabc" matches
  inspect(sh.lcp(0, 1), content="0") // "abc..." vs "bca..." no common prefix
}

///|
test "double_hash basic" {
  let dh = DoubleHash::new("abcabc")
  inspect(dh.compare(0, 3, 3, 6), content="true")
  inspect(dh.compare(0, 2, 1, 3), content="false")
}

///|
test "double_hash collision resistance" {
  let dh = DoubleHash::new("abababab")
  let (h1a, h1b) = dh.get_hash(0, 2)
  let (h2a, h2b) = dh.get_hash(2, 4)
  // Same substring "ab" should have same hash
  inspect(h1a == h2a && h1b == h2b, content="true")
}

///|
test "hash_pattern_match" {
  let matches = hash_pattern_match("abababab", "aba")
  inspect(matches.length(), content="3")
  inspect(matches[0], content="0")
  inspect(matches[1], content="2")
  inspect(matches[2], content="4")
}

///|
test "hash_pattern_match no match" {
  let matches = hash_pattern_match("abcdef", "xyz")
  inspect(matches.length(), content="0")
}

///|
test "count_distinct_substrings" {
  // "aaa" has only 1 distinct substring of length 1 ("a")
  inspect(count_distinct_substrings("aaa", 1), content="1")
  // "abc" has 3 distinct substrings of length 1 ("a", "b", "c")
  inspect(count_distinct_substrings("abc", 1), content="3")
  // "abab" has 2 distinct substrings of length 2 ("ab", "ba")
  inspect(count_distinct_substrings("abab", 2), content="2")
}

///|
test "string_hash empty" {
  let sh = StringHash::new("")
  inspect(sh.length(), content="0")
  inspect(sh.get_hash(0, 0), content="0")
}

///|
test "string_hash full string" {
  let sh = StringHash::new("abc")
  let h1 = sh.get_hash(0, 3)
  let sh2 = StringHash::new("abc")
  let h2 = sh2.get_hash(0, 3)
  inspect(h1 == h2, content="true")
}

///|
test "string_hash single char" {
  let sh = StringHash::new("aaaa")
  inspect(sh.compare(0, 1, 1, 2), content="true")
  inspect(sh.compare(0, 1, 2, 3), content="true")
}
