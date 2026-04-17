///|
/// Suffix Array and LCP Array Examples
///
/// This file demonstrates suffix array construction and applications,
/// showcasing deep loop invariants that capture the correctness of
/// these fundamental string data structures.
///
/// Key Insight: A suffix array is a sorted array of all suffixes of a string.
/// Combined with the LCP (Longest Common Prefix) array, it enables
/// O(n) or O(log n) solutions to many string problems.

///|
/// Build the suffix array of `s` using a simple selection-sort approach.
///
/// The **suffix array** `sa` of a string of length `n` is a permutation of
/// `[0, n)` such that `sa[i]` is the starting index of the i-th smallest
/// suffix in lexicographic order.
///
/// This implementation uses an O(n² log n) selection sort for clarity.
/// Production code should use a radix-sort-based O(n log n) or O(n)
/// construction.
///
/// # Mathematical foundation
/// ```
/// s = "banana"   (n = 6)
///
/// Suffix index | Suffix   | Rank
///      5       | "a"      |  0
///      3       | "ana"    |  1
///      1       | "anana"  |  2
///      0       | "banana" |  3
///      4       | "na"     |  4
///      2       | "nana"   |  5
///
/// sa = [5, 3, 1, 0, 4, 2]
/// ```
///
/// # Parameters
/// - `s` — the string whose suffix array is requested
///
/// # Returns
/// An `Array[Int]` of length `s.length()` containing the sorted suffix
/// starting indices.  Returns an empty array for the empty string.
fn build_suffix_array_simple(s : String) -> Array[Int] {
  let chars = s.to_array()
  let n = chars.length()
  if n == 0 {
    return []
  }

  // Create array of suffix indices
  let sa = [ for i in 0..<n => i ]

  // Sort using bubble sort with suffix comparison
  // (In production, use radix sort for O(n log n))
  for i in 0..<n {
    for j in (i + 1)..<n {
      if compare_suffixes(chars, sa[i], sa[j]) > 0 {
        let temp = sa[i]
        sa[i] = sa[j]
        sa[j] = temp
      }
    } where {
      proof_invariant: j >= i + 1 && j <= n,
      proof_reasoning: (
        #|INVARIANT (selection):
        #|sa[i] is the smallest suffix among indices in [i..j).
        #|MAINTENANCE:
        #|Compare sa[i] with sa[j] and swap if sa[j] is smaller.
        #|TERMINATION:
        #|At j = n, sa[i] is the minimum suffix in [i..n).
      ),
    }
  } where {
    proof_invariant: i >= 0 && i < n,
    proof_reasoning: (
      #|INVARIANT (selection outer loop):
      #|sa[0..i) contains the i smallest suffixes in sorted order.
      #|MAINTENANCE:
      #|The inner loop selects the smallest suffix in [i..n), placing it at
      #|sa[i], so the prefix grows by one sorted suffix.
      #|TERMINATION:
      #|At i == n, the full suffix array is sorted lexicographically.
    ),
  }
  sa
}

///|
/// Compare two suffixes of `chars` starting at indices `i` and `j`
/// lexicographically.
///
/// Returns a negative integer if suffix `i` is less than suffix `j`,
/// zero if they are equal, and a positive integer if suffix `i` is greater.
/// The shorter suffix is considered smaller when it is a proper prefix of
/// the longer one.
///
/// # Parameters
/// - `chars` — the character array holding both suffixes
/// - `i`     — starting index of the first suffix
/// - `j`     — starting index of the second suffix
fn compare_suffixes(chars : Array[Char], i : Int, j : Int) -> Int {
  let n = chars.length()
  let len = if n - i < n - j { n - i } else { n - j }
  for k in 0..<len {
    if chars[i + k] < chars[j + k] {
      return -1
    }
    if chars[i + k] > chars[j + k] {
      return 1
    }
  } nobreak {
    // Shorter suffix is smaller
    n - i - (n - j)
  } where {
    proof_invariant: k >= 0,
    proof_reasoning: (
      #|INVARIANT (suffix compare):
      #|All positions up to offset k match between suffixes i and j.
      #|MAINTENANCE:
      #|Advance k while characters are equal.
      #|TERMINATION:
      #|On mismatch or end, the ordering is determined.
    ),
  }
}

