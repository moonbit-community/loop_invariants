// ============================================================================
// SEGMENT TREE BEATS - Advanced Range Operations
// ============================================================================
//
// Segment Tree Beats extends lazy propagation to handle operations like:
// - Range chmin/chmax (set all elements ≤ or ≥ threshold)
// - Combined with range sum/min/max queries
//
// KEY INSIGHT: For chmin(l, r, x), if x ≥ max[l,r], no change needed.
// If x > second_max[l,r], only the maximum elements change.
// Otherwise, break into smaller segments.
//
// "BEATS" CONDITION: An operation "beats" a node when it affects all or none
// of the maximum elements, allowing O(log n) amortized per operation.
//
// TRACKED VALUES:
// - max1: Maximum value
// - max2: Second maximum (or -∞)
// - max_cnt: Count of maximum elements
// - sum: Sum of all elements
//
// INVARIANTS:
// 1. max1 > max2 always (or max2 = -∞ if all elements equal)
// 2. After chmin(x): all elements ≤ x
// 3. Sum updated: sum -= max_cnt * (max1 - x) when max1 changes to x
//
// TIME COMPLEXITY: O(log² n) amortized per operation
// SPACE COMPLEXITY: O(n)

///|
const BEATS_NINF : Int64 = -4611686018427387903L

///|
priv struct BeatsNode {
  mut sum : Int64
  mut max1 : Int64 // Maximum value
  mut max2 : Int64 // Second maximum
  mut max_cnt : Int // Count of maximum
  mut lazy : Int64 // Lazy chmin value (or INF if none)
}

///|
priv struct SegmentTreeBeats {
  n : Int
  tree : Array[BeatsNode]
}

///|
fn BeatsNode::new() -> BeatsNode {
  { sum: 0L, max1: BEATS_NINF, max2: BEATS_NINF, max_cnt: 0, lazy: 0L }
}

///|
fn SegmentTreeBeats::new(n : Int) -> SegmentTreeBeats {
  let size = 4 * n
  let tree = Array::make(size, BeatsNode::new())
  for i = 0; i < size; i = i + 1 {
    tree[i] = BeatsNode::new()
  }
  { n, tree }
}

///|
fn SegmentTreeBeats::build(arr : Array[Int64]) -> SegmentTreeBeats {
  let n = arr.length()
  let st = SegmentTreeBeats::new(n)
  st.build_rec(arr, 1, 0, n - 1)
  st
}

///|
fn SegmentTreeBeats::build_rec(
  self : SegmentTreeBeats,
  arr : Array[Int64],
  node : Int,
  start : Int,
  end : Int
) -> Unit {
  if start == end {
    self.tree[node].sum = arr[start]
    self.tree[node].max1 = arr[start]
    self.tree[node].max2 = BEATS_NINF
    self.tree[node].max_cnt = 1
    return
  }

  let mid = (start + end) / 2
  self.build_rec(arr, 2 * node, start, mid)
  self.build_rec(arr, 2 * node + 1, mid + 1, end)
  self.pull_up(node)
}

///|
fn SegmentTreeBeats::pull_up(self : SegmentTreeBeats, node : Int) -> Unit {
  let left = 2 * node
  let right = 2 * node + 1

  self.tree[node].sum = self.tree[left].sum + self.tree[right].sum

  // Merge max info from children
  if self.tree[left].max1 > self.tree[right].max1 {
    self.tree[node].max1 = self.tree[left].max1
    self.tree[node].max_cnt = self.tree[left].max_cnt
    self.tree[node].max2 = if self.tree[left].max2 > self.tree[right].max1 {
      self.tree[left].max2
    } else {
      self.tree[right].max1
    }
  } else if self.tree[left].max1 < self.tree[right].max1 {
    self.tree[node].max1 = self.tree[right].max1
    self.tree[node].max_cnt = self.tree[right].max_cnt
    self.tree[node].max2 = if self.tree[right].max2 > self.tree[left].max1 {
      self.tree[right].max2
    } else {
      self.tree[left].max1
    }
  } else {
    // Equal maximums
    self.tree[node].max1 = self.tree[left].max1
    self.tree[node].max_cnt = self.tree[left].max_cnt + self.tree[right].max_cnt
    self.tree[node].max2 = if self.tree[left].max2 > self.tree[right].max2 {
      self.tree[left].max2
    } else {
      self.tree[right].max2
    }
  }
}

