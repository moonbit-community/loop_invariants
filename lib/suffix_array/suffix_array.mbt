// ============================================================================
// SUFFIX ARRAY - Efficient Suffix Sorting with LCP Array
// ============================================================================
//
// A Suffix Array is a sorted array of all suffixes of a string.
// Combined with LCP (Longest Common Prefix) array, it enables powerful
// string operations in O(n log n) construction and O(log n) or O(1) queries.
//
// SUFFIX ARRAY CONSTRUCTION (Simple O(n log^2 n) approach):
// 1. Start with single-character ranks
// 2. Double the comparison length each iteration
// 3. Sort suffixes by (rank[i], rank[i+k]) pairs
// 4. Total: O(n log^2 n) time, O(n) space
//
// LCP ARRAY (Kasai's Algorithm):
// lcp[i] = length of longest common prefix between suffix[sa[i]] and suffix[sa[i-1]]
// Key insight: lcp[rank[i]] >= lcp[rank[i-1]] - 1
//
// TIME COMPLEXITY: O(n log^2 n) construction, O(m log n) pattern search
// SPACE COMPLEXITY: O(n)

///|
pub struct SuffixArray {
  sa : Array[Int]
  lcp : Array[Int]
  text : String
}

///|
/// Build a suffix array and LCP array for text.
pub fn SuffixArray::new(text : String) -> SuffixArray {
  let n = text.length()
  if n == 0 {
    return { sa: [], lcp: [], text }
  }
  let sa = Array::make(n, 0)
  let rank = Array::make(n, 0)

  // Initialize
  for i = 0; i < n; i = i + 1 {
    sa[i] = i
    rank[i] = text[i].to_int()
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (initial ranks):
      #|For all indices in [0, i), sa[j] = j and rank[j] equals the character
      #|code of text[j]. This is the base ordering by single characters.
      #|MAINTENANCE:
      #|Assign sa[i] = i and rank[i] = text[i].to_int().
      #|TERMINATION:
      #|At i = n, every suffix has an initial rank from its first character.
    ),
  }

  // Prefix doubling
  for k = 1; k < n; k = k * 2 {
    // Sort by (rank[i], rank[i+k]) pairs
    let get_key = i => (rank[i], if i + k < n { rank[i + k] } else { -1 })
    sa.sort_by(fn(a, b) {
      let (a1, a2) = get_key(a)
      let (b1, b2) = get_key(b)
      if a1 != b1 {
        a1 - b1
      } else {
        a2 - b2
      }
    })

    // Compute new ranks
    let tmp = Array::make(n, 0)
    tmp[sa[0]] = 0
    for i = 1; i < n; i = i + 1 {
      let prev_key = get_key(sa[i - 1])
      let curr_key = get_key(sa[i])
      tmp[sa[i]] = if prev_key == curr_key {
        tmp[sa[i - 1]]
      } else {
        tmp[sa[i - 1]] + 1
      }
    } where {
      invariant: i >= 1 && i <= n,
      reasoning: (
        #|INVARIANT (rank recompute):
        #|tmp has correct ranks for suffixes in sa[0..i). Equal adjacent keys
        #|receive the same rank; strictly larger keys advance the rank.
        #|MAINTENANCE:
        #|Compare keys at sa[i-1] and sa[i] to decide whether to reuse or
        #|increment the rank.
        #|TERMINATION:
        #|At i = n, tmp assigns a rank to every suffix for 2k-length prefixes.
      ),
    }
    for i = 0; i < n; i = i + 1 {
      rank[i] = tmp[i]
    } where {
      invariant: i >= 0 && i <= n,
      reasoning: (
        #|INVARIANT (copy ranks):
        #|rank[0..i) has been updated from tmp, so those positions match the
        #|new ordering by 2k-length prefixes.
        #|MAINTENANCE:
        #|Copy tmp[i] into rank[i].
        #|TERMINATION:
        #|At i = n, rank reflects the current suffix ordering for length 2k.
      ),
    }
    if rank[sa[n - 1]] == n - 1 {
      break
    }
  } where {
    invariant: k >= 1 && k <= n * 2,
    reasoning: (
      #|INVARIANT (prefix doubling):
      #|At the start of each iteration, sa is sorted by the first k characters
      #|of each suffix and rank encodes that ordering.
      #|MAINTENANCE:
      #|Sort by pairs (rank[i], rank[i+k]) to order by the first 2k characters,
      #|then recompute ranks accordingly.
      #|TERMINATION:
      #|If ranks become unique or k >= n, the full suffix order is determined.
    ),
  }

  // Normalize ranks to 0..n-1 range for LCP computation
  // This handles the case where prefix doubling didn't run (n=1)
  let rank_norm = Array::make(n, 0)
  for i = 0; i < n; i = i + 1 {
    rank_norm[sa[i]] = i
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (inverse permutation):
      #|rank_norm is filled for suffixes in sa[0..i), mapping each suffix
      #|start position to its order in sa.
      #|MAINTENANCE:
      #|Set rank_norm[sa[i]] = i.
      #|TERMINATION:
      #|At i = n, rank_norm is the full inverse permutation of sa.
    ),
  }

  // Build LCP array using Kasai's algorithm
  let lcp = Array::make(n, 0)
  for i = 0, h = 0; i < n; {
    let mut curr_h = h
    if rank_norm[i] > 0 {
      let j = sa[rank_norm[i] - 1]
      while i + curr_h < n &&
            j + curr_h < n &&
            text[i + curr_h] == text[j + curr_h] {
        curr_h = curr_h + 1
      }
      lcp[rank_norm[i]] = curr_h
      if curr_h > 0 {
        curr_h = curr_h - 1
      }
    }
    continue i + 1, curr_h
  } where {
    invariant: i >= 0 && i <= n && h >= 0,
    reasoning: (
      #|INVARIANT (Kasai):
      #|For all positions < i, lcp is correctly computed. h equals the LCP
      #|length to reuse for the next suffix, bounded below by 0.
      #|MAINTENANCE:
      #|Compute LCP of suffix i with its predecessor in sa by extending from h.
      #|Then decrement h by at most 1, using the property that LCP drops by at
      #|most 1 between consecutive suffixes in text order.
      #|TERMINATION:
      #|At i = n, all LCP values are computed in total O(n) comparisons.
    ),
  }
  { sa, lcp, text }
}

