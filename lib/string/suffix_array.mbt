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
/// Suffix Array Construction (Simple O(n² log n) version)
///
/// MATHEMATICAL FOUNDATION:
/// suffix_array[i] = starting index of the i-th smallest suffix
/// For string "banana":
///   Suffixes: banana, anana, nana, ana, na, a
///   Sorted:   a, ana, anana, banana, na, nana
///   SA:       [5, 3, 1, 0, 4, 2]
fn build_suffix_array_simple(s : String) -> Array[Int] {
  let chars = s.to_array()
  let n = chars.length()
  if n == 0 {
    return []
  }

  // Create array of suffix indices
  let sa = Array::makei(n, i => i)

  // Sort using bubble sort with suffix comparison
  // (In production, use radix sort for O(n log n))
  for i = 0; i < n; i = i + 1 {
    for j = i + 1; j < n; j = j + 1 {
      if compare_suffixes(chars, sa[i], sa[j]) > 0 {
        let temp = sa[i]
        sa[i] = sa[j]
        sa[j] = temp
      }
    } where {
      invariant: j >= i + 1 && j <= n,
      reasoning: (
        #|INVARIANT (selection):
        #|sa[i] is the smallest suffix among indices in [i..j).
        #|MAINTENANCE:
        #|Compare sa[i] with sa[j] and swap if sa[j] is smaller.
        #|TERMINATION:
        #|At j = n, sa[i] is the minimum suffix in [i..n).
      ),
    }
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
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
fn compare_suffixes(chars : Array[Char], i : Int, j : Int) -> Int {
  let n = chars.length()
  for k = 0; i + k < n && j + k < n; k = k + 1 {
    if chars[i + k] < chars[j + k] {
      return -1
    }
    if chars[i + k] > chars[j + k] {
      return 1
    }
  } else {
    // Shorter suffix is smaller
    n - i - (n - j)
  } where {
    invariant: k >= 0,
    reasoning: (
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
/// LCP Array Construction (Kasai's Algorithm)
///
/// MATHEMATICAL FOUNDATION:
/// lcp[i] = length of longest common prefix between suffix_array[i] and suffix_array[i-1]
///
/// KEY INSIGHT (Kasai's observation):
/// If lcp[rank[i]] = k, then lcp[rank[i+1]] >= k - 1
/// This allows O(n) construction by processing suffixes in text order.
///
/// INVARIANT: When processing suffix starting at i, we already know
/// lcp for suffix at i-1, giving us a lower bound.
fn build_lcp_array(s : String, sa : ArrayView[Int]) -> Array[Int] {
  let chars = s.to_array()
  let n = chars.length()
  if n == 0 {
    return []
  }

  // Build rank array: rank[i] = position of suffix i in sorted order
  let rank = Array::make(n, 0)
  sa.eachi(fn(i, pos) { rank[pos] = i })
  let lcp = Array::make(n, 0)
  let mut k = 0

  // Process suffixes in text order (not sorted order)
  for i = 0; i < n; i = i + 1 {
    if rank[i] == 0 {
      k = 0
      continue i + 1
    }

    // Previous suffix in sorted order
    let j = sa[rank[i] - 1]

    // Extend LCP from previous value
    for ; i + k < n && j + k < n && chars[i + k] == chars[j + k]; {
      k = k + 1
    } where {
      invariant: k >= 0,
      reasoning: (
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
    if k > 0 {
      k = k - 1
    }
  } where {
    invariant: i >= 0 && i <= n && k >= 0,
    reasoning: (
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
/// Count Distinct Substrings using Suffix Array
///
/// MATHEMATICAL FOUNDATION:
/// Total substrings = n*(n+1)/2
/// Duplicate substrings = sum of LCP values
/// Distinct = Total - Duplicates
///
/// INVARIANT: Each suffix contributes (n - sa[i]) substrings,
/// but lcp[i] of them are duplicates from the previous suffix.
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
  } else {
    total
  } where {
    invariant: i >= 0 && i <= n && total >= 0,
    reasoning: (
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
/// Longest Repeated Substring using LCP
///
/// INSIGHT: The longest repeated substring is the maximum value in the LCP array.
/// It appears as a prefix of two adjacent suffixes in sorted order.
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
  } else {
    if max_lcp == 0 {
      ""
    } else {
      // Extract substring
      let start = sa[max_idx]
      let result = Array::makei(max_lcp, k => chars[start + k])
      String::from_array(result)
    }
  } where {
    invariant: i >= 1 && i <= n && max_lcp >= 0,
    reasoning: (
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
/// Pattern Search using Suffix Array (Binary Search)
///
/// MATHEMATICAL FOUNDATION:
/// Since suffixes are sorted, we can binary search for patterns.
/// Find the range [lo, hi) where all suffixes start with the pattern.
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
  } else {
    lo
  } where {
    invariant: lo >= 0 && hi >= 0 && lo <= hi + 1,
    reasoning: (
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
  } else {
    lo
  } where {
    invariant: lo >= 0 && hi >= 0 && lo <= hi + 1,
    reasoning: (
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
fn compare_with_pattern(s : Array[Char], start : Int, p : Array[Char]) -> Int {
  let n = s.length()
  let m = p.length()
  for i = 0; i < m && start + i < n; i = i + 1 {
    if s[start + i] < p[i] {
      return -1
    }
    if s[start + i] > p[i] {
      return 1
    }
  } else {
    // All compared characters match
    // If suffix is shorter than pattern, it's "less"
    if start + m > n {
      -1
    } else {
      0
    }
  } where {
    invariant: i >= 0 && i <= m,
    reasoning: (
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
/// Longest Common Substring of Two Strings
///
/// INSIGHT: Concatenate strings with a separator, build suffix array,
/// then find max LCP between suffixes from different strings.
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
  } else {
    if max_lcp == 0 {
      ""
    } else {
      let start = sa[max_idx]
      let result = Array::makei(max_lcp, k => combined[start + k])
      String::from_array(result)
    }
  } where {
    invariant: i >= 1 && i <= n,
    reasoning: (
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
/// Number of Substrings Starting with Each Character
///
/// Using suffix array, we can answer this in O(n) preprocessing + O(1) query.
fn count_substrings_by_char(s : String) -> Array[Int] {
  let chars = s.to_array()
  let n = chars.length()

  // Count for each character (assuming lowercase a-z)
  let count = Array::make(26, 0)
  for i = 0; i < n; i = i + 1 {
    let c = chars[i].to_int() - 'a'.to_int()
    if c >= 0 && c < 26 {
      // Suffix at position i contributes (n - i) substrings
      count[c] = count[c] + (n - i)
    }
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
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
/// Burrows-Wheeler Transform (BWT)
///
/// MATHEMATICAL FOUNDATION:
/// BWT is a reversible transformation that groups similar characters together.
/// It's the last column of the sorted rotation matrix.
///
/// For suffix array: BWT[i] = s[(sa[i] - 1 + n) % n]
fn burrows_wheeler_transform(s : String) -> String {
  let chars = s.to_array()
  let n = chars.length()
  if n == 0 {
    return ""
  }
  let sa = build_suffix_array_simple(s)
  let bwt : Array[Char] = []
  for i = 0; i < n; i = i + 1 {
    // Character before the suffix (with wraparound)
    let idx = (sa[i] - 1 + n) % n
    bwt.push(chars[idx])
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
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
/// Lexicographically Smallest Rotation
///
/// Using suffix array on doubled string.
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
  for i = 0; i < 2 * n; i = i + 1 {
    if sa[i] < n {
      // This is the smallest rotation starting point
      let result = Array::makei(n, j => chars[(sa[i] + j) % n])
      return String::from_array(result)
    }
  } else {
    s // Should not reach here
  } where {
    invariant: i >= 0 && i <= 2 * n,
    reasoning: (
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
