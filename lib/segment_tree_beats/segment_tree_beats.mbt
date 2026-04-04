// ============================================================================
// SEGMENT TREE BEATS - Range chmin with max/sum queries
// ============================================================================
//
// Segment tree beats maintains, for each node covering interval [l, r):
//
//   max        = largest value in the interval
//   second_max = second largest (strictly < max), or NEG_INF if all equal
//   count_max  = number of elements that equal max
//   sum        = sum of all values in the interval
//
// KEY INSIGHT (the "beats" condition):
//   For range_chmin(x) on a node, check against second_max:
//
//   Case A  x >= max          -> no-op, nothing changes
//   Case B  second_max < x < max -> only max-elements are affected;
//                                   update sum and max in O(1) without
//                                   descending (this is the "tag")
//   Case C  x <= second_max   -> must push tag and recurse into children
//
// COMPLEXITY:
//   range_chmin : O(log^2 n) amortized
//   range_max   : O(log n)
//   range_sum   : O(log n)
//   Space       : O(n)

///|
/// Sentinel value used for `second_max` when no second-largest element exists
/// (e.g. a leaf node or a segment where all elements are equal).
const NEG_INF : Int64 = -9223372036854775807L

///|
fn max_i64(a : Int64, b : Int64) -> Int64 {
  if a > b {
    a
  } else {
    b
  }
}

/// A segment tree that supports range chmin updates together with range sum and
/// range max queries, all in amortized O(log^2 n) time.
///
/// Each internal node stores four aggregates for its covered segment `[l, r)`:
///
/// - `max`        — largest element value
/// - `second_max` — second largest value (strictly less than max), or `NEG_INF`
///                  when all elements are equal or the segment is a single leaf
/// - `count_max`  — number of elements whose value equals `max`
/// - `sum`        — total sum of all elements
///
/// The tree is 1-indexed and backed by four flat arrays of size `4 * n`.
/// Node `k` has left child `2k` and right child `2k + 1`.
///
/// All ranges passed to public methods use the **half-open** convention:
/// `[l, r)` covers indices `l, l+1, ..., r-1`.
pub struct SegmentTreeBeats {
  n : Int
  max : Array[Int64]
  second_max : Array[Int64]
  count_max : Array[Int]
  sum : Array[Int64]
}

///|
/// Build a `SegmentTreeBeats` from a slice of `Int64` values.
///
/// The resulting tree covers the half-open range `[0, values.length())`.
/// Construction runs in O(n) time.
///
/// Parameters:
/// - `values` — the initial array; may be empty, in which case all queries
///              return identity values (0 for sum, `NEG_INF` for max).
pub fn SegmentTreeBeats::new(values : ArrayView[Int64]) -> SegmentTreeBeats {
  let n = values.length()
  let size = if n == 0 { 0 } else { 4 * n }
  let max = Array::make(size, NEG_INF)
  let second_max = Array::make(size, NEG_INF)
  let count_max = Array::make(size, 0)
  let sum = Array::make(size, 0L)
  let st : SegmentTreeBeats = { n, max, second_max, count_max, sum }
  if n > 0 {
    st.build(1, 0, n, values)
  }
  st
}

///|
fn SegmentTreeBeats::build(
  self : SegmentTreeBeats,
  node : Int,
  l : Int,
  r : Int,
  values : ArrayView[Int64],
) -> Unit {
  if r - l == 1 {
    let v = values[l]
    self.max[node] = v
    self.second_max[node] = NEG_INF
    self.count_max[node] = 1
    self.sum[node] = v
  } else {
    let mid = (l + r) / 2
    self.build(node * 2, l, mid, values)
    self.build(node * 2 + 1, mid, r, values)
    self.pull(node)
  }
}