///|
/// Build the suffix array for s (convenience wrapper).
pub fn suffix_array(s : String) -> Array[Int] {
  SuffixArray::new(s).sa
}

///|
/// Build the LCP array for s using a provided suffix array.
pub fn lcp_array(s : String, sa : ArrayView[Int]) -> Array[Int] {
  let n = s.length()
  if n == 0 || sa.length() != n {
    return []
  }
  let rank = Array::make(n, 0)
  for i = 0; i < n; i = i + 1 {
    rank[sa[i]] = i
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (inverse SA):
      #|rank is filled for sa[0..i), mapping suffix start to its position.
      #|MAINTENANCE:
      #|Set rank[sa[i]] = i.
      #|TERMINATION:
      #|At i = n, rank is the full inverse permutation of sa.
    ),
  }
  let lcp = Array::make(n, 0)
  for i = 0, h = 0; i < n; {
    let mut curr_h = h
    if rank[i] == 0 {
      if curr_h > 0 {
        curr_h = curr_h - 1
      }
      continue i + 1, curr_h
    }
    let j = sa[rank[i] - 1]
    while i + curr_h < n && j + curr_h < n && s[i + curr_h] == s[j + curr_h] {
      curr_h = curr_h + 1
    }
    lcp[rank[i]] = curr_h
    if curr_h > 0 {
      curr_h = curr_h - 1
    }
    continue i + 1, curr_h
  } where {
    invariant: i >= 0 && i <= n && h >= 0,
    reasoning: (
      #|INVARIANT (Kasai scan):
      #|lcp is correct for suffixes with start < i. h is the current reuse
      #|length that can be decremented by at most 1 each step.
      #|MAINTENANCE:
      #|Compute LCP with the previous suffix in SA order, then set h = max(h-1,0).
      #|TERMINATION:
      #|At i = n, all LCP values are computed in O(n).
    ),
  }
  lcp
}

