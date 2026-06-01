// ============================================================================
// BURROWS-WHEELER TRANSFORM (BWT)  -  Burrows & Wheeler 1994
// ============================================================================
//
// PROBLEM
//
// Convert a string `s` into a permutation `bwt(s)` that is **highly
// run-length-compressible** -- the foundation of `bzip2`.
//
// THE FORWARD TRANSFORM
//
//   1. Form all cyclic rotations of `s` (preceded by a unique
//      end-of-text sentinel `$` so the transform is one-to-one).
//   2. Sort the rotations lexicographically.
//   3. The BWT is the last column of the sorted table.
//
// The output usually has long runs because, in a sorted table of
// rotations, rows that begin with the same prefix tend to be adjacent,
// so their *last* characters (the character preceding each prefix in
// the original text) tend to be the same.
//
// THE INVERSE TRANSFORM (Burrows-Wheeler Inverse, BWI)
//
// Reconstruct `s` from `bwt` and the index of the original rotation
// (or the position of `$`). The trick uses the **first-column** /
// **last-column** correspondence:
//
//   The k-th occurrence of character c in the last column corresponds
//   to the k-th occurrence of c in the first column. So we can walk
//   backwards through s by following these links.
//
// SIMPLE n^2 log n CONSTRUCTION (used here)
//
// We use a straightforward O(n^2 log n) construction: explicitly sort
// rotations as `Array[Int]` view objects with a lexicographic compare.
// Linear-time suffix-array-based BWT construction is out of scope.
//
// COMPLEXITY
//
//   transform  : O(n^2 log n) -- explicit sorting of rotations
//   inverse    : O(n) + O(n log n) for sorting characters
//
// THE INVARIANT
//
//   "After sorting, row i of the rotation table starts with the same
//    suffix(es) shared with row i-1, so transitions between adjacent
//    rows in the last column reflect short-range structure in s."

///|
const SENTINEL : Int = -1

///|
/// Forward BWT. Returns the transformed array. Marker `-1` is used as
/// the unique end-of-text sentinel and ends up *somewhere* in the
/// transform. The sentinel is implicitly appended; callers should not
/// include it in `text`.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   // BWT of "banana": the transformed array contains the famous
///   // run-heavy ordering.
///   let s = "banana".to_array().map(c => c.to_int())
///   let bwt = @burrows_wheeler.transform(s)
///   @debug.assert_eq(bwt.length(), s.length() + 1)
/// }
/// ```
pub fn transform(text : Array[Int]) -> Array[Int] {
  let n = text.length() + 1
  // Build extended text with sentinel at the end.
  let ext = Array::make(n, 0)
  for i in 0..<(n - 1) {
    ext[i] = text[i]
  }
  ext[n - 1] = SENTINEL
  // Indices of all rotations.
  let rot = Array::makei(n, i => i)
  // Sort rotations by lex order of their starting position in ext.
  sort_rotations(rot, ext, 0, n)
  let bwt = Array::make(n, 0)
  for i in 0..<n {
    // The "last character" of rotation starting at rot[i] is ext[rot[i] - 1 mod n].
    let last = if rot[i] == 0 { n - 1 } else { rot[i] - 1 }
    bwt[i] = ext[last]
  }
  bwt
}

///|
fn cmp_rotations(ext : Array[Int], a : Int, b : Int) -> Int {
  let n = ext.length()
  let mut k = 0
  while k < n {
    let ca = ext[(a + k) % n]
    let cb = ext[(b + k) % n]
    if ca < cb {
      return -1
    }
    if ca > cb {
      return 1
    }
    k = k + 1
  }
  0
}

///|
fn sort_rotations(
  rot : Array[Int],
  ext : Array[Int],
  lo : Int,
  hi : Int,
) -> Unit {
  if hi - lo <= 1 {
    return
  }
  let mid = lo + (hi - lo) / 2
  sort_rotations(rot, ext, lo, mid)
  sort_rotations(rot, ext, mid, hi)
  merge_rot(rot, ext, lo, mid, hi)
}

///|
fn merge_rot(
  rot : Array[Int],
  ext : Array[Int],
  lo : Int,
  mid : Int,
  hi : Int,
) -> Unit {
  let buf = Array::make(hi - lo, 0)
  let mut i = lo
  let mut j = mid
  let mut k = 0
  while i < mid && j < hi {
    if cmp_rotations(ext, rot[i], rot[j]) <= 0 {
      buf[k] = rot[i]
      i = i + 1
    } else {
      buf[k] = rot[j]
      j = j + 1
    }
    k = k + 1
  }
  while i < mid {
    buf[k] = rot[i]
    i = i + 1
    k = k + 1
  }
  while j < hi {
    buf[k] = rot[j]
    j = j + 1
    k = k + 1
  }
  for x in 0..<(hi - lo) {
    rot[lo + x] = buf[x]
  }
}