///|
test "suffix array simple" {
  let sa = build_suffix_array_simple("banana")
  assert_eq(sa[0], 5) // "a"
  assert_eq(sa[1], 3) // "ana"
  assert_eq(sa[2], 1) // "anana"
  assert_eq(sa[3], 0) // "banana"
  assert_eq(sa[4], 4) // "na"
  assert_eq(sa[5], 2) // "nana"
}

///|
/// Build the LCP (Longest Common Prefix) array for string `s` given its
/// suffix array `sa`, using Kasai's O(n) algorithm.
///
/// `lcp[i]` is the length of the longest common prefix between the suffixes
/// at sorted positions `i` and `i-1` (i.e. `sa[i]` and `sa[i-1]`).
/// `lcp[0] = 0` by convention (no predecessor).
///
/// **Kasai's key observation:** if the suffix starting at position `i` has
/// LCP `k` with its predecessor in the sorted order, then the suffix starting
/// at position `i+1` has LCP at least `k-1`.  Processing suffixes in text
/// order (not sorted order) and carrying this lower bound forward yields a
/// total of at most `2n` character comparisons.
///
/// # Example
/// ```
/// s  = "banana"
/// sa = [5, 3, 1, 0, 4, 2]
///
/// Sorted suffixes: "a" | "ana" | "anana" | "banana" | "na" | "nana"
/// lcp             =  0 |   1   |    3    |     0    |   0  |   2
/// ```
///
/// # Parameters
/// - `s`  — the original string
/// - `sa` — its suffix array (from `build_suffix_array_simple`)
///
/// # Returns
/// An `Array[Int]` of length `s.length()` containing the LCP values.
/// Returns an empty array for the empty string.
fn build_lcp_array(s : String, sa : ArrayView[Int]) -> Array[Int] {
  let chars = s.to_array()
  let n = chars.length()
  if n == 0 {
    return []
  }

  // Build rank array: rank[i] = position of suffix i in sorted order
  let rank = Array::make(n, 0)
  sa.eachi((i, pos) => rank[pos] = i)
  let lcp = Array::make(n, 0)

  // Process suffixes in text order (not sorted order)
  let _ = for i = 0, k = 0; i < n; i = i + 1 {
    if rank[i] == 0 {
      continue i + 1, 0
    }

    // Previous suffix in sorted order
    let j = sa[rank[i] - 1]

    // Extend LCP from previous value
    let k = for k = k; i + k < n && j + k < n && chars[i + k] == chars[j + k]; {
      continue k + 1
    } nobreak {
      k
    } where {
      proof_invariant: k >= 0,
      proof_reasoning: (
        #|INVARIANT (LCP extend):
        #|Characters match for the current prefix length k.
        #|MAINTENANCE:
        #|Increment k while the next characters match.
        #|TERMINATION:
        #|Stop when mismatch or end is reached; k is the LCP length.
      ),
    }
    lcp[rank[i]] = k

    // Key insight: next suffix can have LCP at most k-1 less
    continue i + 1, if k > 0 { k - 1 } else { k }
  } where {
    proof_invariant: i >= 0 && i <= n && k >= 0,
    proof_reasoning: (
      #|LOOP INVARIANT (Kasai's Algorithm):
      #|  - lcp[rank[0..i)] has been computed
      #|  - k is a lower bound for the next LCP computation
      #|
      #|KEY INSIGHT: If suffix at position i has LCP = k with its predecessor,
      #|then suffix at position i+1 has LCP >= k-1 with its predecessor.
      #|
      #|PROOF: Removing the first character of both suffixes in the
      #|comparison can reduce the common prefix by at most 1.
      #|
      #|This ensures total work is O(n): k increases at most n times total,
      #|and decreases by 1 at most n times.
      #|MAINTENANCE:
      #|Use k as a lower bound, extend matches, then decrement k by at most 1.
      #|TERMINATION:
      #|At i == n, all LCP values are computed.
    ),
  }
  lcp
}

