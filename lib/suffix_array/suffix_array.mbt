// ============================================================================
// SUFFIX ARRAY - Efficient String Indexing
// ============================================================================
//
// A suffix array is a sorted array of all suffixes of a string.
// Combined with LCP (Longest Common Prefix) array, it enables
// powerful string algorithms.
//
// CONSTRUCTION (Prefix Doubling):
// Sort by first 1, 2, 4, 8... characters iteratively.
//
// KEY INSIGHT: If we know the order of length-k prefixes, we can
// compute length-2k order using pairs (rank[i], rank[i+k]).
//
// INVARIANTS:
// 1. sa[i] gives the starting position of the i-th smallest suffix
// 2. rank[i] gives the rank of suffix starting at position i
// 3. lcp[i] = length of longest common prefix of sa[i] and sa[i-1]
//
// TIME COMPLEXITY: O(n log n) construction
// SPACE COMPLEXITY: O(n)

///|
priv struct SuffixArray {
  sa : Array[Int]      // Suffix array
  rank : Array[Int]    // Rank array
  lcp : Array[Int]     // LCP array
  n : Int
}

///|
/// Build suffix array using prefix doubling (functional style)
fn SuffixArray::build(s : String) -> SuffixArray {
  let n = s.length()
  if n == 0 {
    return { sa: [], rank: [], lcp: [], n: 0 }
  }

  // Special case for single character
  if n == 1 {
    return { sa: [0], rank: [0], lcp: [0], n: 1 }
  }

  // Initialize ranks with character values
  let initial_rank = Array::makei(n, fn(i) { s[i].to_int() })

  // Prefix doubling using functional for loop
  let (final_sa, final_rank) = for k = 1, rank = initial_rank; k < n; k = k * 2 {
    // Create suffix indices with their sort keys
    let suffixes = Array::makei(n, fn(i) {
      let second_rank = if i + k < n { rank[i + k] } else { -1 }
      (i, rank[i], second_rank)
    })

    // Sort by (first_rank, second_rank)
    suffixes.sort_by_key(fn(t) { (t.1, t.2) })

    // Compute new ranks
    let new_rank = Array::make(n, 0)
    new_rank[suffixes[0].0] = 0

    for i = 1; i < n; i = i + 1 {
      let prev = suffixes[i - 1]
      let curr = suffixes[i]
      new_rank[curr.0] = if curr.1 == prev.1 && curr.2 == prev.2 {
        new_rank[prev.0]
      } else {
        new_rank[prev.0] + 1
      }
    }

    // Check if all ranks are unique
    if new_rank[suffixes[n - 1].0] == n - 1 {
      break (Array::makei(n, fn(i) { suffixes[i].0 }), new_rank)
    }

    continue k * 2, new_rank
  } else {
    // Build final SA from rank
    let sa = Array::make(n, 0)
    for i = 0; i < n; i = i + 1 {
      sa[rank[i]] = i
    }
    (sa, rank)
  }

  // Compute LCP array using Kasai's algorithm
  let lcp = compute_lcp(s, final_sa, final_rank)

  { sa: final_sa, rank: final_rank, lcp, n }
}

///|
/// Kasai's algorithm for LCP array (functional style)
fn compute_lcp(s : String, sa : Array[Int], rank : Array[Int]) -> Array[Int] {
  let n = s.length()
  let lcp = Array::make(n, 0)

  // Functional for loop with state
  for i = 0, k = 0; i < n; {
    if rank[i] == 0 {
      continue i + 1, 0
    }

    let j = sa[rank[i] - 1]
    let new_k = for h = k; i + h < n && j + h < n && s[i + h] == s[j + h]; {
      continue h + 1
    } else {
      h
    }

    lcp[rank[i]] = new_k
    continue i + 1, if new_k > 0 { new_k - 1 } else { 0 }
  } else {
    lcp
  }
}

///|
/// Count occurrences of pattern in text using binary search
fn SuffixArray::count(self : SuffixArray, text : String, pattern : String) -> Int {
  let (lo, hi) = self.search_range(text, pattern)
  if lo <= hi { hi - lo + 1 } else { 0 }
}

