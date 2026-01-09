// ============================================================================
// SUFFIX ARRAY - Efficient String Processing Data Structure
// ============================================================================
//
// A Suffix Array is a sorted array of all suffixes of a string. Combined with
// the LCP (Longest Common Prefix) array, it enables efficient string operations.
//
// KEY INSIGHT: Sorting all suffixes lexicographically allows binary search for
// pattern matching and enables computation of various string properties.
//
// STRUCTURE:
// For string "banana$":
// Suffixes:
//   0: banana$
//   1: anana$
//   2: nana$
//   3: ana$
//   4: na$
//   5: a$
//   6: $
//
// Sorted (Suffix Array): [6, 5, 3, 1, 0, 4, 2]
//   sa[0]=6: $
//   sa[1]=5: a$
//   sa[2]=3: ana$
//   sa[3]=1: anana$
//   sa[4]=0: banana$
//   sa[5]=4: na$
//   sa[6]=2: nana$
//
// LCP Array: lcp[i] = length of longest common prefix between sa[i] and sa[i-1]
//   lcp[0]=0, lcp[1]=0, lcp[2]=1, lcp[3]=3, lcp[4]=0, lcp[5]=0, lcp[6]=2
//
// OPERATIONS:
// - Build suffix array: O(n log n) using prefix doubling
// - Build LCP array: O(n) using Kasai's algorithm
// - Pattern search: O(m log n) where m is pattern length
// - Count occurrences: O(m log n)
// - Longest repeated substring: O(n)
//
// INVARIANTS:
// 1. sa[i] contains starting index of i-th smallest suffix
// 2. lcp[i] = LCP(s[sa[i-1]..], s[sa[i]..]) for i > 0
// 3. rank[sa[i]] = i (rank is inverse of suffix array)

///|
/// Suffix Array data structure with LCP
priv struct SuffixArray {
  text : String
  sa : Array[Int] // Suffix array
  lcp : Array[Int] // LCP array
  rank : Array[Int] // Inverse suffix array (rank[i] = position of suffix i in sa)
}

///|
/// Build suffix array using prefix doubling algorithm
/// TIME: O(n log n)
/// REASONING: We sort suffixes by their first 2^k characters iteratively.
/// After k iterations, suffixes are sorted by first 2^k characters.
/// Since max length is n, we need O(log n) iterations.
fn SuffixArray::build(text : String) -> SuffixArray {
  let n = text.length()
  if n == 0 {
    return { text, sa: [], lcp: [], rank: [] }
  }

  // Special case for single character
  if n == 1 {
    return { text, sa: [0], lcp: [0], rank: [0] }
  }

  // Initialize rank by character values
  let rank = Array::make(n, 0)
  let sa = Array::make(n, 0)

  for i = 0; i < n; i = i + 1 {
    rank[i] = text[i].to_int()
    sa[i] = i
  }

  // Temporary arrays for sorting
  let tmp_rank = Array::make(n, 0)

  // INVARIANT: After iteration with gap=2^k, suffixes are sorted by first 2^k chars
  // rank[i] encodes the relative order of suffix i among first 2^k characters
  for gap = 1; gap < n; gap = gap * 2 {
    // Sort by (rank[i], rank[i+gap]) pairs
    // This effectively sorts by first 2*gap characters
    
    // Custom comparison for sorting
    fn compare(
      rank : Array[Int],
      n : Int,
      gap : Int,
      i : Int,
      j : Int
    ) -> Int {
      if rank[i] != rank[j] {
        return rank[i] - rank[j]
      }
      let ri = if i + gap < n { rank[i + gap] } else { -1 }
      let rj = if j + gap < n { rank[j + gap] } else { -1 }
      ri - rj
    }

    // Sort suffix array using the comparison function
    // Using simple insertion sort for clarity (could use quicksort for efficiency)
    for i = 1; i < n; i = i + 1 {
      let key = sa[i]
      let mut j = i - 1
      while j >= 0 && compare(rank, n, gap, sa[j], key) > 0 {
        sa[j + 1] = sa[j]
        j = j - 1
      }
      sa[j + 1] = key
    }

    // Update ranks based on new order
    tmp_rank[sa[0]] = 0
    for i = 1; i < n; i = i + 1 {
      let same = compare(rank, n, gap, sa[i - 1], sa[i]) == 0
      tmp_rank[sa[i]] = tmp_rank[sa[i - 1]] + (if same { 0 } else { 1 })
    }

    // Copy tmp_rank to rank
    for i = 0; i < n; i = i + 1 {
      rank[i] = tmp_rank[i]
    }

    // Early termination if all ranks are unique
    if rank[sa[n - 1]] == n - 1 {
      break
    }
  } where {
    invariant: gap >= 1 && gap <= n,
    reasoning: "Gap doubles each iteration; suffixes sorted by first gap chars",
  }

  // Build LCP array using Kasai's algorithm
  let lcp = build_lcp(text, sa, rank)

  { text, sa, lcp, rank }
}