///|
test "lcp array" {
  let s = "banana"
  let sa = build_suffix_array_simple(s)
  let lcp = build_lcp_array(s, sa[:])
  // SA:  [5, 3, 1, 0, 4, 2]
  // Suffixes in order: a, ana, anana, banana, na, nana
  // LCP: [0, 1, 3, 0, 0, 2]
  //      (-, a/ana=1, ana/anana=3, anana/banana=0, banana/na=0, na/nana=2)
  assert_eq(lcp[0], 0) // No predecessor
  assert_eq(lcp[1], 1) // "a" vs "ana" = 1
  assert_eq(lcp[2], 3) // "ana" vs "anana" = 3
  assert_eq(lcp[3], 0) // "anana" vs "banana" = 0
  assert_eq(lcp[4], 0) // "banana" vs "na" = 0
  assert_eq(lcp[5], 2) // "na" vs "nana" = 2
}

///|
/// Count the number of distinct (non-empty) substrings of `s`.
///
/// Uses the suffix array and LCP array with the formula:
/// ```
/// distinct = n*(n+1)/2 - sum(lcp)
/// ```
/// Each suffix `sa[i]` of length `n - sa[i]` contributes exactly
/// `(n - sa[i]) - lcp[i]` new distinct substrings that were not already
/// introduced by the lexicographically preceding suffix.
///
/// # Example
/// ```
/// // "ab": substrings "a", "b", "ab"  -> 3
/// // "aa": substrings "a", "aa"       -> 2
/// // "abc": 6 distinct substrings
/// ```
///
/// # Parameters
/// - `s` — the string to analyse
///
/// # Returns
/// The count of distinct non-empty substrings as an `Int`.
fn count_distinct_substrings(s : String) -> Int {
  let n = s.to_array().length()
  if n == 0 {
    return 0
  }
  let sa = build_suffix_array_simple(s)
  let lcp = build_lcp_array(s, sa[:])

  // Total substrings from each suffix, minus duplicates
  for i = 0, total = 0; i < n; i = i + 1 {
    let suffix_len = n - sa[i]
    let duplicates = lcp[i]
    continue i + 1, total + suffix_len - duplicates
  } nobreak {
    total
  } where {
    proof_invariant: i >= 0 && i <= n && total >= 0,
    proof_reasoning: (
      #|LOOP INVARIANT: total = count of distinct substrings from suffixes 0..i
      #|
      #|Suffix sa[i] has length (n - sa[i]), contributing that many substrings.
      #|But lcp[i] of them are prefixes shared with the previous suffix,
      #|so we subtract lcp[i] to avoid double counting.
      #|
      #|CORRECTNESS: Every substring is a prefix of exactly one suffix
      #|(the one starting at its position). By processing in sorted order
      #|and subtracting common prefixes, we count each distinct substring once.
      #|MAINTENANCE:
      #|Add (n - sa[i]) - lcp[i] to total and advance i.
      #|TERMINATION:
      #|At i == n, total equals the number of distinct substrings.
    ),
  }
}

///|
test "count distinct substrings" {
  assert_eq(count_distinct_substrings("ab"), 3) // "a", "b", "ab"
  assert_eq(count_distinct_substrings("aa"), 2) // "a", "aa"
  assert_eq(count_distinct_substrings("abc"), 6) // "a", "b", "c", "ab", "bc", "abc"
}