///|
/// Recompute the four aggregates of `node` from its two children.
///
/// Must be called after any modification to a child node.  This is the
/// bottom-up merge step:
///
/// - `sum`        = sum[left] + sum[right]
/// - When one child's max dominates, inherit its `max` and `count_max`, and
///   set `second_max` to the larger of the other child's max and the dominant
///   child's own `second_max`.
/// - When both children share the same max, add their `count_max` values and
///   take the larger of their `second_max` values.
fn SegmentTreeBeats::pull(self : SegmentTreeBeats, node : Int) -> Unit {
  let left = node * 2
  let right = left + 1
  let left_max = self.max[left]
  let right_max = self.max[right]
  self.sum[node] = self.sum[left] + self.sum[right]
  if left_max > right_max {
    self.max[node] = left_max
    self.count_max[node] = self.count_max[left]
    self.second_max[node] = max_i64(self.second_max[left], right_max)
  } else if left_max < right_max {
    self.max[node] = right_max
    self.count_max[node] = self.count_max[right]
    self.second_max[node] = max_i64(self.second_max[right], left_max)
  } else {
    self.max[node] = left_max
    self.count_max[node] = self.count_max[left] + self.count_max[right]
    self.second_max[node] = max_i64(
      self.second_max[left],
      self.second_max[right],
    )
  }
}

///|
/// Apply a chmin tag to `node` under the Case-B precondition.
///
/// Precondition: `second_max[node] < x < max[node]`.
///
/// Because only the `count_max` elements currently equal to `max` will be
/// lowered to `x`, the update is exact and O(1):
///
/// ```
/// sum  -= count_max * (max - x)
/// max   = x
/// ```
///
/// `second_max` and `count_max` remain unchanged; a future `push` call will
/// propagate this tag to the children when needed.
fn SegmentTreeBeats::apply_chmin(
  self : SegmentTreeBeats,
  node : Int,
  x : Int64,
) -> Unit {
  let max_val = self.max[node]
  if x >= max_val {
    return
  }
  let diff = max_val - x
  self.sum[node] = self.sum[node] - diff * self.count_max[node].to_int64()
  self.max[node] = x
}

///|
/// Propagate any pending chmin tag from `node` down to its two children.
///
/// The tag is stored implicitly as `max[node]`.  If a child's `max` exceeds
/// the parent's `max`, the parent's constraint has not yet been applied to that
/// child, so we call `apply_chmin` on it.
///
/// The precondition `max[node] > second_max[child]` is guaranteed by the tree
/// invariant, so each `apply_chmin` call here is always a Case-B operation and
/// runs in O(1).
///
/// Must be called before descending into children during an update or query
/// that cannot be served from the current node alone.
fn SegmentTreeBeats::push(self : SegmentTreeBeats, node : Int) -> Unit {
  let max_val = self.max[node]
  let left = node * 2
  let right = left + 1
  if self.max[left] > max_val {
    self.apply_chmin(left, max_val)
  }
  if self.max[right] > max_val {
    self.apply_chmin(right, max_val)
  }
}

///|
/// Clamp every element in `[l, r)` to at most `x`.
///
/// Formally, for each index `i` in `[l, r)`, sets `a[i] = min(a[i], x)`.
/// Indices outside `[l, r)` are unaffected.
///
/// Parameters:
/// - `l` — inclusive left endpoint (0-indexed)
/// - `r` — exclusive right endpoint; the range is `[l, r)`
/// - `x` — the upper cap to apply
///
/// If `l >= r` or the tree is empty the call is a no-op.
///
/// Complexity: amortized O(log^2 n).
pub fn SegmentTreeBeats::range_chmin(
  self : SegmentTreeBeats,
  l : Int,
  r : Int,
  x : Int64,
) -> Unit {
  if self.n == 0 || l >= r {
    return
  }
  self.chmin_impl(1, 0, self.n, l, r, x)
}