///|
/// Find range of suffixes that start with pattern
fn SuffixArray::search_range(self : SuffixArray, text : String, pattern : String) -> (Int, Int) {
  let lo = self.lower_bound(text, pattern)
  let hi = self.upper_bound(text, pattern)
  (lo, hi - 1)
}

///|
fn SuffixArray::lower_bound(self : SuffixArray, text : String, pattern : String) -> Int {
  for lo = 0, hi = self.n; lo < hi; {
    let mid = (lo + hi) / 2
    if compare_suffix(text, self.sa[mid], pattern) < 0 {
      continue mid + 1, hi
    } else {
      continue lo, mid
    }
  } else {
    lo
  }
}

///|
fn SuffixArray::upper_bound(self : SuffixArray, text : String, pattern : String) -> Int {
  for lo = 0, hi = self.n; lo < hi; {
    let mid = (lo + hi) / 2
    if compare_suffix(text, self.sa[mid], pattern) <= 0 {
      continue mid + 1, hi
    } else {
      continue lo, mid
    }
  } else {
    lo
  }
}

///|
/// Compare suffix starting at pos with pattern
fn compare_suffix(text : String, pos : Int, pattern : String) -> Int {
  let text_len = text.length()
  let pat_len = pattern.length()

  for i = 0; i < pat_len && pos + i < text_len; {
    let tc = text[pos + i]
    let pc = pattern[i]
    if tc < pc {
      break -1
    } else if tc > pc {
      break 1
    } else {
      continue i + 1
    }
  } else {
    if pos + pat_len <= text_len { 0 } else { -1 }
  }
}

///|
/// Find all occurrences of pattern
fn SuffixArray::find_all(self : SuffixArray, text : String, pattern : String) -> Array[Int] {
  let (lo, hi) = self.search_range(text, pattern)
  if lo > hi {
    []
  } else {
    Array::makei(hi - lo + 1, fn(i) { self.sa[lo + i] })
  }
}

///|
/// Find longest repeated substring using LCP array
fn SuffixArray::longest_repeated_substring(self : SuffixArray, text : String) -> String {
  if self.n <= 1 {
    return ""
  }

  // Find maximum LCP value using functional for
  let (max_lcp, max_idx) = for i = 1, best_lcp = 0, best_idx = 0; i < self.n; {
    if self.lcp[i] > best_lcp {
      continue i + 1, self.lcp[i], i
    } else {
      continue i + 1, best_lcp, best_idx
    }
  } else {
    (best_lcp, best_idx)
  }

  if max_lcp == 0 {
    ""
  } else {
    text.substring(start=self.sa[max_idx], end=self.sa[max_idx] + max_lcp)
  }
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "suffix array build" {
  let sa = SuffixArray::build("banana")
  // Suffixes sorted: a, ana, anana, banana, na, nana
  // Positions:       5, 3,   1,     0,      4,  2
  inspect(sa.sa[0], content="5")
  inspect(sa.sa[1], content="3")
  inspect(sa.sa[2], content="1")
}

///|
test "suffix array count" {
  let text = "mississippi"
  let sa = SuffixArray::build(text)

  inspect(sa.count(text, "issi"), content="2")
  inspect(sa.count(text, "ss"), content="2")
  inspect(sa.count(text, "xyz"), content="0")
}

///|
test "suffix array find all" {
  let text = "abracadabra"
  let sa = SuffixArray::build(text)

  let positions = sa.find_all(text, "abra")
  inspect(positions.length(), content="2")
  let sorted = positions.copy()
  sorted.sort()
  inspect(sorted[0], content="0")
  inspect(sorted[1], content="7")
}

///|
test "suffix array lcp" {
  let text = "banana"
  let sa = SuffixArray::build(text)
  inspect(sa.lcp[1], content="1")
  inspect(sa.lcp[2], content="3")
}

///|
test "suffix array longest repeated" {
  let text = "banana"
  let sa = SuffixArray::build(text)
  let lrs = sa.longest_repeated_substring(text)
  inspect(lrs, content="ana")
}

///|
test "suffix array empty" {
  let sa = SuffixArray::build("")
  inspect(sa.n, content="0")
}

///|
test "suffix array single char" {
  let sa = SuffixArray::build("a")
  inspect(sa.n, content="1")
  inspect(sa.sa[0], content="0")
}
