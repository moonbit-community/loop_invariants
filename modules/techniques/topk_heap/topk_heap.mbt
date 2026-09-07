// ============================================================================
// TOP-K via MIN-HEAP  -  streaming and offline
// ============================================================================
//
// PROBLEM
//
// Given a stream of `Int64` values, maintain the **k largest** seen so
// far in O(k) memory. After processing `n` values, the structure
// supports `O(k log k)` retrieval of those k largest values.
//
// THE TRICK
//
// Use a **min-heap of capacity k**. For each incoming value x:
//
//   if size < k: push(x)
//   elif x > min: replace min with x
//
// At all times the heap contains exactly the k largest values seen so
// far, with the smallest at the root for quick admission decisions.
//
// COMPLEXITY
//
//   add(x) : O(log k)
//   top_k_sorted(): O(k log k) to drain
//
// Offline `top_k(arr, k)` runs a single sweep -> O(n log k).
//
// THE INVARIANT
//
//   "At every moment, the heap stores the top min(size_so_far, k)
//    values seen, with the smallest at the root."

///|
/// Streaming top-k accumulator.
pub struct TopK {
  k : Int
  data : Array[Int64]
}

///|
/// Build an empty accumulator with capacity `k`. `k` is clamped to
/// `0` if negative.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let t = @topk_heap.new(3)
///   for x in [5L, 1L, 7L, 2L, 9L, 3L] {
///     t.add(x)
///   }
///   @debug.assert_eq(t.top_k_sorted(), [9L, 7L, 5L])
/// }
/// ```
pub fn new(k : Int) -> TopK {
  let kk = if k < 0 { 0 } else { k }
  { k: kk, data: [], }
}

///|
/// Capacity (the `k` parameter).
pub fn TopK::capacity(self : TopK) -> Int {
  self.k
}

///|
/// Number of elements currently retained.
pub fn TopK::length(self : TopK) -> Int {
  self.data.length()
}

///|
fn TopK::swap(self : TopK, i : Int, j : Int) -> Unit {
  let t = self.data[i]
  self.data[i] = self.data[j]
  self.data[j] = t
}

///|
fn TopK::sift_up(self : TopK, idx : Int) -> Unit {
  let mut i = idx
  while i > 0 {
    let p = (i - 1) / 2
    if self.data[i] < self.data[p] {
      self.swap(i, p)
      i = p
    } else {
      break
    }
  }
}

///|
fn TopK::sift_down(self : TopK, idx : Int) -> Unit {
  let n = self.data.length()
  let mut i = idx
  while true {
    let l = 2 * i + 1
    let r = 2 * i + 2
    let mut best = i
    if l < n && self.data[l] < self.data[best] {
      best = l
    }
    if r < n && self.data[r] < self.data[best] {
      best = r
    }
    if best == i {
      break
    }
    self.swap(i, best)
    i = best
  }
}

///|
/// Consider a new value. May or may not be retained.
pub fn TopK::add(self : TopK, x : Int64) -> Unit {
  if self.k == 0 {
    return
  }
  let n = self.data.length()
  if n < self.k {
    self.data.push(x)
    self.sift_up(n)
  } else if x > self.data[0] {
    self.data[0] = x
    self.sift_down(0)
  }
}

///|
/// Current top-k values in **descending** order. Does not consume the
/// accumulator (returns a freshly built copy).
pub fn TopK::top_k_sorted(self : TopK) -> Array[Int64] {
  let copy = Array::makei(self.data.length(), i => self.data[i])
  // Sort copy in descending order via insertion sort (small k).
  for i in 1..<copy.length() {
    let key = copy[i]
    let mut j = i - 1
    while j >= 0 && copy[j] < key {
      copy[j + 1] = copy[j]
      j = j - 1
    }
    copy[j + 1] = key
  }
  copy
}

///|
/// One-shot top-k for an offline array.
pub fn top_k(arr : Array[Int64], k : Int) -> Array[Int64] {
  let t = new(k)
  for x in arr {
    t.add(x)
  }
  t.top_k_sorted()
}

///|
test "topk basic" {
  let t = new(3)
  for x in [5L, 1L, 7L, 2L, 9L, 3L] {
    t.add(x)
  }
  @debug.assert_eq(t.top_k_sorted(), [9L, 7L, 5L])
}

///|
test "topk fewer than k" {
  let t = new(5)
  t.add(7L)
  t.add(3L)
  @debug.assert_eq(t.top_k_sorted(), [7L, 3L])
  @debug.assert_eq(t.length(), 2)
}

///|
test "topk empty" {
  @debug.assert_eq(top_k([], 5), [])
}

///|
test "topk k zero" {
  let t = new(0)
  t.add(1L)
  t.add(2L)
  @debug.assert_eq(t.length(), 0)
  @debug.assert_eq(top_k([1L, 2L, 3L], 0), [])
}

///|
test "topk single element" {
  @debug.assert_eq(top_k([42L], 3), [42L])
}

///|
test "topk monotone descending input" {
  @debug.assert_eq(top_k([5L, 4L, 3L, 2L, 1L], 2), [5L, 4L])
}

///|
test "topk agrees with sort" {
  fn naive(arr : Array[Int64], k : Int) -> Array[Int64] {
    let sorted = Array::makei(arr.length(), i => arr[i])
    for i in 1..<sorted.length() {
      let key = sorted[i]
      let mut j = i - 1
      while j >= 0 && sorted[j] < key {
        sorted[j + 1] = sorted[j]
        j = j - 1
      }
      sorted[j + 1] = key
    }
    let kk = if k < arr.length() { k } else { arr.length() }
    Array::makei(kk, i => sorted[i])
  }

  let cases : ReadOnlyArray[Array[Int64]] = [
    [3L, 1L, 4L, 1L, 5L, 9L, 2L, 6L],
    [9L, 8L, 7L, 6L, 5L, 4L, 3L, 2L, 1L],
    [1L, 2L, 3L, 4L, 5L],
    [100L, -50L, 0L, 75L, 25L],
  ]
  for arr in cases {
    for k in 0..<=arr.length() {
      @debug.assert_eq(top_k(arr, k), naive(arr, k))
    }
  }
}