///|
/// Recursive implementation of range chmin for the subtree rooted at `node`,
/// which covers segment `[l, r)`, against the query range `[ql, qr)`.
///
/// Decision logic at each node:
///
/// - No overlap with `[ql, qr)`, or `x >= max[node]`  ->  return immediately (Case A).
/// - Full overlap and `x > second_max[node]`           ->  apply tag in O(1) (Case B).
/// - Otherwise                                          ->  push, recurse, pull (Case C).
fn SegmentTreeBeats::chmin_impl(
  self : SegmentTreeBeats,
  node : Int,
  l : Int,
  r : Int,
  ql : Int,
  qr : Int,
  x : Int64,
) -> Unit {
  if qr <= l || r <= ql || x >= self.max[node] {
    return
  }
  if ql <= l && r <= qr && x > self.second_max[node] {
    self.apply_chmin(node, x)
    return
  }
  let mid = (l + r) / 2
  self.push(node)
  self.chmin_impl(node * 2, l, mid, ql, qr, x)
  self.chmin_impl(node * 2 + 1, mid, r, ql, qr, x)
  self.pull(node)
}

///|
/// Return the maximum element value in `[l, r)`.
///
/// Parameters:
/// - `l` — inclusive left endpoint (0-indexed)
/// - `r` — exclusive right endpoint; the range is `[l, r)`
///
/// Returns `NEG_INF` when `l >= r` or the tree is empty.
///
/// Complexity: O(log n).
pub fn SegmentTreeBeats::range_max(
  self : SegmentTreeBeats,
  l : Int,
  r : Int,
) -> Int64 {
  if self.n == 0 || l >= r {
    return NEG_INF
  }
  self.max_impl(1, 0, self.n, l, r)
}

///|
fn SegmentTreeBeats::max_impl(
  self : SegmentTreeBeats,
  node : Int,
  l : Int,
  r : Int,
  ql : Int,
  qr : Int,
) -> Int64 {
  if qr <= l || r <= ql {
    return NEG_INF
  }
  if ql <= l && r <= qr {
    return self.max[node]
  }
  let mid = (l + r) / 2
  self.push(node)
  let left = self.max_impl(node * 2, l, mid, ql, qr)
  let right = self.max_impl(node * 2 + 1, mid, r, ql, qr)
  max_i64(left, right)
}

///|
/// Query sum on [l, r).
pub fn SegmentTreeBeats::range_sum(
  self : SegmentTreeBeats,
  l : Int,
  r : Int,
) -> Int64 {
  if self.n == 0 || l >= r {
    return 0L
  }
  self.sum_impl(1, 0, self.n, l, r)
}

///|
fn SegmentTreeBeats::sum_impl(
  self : SegmentTreeBeats,
  node : Int,
  l : Int,
  r : Int,
  ql : Int,
  qr : Int,
) -> Int64 {
  if qr <= l || r <= ql {
    return 0L
  }
  if ql <= l && r <= qr {
    return self.sum[node]
  }
  let mid = (l + r) / 2
  self.push(node)
  let left = self.sum_impl(node * 2, l, mid, ql, qr)
  let right = self.sum_impl(node * 2 + 1, mid, r, ql, qr)
  left + right
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "segment tree beats range chmin" {
  let values : Array[Int64] = [5L, 1L, 7L, 3L, 9L]
  let st = SegmentTreeBeats::new(values)
  inspect(st.range_sum(0, 5), content="25")
  inspect(st.range_max(0, 5), content="9")
  st.range_chmin(1, 4, 4L)
  inspect(st.range_sum(0, 5), content="22")
  inspect(st.range_max(0, 5), content="9")
  st.range_chmin(0, 5, 4L)
  inspect(st.range_sum(0, 5), content="16")
  inspect(st.range_max(0, 5), content="4")
  st.range_chmin(2, 5, 2L)
  inspect(st.range_sum(0, 5), content="11")
  inspect(st.range_max(0, 5), content="4")
}

///|
test "segment tree beats single element" {
  let st = SegmentTreeBeats::new([10L])
  inspect(st.range_sum(0, 1), content="10")
  inspect(st.range_max(0, 1), content="10")
  st.range_chmin(0, 1, 6L)
  inspect(st.range_sum(0, 1), content="6")
  inspect(st.range_max(0, 1), content="6")
}