///|
fn SegmentTreeBeats::push_down(
  self : SegmentTreeBeats,
  node : Int,
  start : Int,
  end : Int
) -> Unit {
  if start == end || self.tree[node].lazy == 0L {
    return
  }

  let left = 2 * node
  let right = 2 * node + 1
  let lazy_val = self.tree[node].lazy

  // Apply to children only if their max1 > lazy_val
  self.apply_chmin(left, lazy_val)
  self.apply_chmin(right, lazy_val)

  self.tree[node].lazy = 0L
}

///|
fn SegmentTreeBeats::apply_chmin(
  self : SegmentTreeBeats,
  node : Int,
  x : Int64
) -> Unit {
  if self.tree[node].max1 <= x {
    return
  }

  // Update sum
  self.tree[node].sum = self.tree[node].sum -
    (self.tree[node].max1 - x) * self.tree[node].max_cnt.to_int64()
  self.tree[node].max1 = x

  // Update lazy
  if self.tree[node].lazy == 0L || self.tree[node].lazy > x {
    self.tree[node].lazy = x
  }
}

///|
/// Range chmin: set all elements in [l, r] to min(a[i], x)
fn SegmentTreeBeats::chmin(
  self : SegmentTreeBeats,
  l : Int,
  r : Int,
  x : Int64
) -> Unit {
  self.chmin_rec(1, 0, self.n - 1, l, r, x)
}

///|
fn SegmentTreeBeats::chmin_rec(
  self : SegmentTreeBeats,
  node : Int,
  start : Int,
  end : Int,
  l : Int,
  r : Int,
  x : Int64
) -> Unit {
  if l > end || r < start {
    return
  }

  // No change needed
  if self.tree[node].max1 <= x {
    return
  }

  // All elements affected uniformly
  if l <= start && end <= r && self.tree[node].max2 < x {
    self.apply_chmin(node, x)
    return
  }

  // Need to go deeper
  self.push_down(node, start, end)
  let mid = (start + end) / 2
  self.chmin_rec(2 * node, start, mid, l, r, x)
  self.chmin_rec(2 * node + 1, mid + 1, end, l, r, x)
  self.pull_up(node)
}

///|
/// Query sum in range [l, r]
fn SegmentTreeBeats::query_sum(self : SegmentTreeBeats, l : Int, r : Int) -> Int64 {
  self.query_sum_rec(1, 0, self.n - 1, l, r)
}

///|
fn SegmentTreeBeats::query_sum_rec(
  self : SegmentTreeBeats,
  node : Int,
  start : Int,
  end : Int,
  l : Int,
  r : Int
) -> Int64 {
  if l > end || r < start {
    return 0L
  }

  if l <= start && end <= r {
    return self.tree[node].sum
  }

  self.push_down(node, start, end)
  let mid = (start + end) / 2
  self.query_sum_rec(2 * node, start, mid, l, r) +
  self.query_sum_rec(2 * node + 1, mid + 1, end, l, r)
}

///|
/// Query max in range [l, r]
fn SegmentTreeBeats::query_max(self : SegmentTreeBeats, l : Int, r : Int) -> Int64 {
  self.query_max_rec(1, 0, self.n - 1, l, r)
}

///|
fn SegmentTreeBeats::query_max_rec(
  self : SegmentTreeBeats,
  node : Int,
  start : Int,
  end : Int,
  l : Int,
  r : Int
) -> Int64 {
  if l > end || r < start {
    return BEATS_NINF
  }

  if l <= start && end <= r {
    return self.tree[node].max1
  }

  self.push_down(node, start, end)
  let mid = (start + end) / 2
  let left_max = self.query_max_rec(2 * node, start, mid, l, r)
  let right_max = self.query_max_rec(2 * node + 1, mid + 1, end, l, r)

  if left_max > right_max { left_max } else { right_max }
}