///|
/// Find the longest substring of `s` that appears at least twice.
///
/// The longest repeated substring corresponds to the maximum value in the
/// LCP array.  When `lcp[i] = k`, the first `k` characters of suffixes
/// `sa[i-1]` and `sa[i]` are identical, so `k` characters starting at
/// `sa[i]` appear at two different positions in `s`.
///
/// # Example
/// ```
/// // longest_repeated_substring("banana") == "ana"
/// // longest_repeated_substring("abcd")   == ""   (no repetition)
/// // longest_repeated_substring("aaa")    == "aa"
/// ```
///
/// # Parameters
/// - `s` — the string to search
///
/// # Returns
/// The longest repeated substring, or `""` if no character appears more
/// than once.
fn longest_repeated_substring(s : String) -> String {
  let chars = s.to_array()
  let n = chars.length()
  if n <= 1 {
    return ""
  }
  let sa = build_suffix_array_simple(s)
  let lcp = build_lcp_array(s, sa[:])

  // Find maximum LCP
  for i = 1, max_lcp = 0, max_idx = 0; i < n; i = i + 1 {
    if lcp[i] > max_lcp {
      continue i + 1, lcp[i], i
    } else {
      continue i + 1, max_lcp, max_idx
    }
  } nobreak {
    if max_lcp == 0 {
      ""
    } else {
      // Extract substring
      let start = sa[max_idx]
      let result = [ for k in 0..<max_lcp => chars[start + k] ]
      String::from_array(result)
    }
  } where {
    proof_invariant: i >= 1 && i <= n && max_lcp >= 0,
    proof_reasoning: (
      #|LOOP INVARIANT: max_lcp = maximum LCP value in lcp[1..i)
      #|
      #|The longest repeated substring appears as a common prefix
      #|of two adjacent suffixes in sorted order, which is exactly
      #|what LCP measures.
      #|MAINTENANCE:
      #|Compare lcp[i] to max_lcp and update if larger, then advance i.
      #|TERMINATION:
      #|At i == n, max_lcp is the longest repeated substring length.
    ),
  }
}

///|
test "longest repeated substring" {
  assert_eq(longest_repeated_substring("banana"), "ana")
  assert_eq(longest_repeated_substring("abcd"), "")
  assert_eq(longest_repeated_substring("aaa"), "aa")
}

///|
/// Find all starting positions where `pattern` occurs in `s` using binary
/// search on the suffix array.
///
/// Because the suffix array stores suffixes in sorted order, all suffixes
/// that start with `pattern` form a contiguous range `[lo, hi)`.  Two binary
/// searches locate this range in **O(m log n)** time (after O(n² log n)
/// preprocessing).
///
/// # Parameters
/// - `s`       — the text to search in
/// - `pattern` — the pattern to search for
///
/// # Returns
/// An `Array[Int]` of all (unsorted) starting positions in `s` where
/// `pattern` occurs.  Returns an empty array if `pattern` is empty, longer
/// than `s`, or not found.
///
/// # Example
/// ```
/// // search_pattern("banana", "ana") -> [1, 3]  (two occurrences)
/// // search_pattern("banana", "ban") -> [0]
/// ```
fn search_pattern(s : String, pattern : String) -> Array[Int] {
  let s_chars = s.to_array()
  let p_chars = pattern.to_array()
  let n = s_chars.length()
  let m = p_chars.length()
  if n == 0 || m == 0 || m > n {
    return []
  }
  let sa = build_suffix_array_simple(s)

  // Binary search for lower bound
  let lo = search_lower_bound(s_chars, sa[:], p_chars)
  // Binary search for upper bound
  let hi = search_upper_bound(s_chars, sa[:], p_chars)

  // Collect all matches
  sa[lo:hi].to_array()
}

///|
/// Binary-search the suffix array `sa` for the first index whose suffix
/// is greater than or equal to the pattern `p`.
///
/// This is the standard lower-bound binary search adapted for suffix
/// comparisons.  The loop invariant is: all indices `< lo` are strictly
/// less than `p`; all indices `>= hi` are greater than or equal to `p`.
fn search_lower_bound(
  s : Array[Char],
  sa : ArrayView[Int],
  p : Array[Char],
) -> Int {
  let n = sa.length()
  for lo = 0, hi = n; lo < hi; {
    let mid = (lo + hi) / 2
    if compare_with_pattern(s, sa[mid], p) < 0 {
      continue mid + 1, hi
    } else {
      continue lo, mid
    }
  } nobreak {
    lo
  } where {
    proof_invariant: lo >= 0 && hi >= 0 && lo <= hi + 1,
    proof_reasoning: (
      #|INVARIANT (lower bound):
      #|All indices < lo are < pattern; all indices >= hi are >= pattern.
      #|MAINTENANCE:
      #|Move lo or hi based on comparison at mid.
      #|TERMINATION:
      #|At lo == hi, lo is the first suffix >= pattern.
    ),
  }
}