///|
/// Build LCP array using Kasai's algorithm
/// TIME: O(n)
/// REASONING: Key observation is that lcp[rank[i]] >= lcp[rank[i-1]] - 1
/// This allows us to compute LCP values in suffix order, reusing previous computations.
fn build_lcp(text : String, sa : Array[Int], rank : Array[Int]) -> Array[Int] {
  let n = text.length()
  let lcp = Array::make(n, 0)

  // INVARIANT: k is the current LCP length being extended
  // After processing suffix i, lcp[rank[i]] is correctly computed
  let mut k = 0

  for i = 0; i < n; i = i + 1 {
    if rank[i] == 0 {
      k = 0
    } else {
      let j = sa[rank[i] - 1] // Previous suffix in sorted order

      // Extend match from position k
      // INVARIANT: text[i..i+k] == text[j..j+k] from previous iteration
      while i + k < n && j + k < n && text[i + k] == text[j + k] {
        k = k + 1
      }

      lcp[rank[i]] = k

      // Key insight: when we move to suffix i+1, we lose at most one character
      // of the common prefix, so k decreases by at most 1
      if k > 0 {
        k = k - 1
      }
    }
  }

  lcp
}

///|
/// Search for pattern in text, returns range [lo, hi) of matching suffixes
fn SuffixArray::search_range(self : SuffixArray, pattern : String) -> (Int, Int) {
  let n = self.sa.length()
  let m = pattern.length()

  if n == 0 || m == 0 {
    return (0, 0)
  }

  // Binary search for lower bound
  // INVARIANT: All suffixes in [0, lo) are < pattern, all in [hi, n) are >= pattern
  let lo = for lo = 0, hi = n; lo < hi; {
    let mid = (lo + hi) / 2
    if compare_suffix_pattern(self.text, self.sa[mid], pattern) < 0 {
      continue mid + 1, hi
    } else {
      continue lo, mid
    }
  } else {
    lo
  }

  // Binary search for upper bound
  // INVARIANT: All suffixes in [0, lo2) have pattern as prefix, all in [hi2, n) don't
  let hi = for lo2 = lo, hi2 = n; lo2 < hi2; {
    let mid = (lo2 + hi2) / 2
    if compare_suffix_pattern_prefix(self.text, self.sa[mid], pattern) {
      continue mid + 1, hi2
    } else {
      continue lo2, mid
    }
  } else {
    lo2
  }

  (lo, hi)
}

///|
/// Compare suffix starting at pos with pattern (lexicographically)
fn compare_suffix_pattern(text : String, pos : Int, pattern : String) -> Int {
  let n = text.length()
  let m = pattern.length()

  for i = 0; i < m; i = i + 1 {
    if pos + i >= n {
      return -1 // Suffix is shorter, so it's smaller
    }
    let tc = text[pos + i].to_int()
    let pc = pattern[i].to_int()
    if tc != pc {
      return tc - pc
    }
  }
  0 // Pattern is prefix of suffix
}

