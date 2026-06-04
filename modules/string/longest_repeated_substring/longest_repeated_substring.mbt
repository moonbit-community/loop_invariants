// ============================================================================
// LONGEST REPEATED SUBSTRING  -  via suffix array + LCP
// ============================================================================
//
// PROBLEM
//
// Find the longest substring of `s` that occurs at least twice (with
// allowed overlap unless caller filters). Equivalently, the maximum
// value of `lcp[i]` for adjacent suffixes in the suffix array.
//
// ALGORITHM (Kasai-style)
//
//   1. Build the suffix array `sa` of `s` (O(n log n) via doubling
//      or O(n log^2 n) via straightforward sort).
//   2. Build the longest-common-prefix array `lcp[i] = lcp(s[sa[i]:],
//      s[sa[i+1]:])` in O(n) via Kasai's algorithm.
//   3. Maximum of `lcp` is the answer.
//
// COMPLEXITY
//
//   Time : O(n log^2 n) -- our simple sort-based SA
//   Space: O(n)
//
// THE INVARIANT
//
//   "After sorting, the suffix array sa lists suffix starting indices
//    in lexicographic order; the LCP array gives the longest common
//    prefix between adjacent suffixes."

///|
/// Length plus starting index of the longest repeated substring.
/// Returns `(0, 0)` when no substring occurs twice (i.e., all characters
/// distinct).
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let s = "banana".to_array().map(c => c.to_int())
///   let (len, _) = @longest_repeated_substring.find(s)
///   @debug.assert_eq(len, 3) // "ana"
/// }
/// ```
pub fn find(s : Array[Int]) -> (Int, Int) {
  let n = s.length()
  if n <= 1 {
    return (0, 0)
  }
  let sa = build_sa(s)
  let lcp = build_lcp(s, sa)
  let mut best_len = 0
  let mut best_start = 0
  for i in 0..<lcp.length() {
    if lcp[i] > best_len {
      best_len = lcp[i]
      best_start = sa[i]
    }
  }
  (best_len, best_start)
}

///|
/// Build the suffix array via O(n log^2 n) sort with string compares.
fn build_sa(s : Array[Int]) -> Array[Int] {
  let n = s.length()
  let idx = Array::makei(n, i => i)
  sort_suffixes(idx, s, 0, n)
  idx
}

///|
fn sort_suffixes(arr : Array[Int], s : Array[Int], lo : Int, hi : Int) -> Unit {
  if hi - lo <= 1 {
    return
  }
  let mid = lo + (hi - lo) / 2
  sort_suffixes(arr, s, lo, mid)
  sort_suffixes(arr, s, mid, hi)
  merge_suffixes(arr, s, lo, mid, hi)
}

///|
fn merge_suffixes(
  arr : Array[Int],
  s : Array[Int],
  lo : Int,
  mid : Int,
  hi : Int,
) -> Unit {
  let buf = Array::make(hi - lo, 0)
  let mut i = lo
  let mut j = mid
  let mut k = 0
  while i < mid && j < hi {
    if cmp_suffix(s, arr[i], arr[j]) <= 0 {
      buf[k] = arr[i]
      i = i + 1
    } else {
      buf[k] = arr[j]
      j = j + 1
    }
    k = k + 1
  }
  while i < mid {
    buf[k] = arr[i]
    i = i + 1
    k = k + 1
  }
  while j < hi {
    buf[k] = arr[j]
    j = j + 1
    k = k + 1
  }
  for x in 0..<(hi - lo) {
    arr[lo + x] = buf[x]
  }
}

///|
fn cmp_suffix(s : Array[Int], a : Int, b : Int) -> Int {
  let n = s.length()
  let mut i = a
  let mut j = b
  while i < n && j < n {
    if s[i] < s[j] {
      return -1
    }
    if s[i] > s[j] {
      return 1
    }
    i = i + 1
    j = j + 1
  }
  // Shorter suffix first.
  if i == n && j < n {
    -1
  } else if j == n && i < n {
    1
  } else {
    0
  }
}

///|
fn build_lcp(s : Array[Int], sa : Array[Int]) -> Array[Int] {
  let n = s.length()
  let rank = Array::make(n, 0)
  for i in 0..<n {
    rank[sa[i]] = i
  }
  let lcp = Array::make(n - 1, 0)
  let mut h = 0
  for i in 0..<n {
    if rank[i] > 0 {
      let j = sa[rank[i] - 1]
      while i + h < n && j + h < n && s[i + h] == s[j + h] {
        h = h + 1
      }
      lcp[rank[i] - 1] = h
      if h > 0 {
        h = h - 1
      }
    } else {
      h = 0
    }
  }
  lcp
}

///|
fn s(str : String) -> Array[Int] {
  let r : Array[Int] = []
  for c in str {
    r.push(c.to_int())
  }
  r
}

///|
test "lrs banana" {
  let arr = s("banana")
  let (len, start) = find(arr)
  @debug.assert_eq(len, 3)
  // "ana" occurs at indices 1 and 3; either is a valid start.
  @debug.assert_eq(start == 1 || start == 3, true)
  let expected_chars = [arr[1], arr[2], arr[3]]
  let got_chars = [arr[start], arr[start + 1], arr[start + 2]]
  @debug.assert_eq(got_chars, expected_chars)
}

///|
test "lrs mississippi" {
  let (len, _) = find(s("mississippi"))
  // Longest repeated: "issi" -> length 4.
  @debug.assert_eq(len, 4)
}

///|
test "lrs no repetition" {
  @debug.assert_eq(find(s("abcdef")), (0, 0))
}

///|
test "lrs empty / single" {
  @debug.assert_eq(find([]), (0, 0))
  @debug.assert_eq(find([42]), (0, 0))
}

///|
test "lrs entire string repeats" {
  // "abab" -> "ab" of length 2.
  let (len, _) = find(s("abab"))
  @debug.assert_eq(len, 2)
}

///|
test "lrs reports a correct start" {
  // Verify that arr[start..start+len] occurs at least twice in s.
  let cases : ReadOnlyArray[String] = [
    "banana", "mississippi", "abcabc", "the cat in the hat",
  ]
  for c in cases {
    let arr = s(c)
    let (len, start) = find(arr)
    if len > 0 {
      let mut count = 0
      for i in 0..<=(arr.length() - len) {
        let mut ok = true
        for k in 0..<len {
          if arr[i + k] != arr[start + k] {
            ok = false
            break
          }
        }
        if ok {
          count = count + 1
        }
      }
      @debug.assert_eq(count >= 2, true)
    }
  }
}

///|
test "lrs all same char" {
  // "aaaaa" -> length 4 (longest is "aaaa", repeats at start 0 and 1).
  let (len, _) = find(s("aaaaa"))
  @debug.assert_eq(len, 4)
}