///|
/// Binary-search the suffix array `sa` for the first index whose suffix
/// is strictly greater than the pattern `p`.
///
/// This is the upper-bound binary search; together with `search_lower_bound`
/// it identifies the half-open range `[lo, hi)` of all suffixes that have
/// `p` as a prefix.
fn search_upper_bound(
  s : Array[Char],
  sa : ArrayView[Int],
  p : Array[Char],
) -> Int {
  let n = sa.length()
  for lo = 0, hi = n; lo < hi; {
    let mid = (lo + hi) / 2
    if compare_with_pattern(s, sa[mid], p) <= 0 {
      continue mid + 1, hi
    } else {
      continue lo, mid
    }
  } nobreak {
    lo
  } where {
    proof_invariant: lo >= 0 && hi >= 0 && lo <= hi + 1,
    proof_reasoning: (
      #|INVARIANT (upper bound):
      #|All indices < lo are <= pattern; all indices >= hi are > pattern.
      #|MAINTENANCE:
      #|Move lo or hi based on comparison at mid.
      #|TERMINATION:
      #|At lo == hi, lo is the first suffix > pattern.
    ),
  }
}

///|
/// Compare the suffix of `s` starting at `start` with pattern `p`.
///
/// Returns a negative integer if the suffix is lexicographically less than
/// `p`, zero if `p` is a prefix of the suffix (or they are equal), and a
/// positive integer if the suffix is greater than `p`.
///
/// A suffix shorter than `p` is treated as less than `p`.
fn compare_with_pattern(s : Array[Char], start : Int, p : Array[Char]) -> Int {
  let n = s.length()
  let m = p.length()
  let len = if m < n - start { m } else { n - start }
  for i in 0..<len {
    if s[start + i] < p[i] {
      return -1
    }
    if s[start + i] > p[i] {
      return 1
    }
  } nobreak {
    // All compared characters match
    // If suffix is shorter than pattern, it's "less"
    if start + m > n {
      -1
    } else {
      0
    }
  } where {
    proof_invariant: i >= 0 && i <= m,
    proof_reasoning: (
      #|INVARIANT (pattern compare):
      #|Characters up to offset i match between suffix and pattern.
      #|MAINTENANCE:
      #|Advance i while characters are equal.
      #|TERMINATION:
      #|On mismatch or end, return ordering or prefix match.
    ),
  }
}

///|
test "pattern search" {
  let s = "banana"
  let matches = search_pattern(s, "ana")
  assert_eq(matches.length(), 2) // positions 1 and 3
  let matches2 = search_pattern(s, "ban")
  assert_eq(matches2.length(), 1)
  assert_eq(matches2[0], 0)
}

///|
/// Find the longest substring common to both `s1` and `s2` using a suffix
/// array on the concatenation `s1 + '$' + s2`.
///
/// The separator `'$'` (ASCII 36, less than any lowercase letter) ensures
/// that no suffix crosses from `s1` into `s2`.  After building the suffix
/// array and LCP array for the combined string, the longest common substring
/// is the maximum LCP value between adjacent suffixes that originate from
/// **different** input strings.
///
/// # Parameters
/// - `s1` — first string
/// - `s2` — second string
///
/// # Returns
/// The longest common substring (as a `String`), or `""` if the strings
/// share no common character.
///
/// # Example
/// ```
/// // longest_common_substring_sa("abcdef", "zbcdf") == "bcd"
/// // longest_common_substring_sa("abc",    "xyz")   == ""
/// ```
fn longest_common_substring_sa(s1 : String, s2 : String) -> String {
  let c1 = s1.to_array()
  let c2 = s2.to_array()
  let n1 = c1.length()
  let n2 = c2.length()
  if n1 == 0 || n2 == 0 {
    return ""
  }

  // Concatenate with separator (use '$' which is less than lowercase letters)
  let combined : Array[Char] = []
  combined.append(c1[:])
  combined.push('$')
  combined.append(c2[:])
  let combined_str = String::from_array(combined)
  let n = combined.length()
  let sa = build_suffix_array_simple(combined_str)
  let lcp = build_lcp_array(combined_str, sa[:])

  // Find max LCP where adjacent suffixes are from different strings
  for i = 1, max_lcp = 0, max_idx = 0; i < n; i = i + 1 {
    let from_s1_curr = sa[i] < n1
    let from_s1_prev = sa[i - 1] < n1

    // Must be from different original strings
    if from_s1_curr != from_s1_prev && lcp[i] > max_lcp {
      continue i + 1, lcp[i], i
    } else {
      continue i + 1, max_lcp, max_idx
    }
  } nobreak {
    if max_lcp == 0 {
      ""
    } else {
      let start = sa[max_idx]
      let result = [ for k in 0..<max_lcp => combined[start + k] ]
      String::from_array(result)
    }
  } where {
    proof_invariant: i >= 1 && i <= n,
    proof_reasoning: (
      #|LOOP INVARIANT: max_lcp = longest common substring found so far
      #|
      #|By concatenating s1 + '$' + s2 and building SA/LCP:
      #|  - Suffixes starting in s1 have index < n1
      #|  - Suffixes starting in s2 have index > n1
      #|  - LCP between adjacent suffixes from different strings
      #|    gives a common substring
      #|
      #|The separator '$' ensures no suffix crosses from s1 to s2.
      #|MAINTENANCE:
      #|When adjacent suffixes are from different strings, update max_lcp.
      #|TERMINATION:
      #|At i == n, max_lcp is the LCS length.
    ),
  }
}