///|
/// Return the suffix array index range matching pattern, or None if absent.
pub fn SuffixArray::search(self : SuffixArray, pattern : String) -> (Int, Int)? {
  let n = self.sa.length()
  let m = pattern.length()
  if n == 0 || m == 0 {
    return None
  }

  // Binary search for lower bound
  let mut lo = 0
  let mut hi = n
  while lo < hi {
    let mid = (lo + hi) / 2
    let suffix_start = self.sa[mid]
    if compare_suffix(self.text, suffix_start, pattern) < 0 {
      lo = mid + 1
    } else {
      hi = mid
    }
  }
  let first = lo

  // Binary search for upper bound
  hi = n
  while lo < hi {
    let mid = (lo + hi) / 2
    let suffix_start = self.sa[mid]
    if starts_with(self.text, suffix_start, pattern) {
      lo = mid + 1
    } else if compare_suffix(self.text, suffix_start, pattern) < 0 {
      lo = mid + 1
    } else {
      hi = mid
    }
  }
  let last = lo - 1
  if first <= last && starts_with(self.text, self.sa[first], pattern) {
    Some((first, last))
  } else {
    None
  }
}

///|
fn compare_suffix(text : String, start : Int, pattern : String) -> Int {
  let n = text.length()
  let m = pattern.length()
  for i = 0; i < m; i = i + 1 {
    if start + i >= n {
      return -1
    }
    if text[start + i] < pattern[i] {
      return -1
    }
    if text[start + i] > pattern[i] {
      return 1
    }
  } where {
    invariant: i >= 0 && i <= m,
    reasoning: (
      #|INVARIANT (suffix compare):
      #|text[start..start+i) matches pattern[0..i). The comparison is decided
      #|by the first mismatch.
      #|MAINTENANCE:
      #|Compare the next characters and return immediately on mismatch.
      #|TERMINATION:
      #|At i = m, pattern is a prefix of the suffix, so they compare equal up
      #|to length m.
    ),
  }
  0
}

///|
fn starts_with(text : String, start : Int, pattern : String) -> Bool {
  let n = text.length()
  let m = pattern.length()
  if start + m > n {
    return false
  }
  for i = 0; i < m; i = i + 1 {
    if text[start + i] != pattern[i] {
      return false
    }
  } where {
    invariant: i >= 0 && i <= m,
    reasoning: (
      #|INVARIANT (prefix match):
      #|text[start..start+i) matches pattern[0..i).
      #|MAINTENANCE:
      #|Compare the next character and fail on mismatch.
      #|TERMINATION:
      #|At i = m, the full pattern matches the suffix prefix.
    ),
  }
  true
}

///|
/// Return all match start positions of pattern in text (sorted ascending).
pub fn SuffixArray::find_all(
  self : SuffixArray,
  pattern : String,
) -> Array[Int] {
  match self.search(pattern) {
    None => []
    Some((first, last)) => {
      let result : Array[Int] = []
      for i = first; i <= last; i = i + 1 {
        result.push(self.sa[i])
      } where {
        invariant: i >= first && i <= last + 1,
        reasoning: (
          #|INVARIANT (collect matches):
          #|result contains sa indices for matches in sa[first..i).
          #|MAINTENANCE:
          #|Append sa[i] for each suffix in the matching range.
          #|TERMINATION:
          #|At i = last + 1, all matching suffix indices are collected.
        ),
      }
      result.sort_by((a, b) => a - b)
      result
    }
  }
}

///|
/// Count how many times pattern appears in text.
pub fn SuffixArray::count(self : SuffixArray, pattern : String) -> Int {
  match self.search(pattern) {
    None => 0
    Some((first, last)) => last - first + 1
  }
}

///|
/// Return the longest repeated substring, or "" if none exists.
pub fn SuffixArray::longest_repeated_substring(self : SuffixArray) -> String {
  let n = self.sa.length()
  if n < 2 {
    return ""
  }
  // Find max LCP and its index using functional for loop
  let (max_idx, max_lcp) = for i = 1, best = (0, 0); i < n; {
    if self.lcp[i] > best.1 {
      continue i + 1, (i, self.lcp[i])
    } else {
      continue i + 1, best
    }
  } else {
    best
  } where {
    invariant: i >= 1 && i <= n,
    reasoning: (
      #|INVARIANT (max LCP):
      #|best is (index, lcp) of the maximum LCP among indices in [1, i).
      #|MAINTENANCE:
      #|Update best when a larger LCP is found.
      #|TERMINATION:
      #|At i = n, best identifies the longest repeated substring.
    ),
  }
  if max_lcp == 0 {
    return ""
  }
  let start = self.sa[max_idx]
  self.text.unsafe_substring(start~, end=start + max_lcp)
}

