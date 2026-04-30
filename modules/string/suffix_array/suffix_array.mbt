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
/// A precomputed index over a string that stores all suffixes in sorted
/// (lexicographic) order together with their Longest Common Prefix (LCP) values.
///
/// Fields:
/// - `sa`   : suffix array; `sa[i]` is the start index of the i-th smallest suffix.
/// - `lcp`  : LCP array; `lcp[i]` is the length of the longest common prefix
///            shared by the suffixes at SA positions `i-1` and `i`. `lcp[0]` is 0.
/// - `text` : the original string used to build the index.
///
/// Build with `SuffixArray::new`. Time: O(n log^2 n). Space: O(n).
pub struct SuffixArray {
  sa : Array[Int]
  lcp : Array[Int]
  text : String
}

///|
/// Build a `SuffixArray` index for `text` using the prefix-doubling algorithm.
///
/// The suffix array `sa` and LCP array `lcp` are computed together so that
/// callers can immediately use the full set of query methods without any extra
/// construction step.
///
/// Parameters:
/// - `text` : the string to index. May be empty, in which case all arrays are
///            empty and all query methods return neutral values.
///
/// Returns a `SuffixArray` value whose fields are fully populated.
///
/// Time: O(n log^2 n) where n = `text.length()`.
/// Space: O(n).
pub fn SuffixArray::SuffixArray(text : String) -> SuffixArray {
  let n = text.length()
  if n == 0 {
    return { sa: [], lcp: [], text }
  }
  let sa = Array::make(n, 0)
  let rank = Array::make(n, 0)

  // Initialize
  for i in 0..<n {
    sa[i] = i
    rank[i] = text[i].to_int()
  }

  // Prefix doubling
  for k = 1; k < n; k = k * 2 {
    // Sort by (rank[i], rank[i+k]) pairs
    let get_key = i => (rank[i], if i + k < n { rank[i + k] } else { -1 })
    sa.sort_by((a, b) => {
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
    for i in 1..<n {
      let prev_key = get_key(sa[i - 1])
      let curr_key = get_key(sa[i])
      tmp[sa[i]] = if prev_key == curr_key {
        tmp[sa[i - 1]]
      } else {
        tmp[sa[i - 1]] + 1
      }
    }
    for i in 0..<n {
      rank[i] = tmp[i]
    }
    if rank[sa[n - 1]] == n - 1 {
      break
    }
  } where {
    proof_invariant: k >= 1 && k <= n * 2,
    proof_reasoning: (
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
  for i in 0..<n {
    rank_norm[sa[i]] = i
  }

  // Build LCP array using Kasai's algorithm
  let lcp = Array::make(n, 0)
  for i = 0, h = 0; i < n; {
    let curr_h = h
    if rank_norm[i] > 0 {
      let j = sa[rank_norm[i] - 1]
      let curr_h = for curr_h = curr_h; i + curr_h < n &&
                      j + curr_h < n &&
                      text[i + curr_h] == text[j + curr_h]; {
        continue curr_h + 1
      } nobreak {
        curr_h
      }
      lcp[rank_norm[i]] = curr_h
      continue i + 1, if curr_h > 0 { curr_h - 1 } else { curr_h }
    }
    continue i + 1, curr_h
  } where {
    proof_invariant: i >= 0 && i <= n && h >= 0,
    proof_reasoning: (
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
/// Build and return just the suffix array for `s`.
///
/// This is a convenience wrapper around `SuffixArray::new` for callers that
/// only need the raw suffix array without the full index object.
///
/// Parameters:
/// - `s` : the string to index.
///
/// Returns an `Array[Int]` where element `i` is the starting index of the
/// i-th lexicographically smallest suffix of `s`.
///
/// Time: O(n log^2 n). Space: O(n).
pub fn suffix_array(s : String) -> Array[Int] {
  SuffixArray(s).sa
}

///|
/// Build the LCP array for `s` given a precomputed suffix array `sa`.
///
/// Uses Kasai's algorithm: for each suffix in text order, the LCP with its
/// predecessor in SA order is computed by extending from the previous LCP
/// value decremented by at most one. This guarantees O(n) total character
/// comparisons even though n suffixes are processed.
///
/// Parameters:
/// - `s`  : the original string.
/// - `sa` : a valid suffix array for `s` (length must equal `s.length()`).
///          Pass `sa[:]` to convert an `Array[Int]` to the required view.
///
/// Returns an `Array[Int]` `lcp` of the same length as `s`, where `lcp[i]`
/// is the length of the longest common prefix shared by `s[sa[i-1]:]` and
/// `s[sa[i]:]`. `lcp[0]` is always 0.
///
/// Returns an empty array if `s` is empty or if `sa.length() != s.length()`.
///
/// Time: O(n). Space: O(n).
pub fn lcp_array(s : String, sa : ArrayView[Int]) -> Array[Int] {
  let n = s.length()
  if n == 0 || sa.length() != n {
    return []
  }
  let rank = Array::make(n, 0)
  for i in 0..<n {
    rank[sa[i]] = i
  }
  let lcp = Array::make(n, 0)
  for i = 0, h = 0; i < n; {
    let curr_h = h
    if rank[i] == 0 {
      continue i + 1, if curr_h > 0 { curr_h - 1 } else { curr_h }
    }
    let j = sa[rank[i] - 1]
    let curr_h = for curr_h = curr_h; i + curr_h < n &&
                    j + curr_h < n &&
                    s[i + curr_h] == s[j + curr_h]; {
      continue curr_h + 1
    } nobreak {
      curr_h
    }
    lcp[rank[i]] = curr_h
    continue i + 1, if curr_h > 0 { curr_h - 1 } else { curr_h }
  } where {
    proof_invariant: i >= 0 && i <= n && h >= 0,
    proof_reasoning: (
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
/// Find the contiguous range of SA positions whose suffixes start with `pattern`.
///
/// Because the suffix array is sorted, all matches form a contiguous block
/// `[lo, hi]`. Two binary searches locate the left and right boundaries of
/// that block in O(m log n) time, where m = `pattern.length()`.
///
/// Parameters:
/// - `self`    : the suffix array index to search.
/// - `pattern` : the substring to look for. Must be non-empty.
///
/// Returns `Some((lo, hi))` where `lo` and `hi` are inclusive SA indices such
/// that for every `i` in `lo..=hi`, `text[sa[i]:]` starts with `pattern`.
/// Returns `None` if `pattern` is empty, `text` is empty, or no match exists.
///
/// Time: O(m log n) where m = `pattern.length()` and n = `text.length()`.
pub fn SuffixArray::search(self : SuffixArray, pattern : String) -> (Int, Int)? {
  let n = self.sa.length()
  let m = pattern.length()
  if n == 0 || m == 0 {
    return None
  }

  // Binary search for lower bound
  let first = for lo = 0, hi = n; lo < hi; {
    let mid = (lo + hi) / 2
    let suffix_start = self.sa[mid]
    if compare_suffix(self.text, suffix_start, pattern) < 0 {
      continue mid + 1, hi
    } else {
      continue lo, mid
    }
  } nobreak {
    lo
  }

  // Binary search for upper bound
  let after_last = for lo = first, hi = n; lo < hi; {
    let mid = (lo + hi) / 2
    let suffix_start = self.sa[mid]
    if starts_with(self.text, suffix_start, pattern) {
      continue mid + 1, hi
    } else if compare_suffix(self.text, suffix_start, pattern) < 0 {
      continue mid + 1, hi
    } else {
      continue lo, mid
    }
  } nobreak {
    lo
  }
  let last = after_last - 1
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
  for i in 0..<m {
    if start + i >= n {
      return -1
    }
    if text[start + i] < pattern[i] {
      return -1
    }
    if text[start + i] > pattern[i] {
      return 1
    }
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
  for i in 0..<m {
    if text[start + i] != pattern[i] {
      return false
    }
  }
  true
}

///|
/// Return all start positions in `text` where `pattern` occurs, sorted in
/// ascending order.
///
/// Calls `search` to locate the SA range, then collects and sorts the
/// corresponding text indices. If `pattern` does not appear, returns `[]`.
///
/// Parameters:
/// - `self`    : the suffix array index to search.
/// - `pattern` : the substring to look for.
///
/// Returns an `Array[Int]` of starting positions (0-based) in `text`, sorted
/// ascending. The array is empty when there are no matches.
///
/// Time: O(m log n + k log k) where m = `pattern.length()`, n = `text.length()`,
/// and k = number of matches.
pub fn SuffixArray::find_all(
  self : SuffixArray,
  pattern : String,
) -> Array[Int] {
  match self.search(pattern) {
    None => []
    Some((first, last)) => {
      let result : Array[Int] = [ for i in first..<(last + 1) => self.sa[i] ]
      result.sort_by((a, b) => a - b)
      result
    }
  }
}

///|
/// Count the number of (possibly overlapping) occurrences of `pattern` in
/// `text`.
///
/// Parameters:
/// - `self`    : the suffix array index to search.
/// - `pattern` : the substring to count. Must be non-empty for a non-zero result.
///
/// Returns the number of positions in `text` at which `pattern` starts.
/// Returns 0 when `pattern` is not present or when either string is empty.
///
/// Time: O(m log n) where m = `pattern.length()` and n = `text.length()`.
pub fn SuffixArray::count(self : SuffixArray, pattern : String) -> Int {
  match self.search(pattern) {
    None => 0
    Some((first, last)) => last - first + 1
  }
}

///|
/// Return the longest substring that appears at least twice in `text`.
///
/// The answer is the suffix of length `max(lcp)` starting at the position
/// recorded by the SA entry with the highest LCP value. If no suffix pair
/// shares any common prefix (all LCP values are 0), or if `text` has fewer
/// than two characters, the empty string `""` is returned.
///
/// Parameters:
/// - `self` : the suffix array index to query.
///
/// Returns the longest repeated substring, or `""` if none exists.
///
/// Time: O(n). Space: O(n) for the returned substring.
pub fn SuffixArray::longest_repeated_substring(self : SuffixArray) -> String {
  let n = self.sa.length()
  if n < 2 {
    return ""
  }
  // Find max LCP and its index.
  let (max_idx, max_lcp) = for i in 1..<n; max_idx = 0, max_lcp = 0 {
    if self.lcp[i] > max_lcp {
      continue i, self.lcp[i]
    }
    continue max_idx, max_lcp
  } nobreak {
    (max_idx, max_lcp)
  }
  if max_lcp == 0 {
    return ""
  }
  let start = self.sa[max_idx]
  self.text.unsafe_substring(start~, end=start + max_lcp)
}

///|
/// Count the number of distinct (non-empty) substrings of `text`.
///
/// Uses the identity:
///
/// ```
/// distinct = n*(n+1)/2 - sum(lcp[1..n-1])
/// ```
///
/// Intuition: each suffix of length L introduces L new substrings, but the
/// first `lcp[i]` of them are already counted by the previous suffix in SA
/// order. Subtracting the total LCP sum removes all duplicates.
///
/// Parameters:
/// - `self` : the suffix array index to query.
///
/// Returns the count of distinct substrings as `Int64` (the value can reach
/// n*(n+1)/2 which exceeds `Int` range for large n).
///
/// Time: O(n). Space: O(1).
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
/// Return the i-th lexicographically smallest suffix of `text`.
///
/// Parameters:
/// - `self` : the suffix array index to query.
/// - `i`    : 0-based rank in the sorted suffix order (0 = smallest suffix).
///
/// Returns the suffix string `text[sa[i]:]`, or `""` if `i` is out of range
/// (i.e., `i < 0` or `i >= text.length()`).
///
/// Time: O(n) to construct the returned string. Space: O(n).
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
  let sa = SuffixArray("banana")
  inspect(sa.sa[0], content="5")
  inspect(sa.sa[1], content="3")
  inspect(sa.sa[2], content="1")
  inspect(sa.sa[3], content="0")
  inspect(sa.sa[4], content="4")
  inspect(sa.sa[5], content="2")
}

///|
test "suffix array lcp" {
  let sa = SuffixArray("banana")
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
  let lcp = lcp_array("banana", sa)
  inspect(lcp, content="[0, 1, 3, 0, 0, 2]")
}

///|
test "suffix array search" {
  let sa = SuffixArray("banana")
  let matches = sa.find_all("ana")
  inspect(matches.length(), content="2")
  inspect(matches[0], content="1")
  inspect(matches[1], content="3")
  inspect(sa.count("na"), content="2")
  inspect(sa.count("xyz"), content="0")
}

///|
test "suffix array longest repeated" {
  let sa = SuffixArray("banana")
  inspect(sa.longest_repeated_substring(), content="ana")
  let sa2 = SuffixArray("abcabc")
  inspect(sa2.longest_repeated_substring(), content="abc")
}

///|
test "suffix array distinct substrings" {
  let sa = SuffixArray("banana")
  inspect(sa.count_distinct_substrings(), content="15")
}

///|
test "suffix array empty" {
  let sa = SuffixArray("")
  inspect(sa.sa.length(), content="0")
}

///|
test "suffix array single char" {
  let sa = SuffixArray("a")
  inspect(sa.sa.length(), content="1")
  inspect(sa.sa[0], content="0")
  inspect(sa.count_distinct_substrings(), content="1")
}

///|
test "suffix array all same" {
  let sa = SuffixArray("aaaa")
  inspect(sa.sa[0], content="3")
  inspect(sa.sa[1], content="2")
  inspect(sa.sa[2], content="1")
  inspect(sa.sa[3], content="0")
  inspect(sa.count_distinct_substrings(), content="4")
}

///|
test "suffix array pattern not found" {
  let sa = SuffixArray("banana")
  let matches = sa.find_all("xyz")
  inspect(matches.length(), content="0")
}

///|
test "suffix array get suffix" {
  let sa = SuffixArray("banana")
  inspect(sa.get_suffix(0), content="a")
  inspect(sa.get_suffix(1), content="ana")
  inspect(sa.get_suffix(3), content="banana")
}