///|
/// Point update: set a[i] = x
fn SegmentTreeBeats::update(self : SegmentTreeBeats, i : Int, x : Int64) -> Unit {
  self.update_rec(1, 0, self.n - 1, i, x)
}

///|
fn SegmentTreeBeats::update_rec(
  self : SegmentTreeBeats,
  node : Int,
  start : Int,
  end : Int,
  i : Int,
  x : Int64
) -> Unit {
  if start == end {
    self.tree[node].sum = x
    self.tree[node].max1 = x
    self.tree[node].max2 = BEATS_NINF
    self.tree[node].max_cnt = 1
    return
  }

  self.push_down(node, start, end)
  let mid = (start + end) / 2
  if i <= mid {
    self.update_rec(2 * node, start, mid, i, x)
  } else {
    self.update_rec(2 * node + 1, mid + 1, end, i, x)
  }
  self.pull_up(node)
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "beats build and query" {
  let arr : Array[Int64] = [1L, 3L, 5L, 7L, 9L]
  let st = SegmentTreeBeats::build(arr)

  inspect(st.query_sum(0, 4), content="25") // 1+3+5+7+9
  inspect(st.query_max(0, 4), content="9")
  inspect(st.query_max(0, 2), content="5")
}

///|
test "beats chmin" {
  let arr : Array[Int64] = [1L, 3L, 5L, 7L, 9L]
  let st = SegmentTreeBeats::build(arr)

  // chmin all to 6: [1, 3, 5, 6, 6]
  st.chmin(0, 4, 6L)

  inspect(st.query_max(0, 4), content="6")
  inspect(st.query_sum(0, 4), content="21") // 1+3+5+6+6
}

///|
test "beats chmin partial" {
  let arr : Array[Int64] = [1L, 3L, 5L, 7L, 9L]
  let st = SegmentTreeBeats::build(arr)

  // chmin [2, 4] to 6: [1, 3, 5, 6, 6]
  st.chmin(2, 4, 6L)

  inspect(st.query_sum(0, 4), content="21")
  inspect(st.query_max(0, 1), content="3") // Unchanged
}

///|
test "beats point update" {
  let arr : Array[Int64] = [1L, 3L, 5L, 7L, 9L]
  let st = SegmentTreeBeats::build(arr)

  st.update(2, 100L)

  inspect(st.query_max(0, 4), content="100")
  inspect(st.query_sum(0, 4), content="120") // 1+3+100+7+9
}

///|
test "beats combined operations" {
  let arr : Array[Int64] = [10L, 20L, 30L, 40L, 50L]
  let st = SegmentTreeBeats::build(arr)

  st.chmin(0, 4, 35L) // [10, 20, 30, 35, 35]
  inspect(st.query_sum(0, 4), content="130")

  st.chmin(2, 4, 25L) // [10, 20, 25, 25, 25]
  inspect(st.query_sum(0, 4), content="105")
}

///|
test "beats single element" {
  let arr : Array[Int64] = [42L]
  let st = SegmentTreeBeats::build(arr)

  inspect(st.query_sum(0, 0), content="42")
  inspect(st.query_max(0, 0), content="42")

  st.chmin(0, 0, 10L)
  inspect(st.query_max(0, 0), content="10")
}

///|
test "beats no change" {
  let arr : Array[Int64] = [1L, 2L, 3L]
  let st = SegmentTreeBeats::build(arr)

  // chmin to 10 should not change anything
  st.chmin(0, 2, 10L)
  inspect(st.query_sum(0, 2), content="6")
  inspect(st.query_max(0, 2), content="3")
}

///|
test "beats equal elements" {
  let arr : Array[Int64] = [5L, 5L, 5L, 5L]
  let st = SegmentTreeBeats::build(arr)

  inspect(st.query_sum(0, 3), content="20")

  st.chmin(0, 3, 3L)
  inspect(st.query_sum(0, 3), content="12") // 4 * 3
}