///|
test "longest common substring sa" {
  assert_eq(longest_common_substring_sa("abcdef", "zbcdf"), "bcd")
  assert_eq(longest_common_substring_sa("abc", "xyz"), "")
}

///|
/// Count the number of substrings of `s` that start with each lowercase
/// letter (`'a'` to `'z'`).
///
/// For each position `i`, the suffix `s[i..]` of length `n - i` contributes
/// exactly `n - i` substrings of length 1 through `n - i`, all starting with
/// `s[i]`.  Accumulating this over all positions gives the result in O(n).
///
/// # Parameters
/// - `s` — the string to analyse (only lowercase ASCII letters are counted)
///
/// # Returns
/// An `Array[Int]` of length 26 where index `c` holds the total number of
/// substrings starting with the character `'a' + c`.
///
/// # Example
/// ```
/// // s = "abc"
/// // 'a': "a", "ab", "abc"  -> 3
/// // 'b': "b", "bc"         -> 2
/// // 'c': "c"               -> 1
/// ```
fn count_substrings_by_char(s : String) -> Array[Int] {
  let chars = s.to_array()
  let n = chars.length()

  // Count for each character (assuming lowercase a-z)
  let count = Array::make(26, 0)
  for i in 0..<n {
    let c = chars[i].to_int() - 'a'.to_int()
    if c >= 0 && c < 26 {
      // Suffix at position i contributes (n - i) substrings
      count[c] = count[c] + (n - i)
    }
  } where {
    proof_invariant: i >= 0 && i <= n,
    proof_reasoning: (
      #|LOOP INVARIANT: count[c] = total substrings starting with character c
      #|                          from positions [0, i)
      #|
      #|Each position i contributes (n - i) substrings (all lengths 1 to n-i).
      #|We add this to the count for the starting character.
      #|MAINTENANCE:
      #|Accumulate substrings for chars[i] and advance i.
      #|TERMINATION:
      #|At i == n, all starting positions are counted.
    ),
  }
  count
}

///|
test "count substrings by char" {
  let counts = count_substrings_by_char("abc")
  assert_eq(counts[0], 3) // "a", "ab", "abc"
  assert_eq(counts[1], 2) // "b", "bc"
  assert_eq(counts[2], 1) // "c"
}