///|
/// Count the number of distinct substrings in text.
pub fn SuffixArray::count_distinct_substrings(self : SuffixArray) -> Int64 {
  let n = self.sa.length()
  if n == 0 {
    return 0L
  }
  // Total possible substrings minus overlaps (LCP sum)
  let total = n.to_int64() * (n.to_int64() + 1L) / 2L
  let lcp_sum = self.lcp[1:].fold(init=0L, (sum, v) => sum + v.to_int64())
  total - lcp_sum
}

///|
/// Return the i-th suffix in lexicographic order, or "" if out of range.
pub fn SuffixArray::get_suffix(self : SuffixArray, i : Int) -> String {
  if i < 0 || i >= self.sa.length() {
    return ""
  }
  let start = self.sa[i]
  self.text.unsafe_substring(start~, end=self.text.length())
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "suffix array construction" {
  let sa = SuffixArray::new("banana")
  inspect(sa.sa[0], content="5")
  inspect(sa.sa[1], content="3")
  inspect(sa.sa[2], content="1")
  inspect(sa.sa[3], content="0")
  inspect(sa.sa[4], content="4")
  inspect(sa.sa[5], content="2")
}

///|
test "suffix array lcp" {
  let sa = SuffixArray::new("banana")
  inspect(sa.lcp[1], content="1")
  inspect(sa.lcp[2], content="3")
  inspect(sa.lcp[3], content="0")
  inspect(sa.lcp[4], content="0")
  inspect(sa.lcp[5], content="2")
}

///|
test "suffix array convenience" {
  let sa = suffix_array("banana")
  inspect(sa, content="[5, 3, 1, 0, 4, 2]")
  let lcp = lcp_array("banana", sa[:])
  inspect(lcp, content="[0, 1, 3, 0, 0, 2]")
}

///|
test "suffix array search" {
  let sa = SuffixArray::new("banana")
  let matches = sa.find_all("ana")
  inspect(matches.length(), content="2")
  inspect(matches[0], content="1")
  inspect(matches[1], content="3")
  inspect(sa.count("na"), content="2")
  inspect(sa.count("xyz"), content="0")
}

///|
test "suffix array longest repeated" {
  let sa = SuffixArray::new("banana")
  inspect(sa.longest_repeated_substring(), content="ana")
  let sa2 = SuffixArray::new("abcabc")
  inspect(sa2.longest_repeated_substring(), content="abc")
}

///|
test "suffix array distinct substrings" {
  let sa = SuffixArray::new("banana")
  inspect(sa.count_distinct_substrings(), content="15")
}

///|
test "suffix array empty" {
  let sa = SuffixArray::new("")
  inspect(sa.sa.length(), content="0")
}

///|
test "suffix array single char" {
  let sa = SuffixArray::new("a")
  inspect(sa.sa.length(), content="1")
  inspect(sa.sa[0], content="0")
  inspect(sa.count_distinct_substrings(), content="1")
}

///|
test "suffix array all same" {
  let sa = SuffixArray::new("aaaa")
  inspect(sa.sa[0], content="3")
  inspect(sa.sa[1], content="2")
  inspect(sa.sa[2], content="1")
  inspect(sa.sa[3], content="0")
  inspect(sa.count_distinct_substrings(), content="4")
}

///|
test "suffix array pattern not found" {
  let sa = SuffixArray::new("banana")
  let matches = sa.find_all("xyz")
  inspect(matches.length(), content="0")
}

///|
test "suffix array get suffix" {
  let sa = SuffixArray::new("banana")
  inspect(sa.get_suffix(0), content="a")
  inspect(sa.get_suffix(1), content="ana")
  inspect(sa.get_suffix(3), content="banana")
}