///|
/// Check if pattern is a prefix of suffix starting at pos
fn compare_suffix_pattern_prefix(text : String, pos : Int, pattern : String) -> Bool {
  let n = text.length()
  let m = pattern.length()

  if pos + m > n {
    return false
  }

  for i = 0; i < m; i = i + 1 {
    if text[pos + i] != pattern[i] {
      return false
    }
  }
  true
}

///|
/// Search for pattern and return all starting positions
fn SuffixArray::search(self : SuffixArray, pattern : String) -> Array[Int] {
  let (lo, hi) = self.search_range(pattern)
  let result : Array[Int] = []
  for i = lo; i < hi; i = i + 1 {
    result.push(self.sa[i])
  }
  result.sort_by(fn(a, b) { a - b })
  result
}

///|
/// Count occurrences of pattern
fn SuffixArray::count(self : SuffixArray, pattern : String) -> Int {
  let (lo, hi) = self.search_range(pattern)
  hi - lo
}

///|
/// Check if pattern exists in text
fn SuffixArray::contains(self : SuffixArray, pattern : String) -> Bool {
  self.count(pattern) > 0
}

///|
/// Find longest repeated substring
/// Returns (start_pos, length)
fn SuffixArray::longest_repeated_substring(self : SuffixArray) -> (Int, Int) {
  let n = self.lcp.length()
  if n <= 1 {
    return (0, 0)
  }

  // Find maximum in LCP array
  let (max_pos, max_len) = for i = 1, max_pos = 0, max_len = 0; i < n; i = i + 1 {
    if self.lcp[i] > max_len {
      continue i + 1, i, self.lcp[i]
    } else {
      continue i + 1, max_pos, max_len
    }
  } else {
    (max_pos, max_len)
  }

  if max_len == 0 {
    return (0, 0)
  }

  (self.sa[max_pos], max_len)
}

///|
/// Find longest common prefix between two suffixes
fn SuffixArray::lcp_of(self : SuffixArray, i : Int, j : Int) -> Int {
  if i == j {
    return self.text.length() - i
  }

  let ri = self.rank[i]
  let rj = self.rank[j]
  let lo = if ri < rj { ri } else { rj }
  let hi = if ri > rj { ri } else { rj }

  // LCP(i, j) = min(lcp[lo+1..hi])
  // INVARIANT: result is minimum LCP in processed range
  for k = lo + 1, result = self.lcp[lo + 1]; k <= hi; k = k + 1 {
    if self.lcp[k] < result {
      continue k + 1, self.lcp[k]
    } else {
      continue k + 1, result
    }
  } else {
    result
  }
}

///|
fn SuffixArray::length(self : SuffixArray) -> Int {
  self.text.length()
}

///|
fn SuffixArray::get_suffix(self : SuffixArray, rank : Int) -> String {
  let pos = self.sa[rank]
  (try! self.text[pos:]).to_string()
}