///|
/// Compute the Burrows-Wheeler Transform (BWT) of `s`.
///
/// The BWT is the **last column** of the matrix formed by all cyclic rotations
/// of `s` sorted lexicographically.  It is a reversible transformation that
/// groups similar preceding contexts together, making the output highly
/// compressible (used in bzip2).
///
/// Using the suffix array, `BWT[i] = s[(sa[i] - 1 + n) % n]` — the character
/// immediately before the suffix `sa[i]` in the circular string.
///
/// # Example
/// ```
/// // s = "banana"  (n=6)
/// // SA = [5, 3, 1, 0, 4, 2]
/// // Sorted rotations (last column):
/// //   "abanan" -> 'n'
/// //   "anaban" -> 'n'
/// //   "ananba" -> 'b'
/// //   "bnanaa" -> 'a'  (well-known result: BWT("banana") = "nnbaaa")
/// // burrows_wheeler_transform("banana") == "nnbaaa"
/// ```
///
/// # Parameters
/// - `s` — the string to transform (treated as circular)
///
/// # Returns
/// The BWT of `s` as a `String` of the same length.
fn burrows_wheeler_transform(s : String) -> String {
  let chars = s.to_array()
  let n = chars.length()
  if n == 0 {
    return ""
  }
  let sa = build_suffix_array_simple(s)
  let bwt : Array[Char] = []
  for i in 0..<n {
    // Character before the suffix (with wraparound)
    let idx = (sa[i] - 1 + n) % n
    bwt.push(chars[idx])
  } where {
    proof_invariant: i >= 0 && i <= n,
    proof_reasoning: (
      #|LOOP INVARIANT: bwt[0..i) contains BWT of first i suffixes
      #|
      #|BWT[i] is the character preceding suffix sa[i] in the original string.
      #|For sa[i] = 0, we wrap around to character n-1.
      #|
      #|KEY INSIGHT: BWT groups characters that precede similar contexts,
      #|making it highly compressible.
      #|MAINTENANCE:
      #|Append chars[(sa[i] - 1 + n) % n] and advance i.
      #|TERMINATION:
      #|At i == n, BWT is complete.
    ),
  }
  String::from_array(bwt)
}

///|
test "burrows wheeler transform" {
  let bwt = burrows_wheeler_transform("banana")
  // SA: [5, 3, 1, 0, 4, 2] (sorted: "a", "ana", "anana", "banana", "na", "nana")
  // BWT[i] = chars[(SA[i]-1+n) % n]: indices [4,2,0,5,3,1] -> chars: [n,n,b,a,a,a]
  assert_eq(bwt, "nnbaaa")
}

///|
/// Return the lexicographically smallest rotation of `s`.
///
/// By doubling the string (`s + s`), every rotation of length `n` appears as
/// a contiguous substring.  Building the suffix array of the doubled string
/// and selecting the first suffix that starts within the first half gives the
/// smallest rotation.
///
/// Note: `booth_smallest_rotation` in `string_algorithms.mbt` solves the same
/// problem in O(n) time; this function runs in O(n² log n) due to the simple
/// suffix-array construction but demonstrates the suffix-array technique.
///
/// # Parameters
/// - `s` — the string to rotate
///
/// # Returns
/// The lexicographically smallest rotation of `s` as a `String`.
/// Returns `""` for the empty string.
///
/// # Example
/// ```
/// // smallest_rotation("bca") == "abc"
/// // smallest_rotation("abc") == "abc"
/// ```
fn smallest_rotation(s : String) -> String {
  let chars = s.to_array()
  let n = chars.length()
  if n == 0 {
    return ""
  }

  // Double the string
  let doubled : Array[Char] = []
  doubled.append(chars[:])
  doubled.append(chars[:])
  let doubled_str = String::from_array(doubled)
  let sa = build_suffix_array_simple(doubled_str)

  // Find smallest suffix that starts in first half
  for i in 0..<(2 * n) {
    if sa[i] < n {
      // This is the smallest rotation starting point
      let result = [ for j in 0..<n => chars[(sa[i] + j) % n] ]
      return String::from_array(result)
    }
  } nobreak {
    s // Should not reach here
  } where {
    proof_invariant: i >= 0 && i <= 2 * n,
    proof_reasoning: (
      #|LOOP INVARIANT: No suffix with index < n found in sa[0..i)
      #|
      #|By doubling the string, each rotation appears as a suffix.
      #|The lexicographically smallest suffix starting in the first half
      #|gives the smallest rotation.
      #|MAINTENANCE:
      #|Scan sa in order; return on the first index < n.
      #|TERMINATION:
      #|At i == 2 * n, all suffixes were checked (fallback to s).
    ),
  }
}

///|
test "smallest rotation" {
  assert_eq(smallest_rotation("bca"), "abc")
  assert_eq(smallest_rotation("cba"), "acb")
  assert_eq(smallest_rotation("abc"), "abc")
}