///|
/// Inverse BWT: reconstruct the original text from its BWT (with
/// embedded sentinel `-1`). Returns the array *without* the sentinel.
///
/// Uses the LF-mapping: for each character, the k-th occurrence in
/// the last column equals the k-th occurrence in the first column.
pub fn inverse_transform(bwt : Array[Int]) -> Array[Int] {
  let n = bwt.length()
  // First column = sorted bwt.
  let first = Array::makei(n, i => bwt[i])
  sort_ints(first, 0, n)
  // For each row i, lf[i] gives the row in the first column whose
  // character matches bwt[i] and has the same rank.
  // Compute by counting occurrences.
  // Build rank-of-last for each position.
  let count : Map[Int, Int] = Map([], capacity=n)
  let lf = Array::make(n, 0)
  // Build a mapping: for each (char, k), record the first-column index.
  // Strategy: for each i in [0, n), let r be the rank-among-equals of
  // bwt[i] (i.e. how many bwt[j] for j < i equal bwt[i]). Then lf[i] =
  // first[c] + r, where first[c] = index of the first row whose first
  // char is c. Since first is sorted, we can derive these on the fly.
  let first_pos : Map[Int, Int] = Map([], capacity=n)
  for i in 0..<n {
    if !first_pos.contains(first[i]) {
      first_pos[first[i]] = i
    }
  }
  let rank = Array::make(n, 0)
  for i in 0..<n {
    let c = bwt[i]
    let k = count.get_or_init(c, () => 0)
    rank[i] = k
    count[c] = k + 1
  }
  for i in 0..<n {
    let c = bwt[i]
    lf[i] = first_pos.get_or_init(c, () => 0) + rank[i]
  }
  // Walk backwards from the sentinel row.
  let mut sentinel_row = 0
  for i in 0..<n {
    if bwt[i] == SENTINEL {
      sentinel_row = i
      break
    }
  }
  // Build the text in reverse: start at the sentinel row, follow lf.
  let result : Array[Int] = []
  let mut idx = sentinel_row
  for _ in 0..<(n - 1) {
    idx = lf[idx]
    result.push(bwt[idx])
  }
  // Reverse.
  let mut i = 0
  let mut j = result.length() - 1
  while i < j {
    let t = result[i]
    result[i] = result[j]
    result[j] = t
    i = i + 1
    j = j - 1
  }
  result
}

///|
fn sort_ints(arr : Array[Int], lo : Int, hi : Int) -> Unit {
  if hi - lo <= 1 {
    return
  }
  let mid = lo + (hi - lo) / 2
  sort_ints(arr, lo, mid)
  sort_ints(arr, mid, hi)
  let buf = Array::make(hi - lo, 0)
  let mut i = lo
  let mut j = mid
  let mut k = 0
  while i < mid && j < hi {
    if arr[i] <= arr[j] {
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
fn s(str : String) -> Array[Int] {
  let r : Array[Int] = []
  for c in str {
    r.push(c.to_int())
  }
  r
}

///|
test "bwt roundtrip banana" {
  let orig = s("banana")
  let bwt = transform(orig)
  let back = inverse_transform(bwt)
  @debug.assert_eq(back, orig)
}

///|
test "bwt roundtrip various" {
  let cases : ReadOnlyArray[String] = [
    "abracadabra", "mississippi", "hello", "a", "ab", "aaaaaa", "the quick brown fox",
  ]
  for c in cases {
    let orig = s(c)
    let bwt = transform(orig)
    let back = inverse_transform(bwt)
    @debug.assert_eq(back, orig)
  }
}

///|
test "bwt roundtrip empty" {
  let orig = s("")
  let bwt = transform(orig)
  // Just one row (the sentinel alone).
  @debug.assert_eq(bwt.length(), 1)
  let back = inverse_transform(bwt)
  @debug.assert_eq(back, [])
}

///|
test "bwt produces runs on aaaaab" {
  // "aaaaab" -> rotations include "aaaaab$", "aaaab$a", ...
  let orig = s("aaaaab")
  let bwt = transform(orig)
  // The 'b' should appear early in BWT (after the row starting with $).
  // Just check we can round-trip.
  let back = inverse_transform(bwt)
  @debug.assert_eq(back, orig)
}

///|
test "bwt sentinel appears once" {
  let orig = s("hello world")
  let bwt = transform(orig)
  let mut count = 0
  for c in bwt {
    if c == -1 {
      count = count + 1
    }
  }
  @debug.assert_eq(count, 1)
}