///|
/// Get k-th smallest suffix starting position
fn SuffixArray::kth_suffix(self : SuffixArray, k : Int) -> Int {
  self.sa[k]
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "suffix array build" {
  let sa = SuffixArray::build("banana")

  inspect(sa.length(), content="6")

  // Verify suffix array is correctly sorted
  // Suffixes in sorted order: a, ana, anana, banana, na, nana
  // Positions: 5, 3, 1, 0, 4, 2
  inspect(sa.sa, content="[5, 3, 1, 0, 4, 2]")
}

///|
test "suffix array search" {
  let sa = SuffixArray::build("mississippi")

  // Search for "issi"
  let matches = sa.search("issi")
  inspect(matches, content="[1, 4]") // positions 1 and 4

  // Search for "ss"
  let matches2 = sa.search("ss")
  inspect(matches2, content="[2, 5]")

  // Count occurrences
  inspect(sa.count("i"), content="4")
  inspect(sa.count("ss"), content="2")
  inspect(sa.count("xyz"), content="0")
}

///|
test "suffix array contains" {
  let sa = SuffixArray::build("hello world")

  inspect(sa.contains("world"), content="true")
  inspect(sa.contains("hello"), content="true")
  inspect(sa.contains("xyz"), content="false")
  inspect(sa.contains("lo wo"), content="true")
}

///|
test "suffix array lcp" {
  let sa = SuffixArray::build("banana")

  // LCP array for banana (suffixes sorted):
  // a, ana, anana, banana, na, nana
  // LCP: 0, 1, 3, 0, 0, 2
  inspect(sa.lcp, content="[0, 1, 3, 0, 0, 2]")
}

///|
test "suffix array longest repeated substring" {
  let sa = SuffixArray::build("banana")

  // Longest repeated substring is "ana" (appears at positions 1 and 3)
  let (pos, len) = sa.longest_repeated_substring()
  inspect(len, content="3")

  // Verify the substring
  let substr = (try! sa.text[pos:pos + len]).to_string()
  inspect(substr, content="ana")
}

///|
test "suffix array lcp of two positions" {
  let sa = SuffixArray::build("abcabc")

  // LCP of suffix at 0 (abcabc) and suffix at 3 (abc) should be 3
  inspect(sa.lcp_of(0, 3), content="3")

  // LCP of same position should be remaining length
  inspect(sa.lcp_of(2, 2), content="4") // "cabc" has length 4
}

///|
test "suffix array get suffix" {
  let sa = SuffixArray::build("hello")

  // Get smallest suffix (should be "ello" since 'e' < 'h' < 'l' < 'o')
  // Actually sorted: ello, hello, llo, lo, o
  inspect(sa.get_suffix(0), content="ello")
  inspect(sa.get_suffix(1), content="hello")
  inspect(sa.get_suffix(4), content="o")
}

///|
test "suffix array empty" {
  let sa = SuffixArray::build("")

  inspect(sa.length(), content="0")
  inspect(sa.sa, content="[]")
  inspect(sa.search("abc"), content="[]")
}

///|
test "suffix array single char" {
  let sa = SuffixArray::build("a")

  inspect(sa.sa, content="[0]")
  inspect(sa.lcp, content="[0]")
  inspect(sa.search("a"), content="[0]")
  inspect(sa.search("b"), content="[]")
}

///|
test "suffix array repeated char" {
  let sa = SuffixArray::build("aaaa")

  // All suffixes start with 'a', sorted by length
  // a, aa, aaa, aaaa -> positions 3, 2, 1, 0
  inspect(sa.sa, content="[3, 2, 1, 0]")

  // LCP: 0, 1, 2, 3 (increasing overlap)
  inspect(sa.lcp, content="[0, 1, 2, 3]")

  // Longest repeated is "aaa"
  let (_, len) = sa.longest_repeated_substring()
  inspect(len, content="3")
}

///|
test "suffix array kth suffix" {
  let sa = SuffixArray::build("abc")

  // Sorted suffixes: abc, bc, c -> positions 0, 1, 2
  inspect(sa.kth_suffix(0), content="0")
  inspect(sa.kth_suffix(1), content="1")
  inspect(sa.kth_suffix(2), content="2")
}

///|
test "suffix array pattern at end" {
  let sa = SuffixArray::build("abcdef")

  inspect(sa.contains("def"), content="true")
  inspect(sa.contains("ef"), content="true")
  inspect(sa.contains("f"), content="true")
  inspect(sa.search("f"), content="[5]")
}

///|
test "suffix array pattern at start" {
  let sa = SuffixArray::build("abcdef")

  inspect(sa.contains("abc"), content="true")
  inspect(sa.contains("ab"), content="true")
  inspect(sa.contains("a"), content="true")
  inspect(sa.search("a"), content="[0]")
}
