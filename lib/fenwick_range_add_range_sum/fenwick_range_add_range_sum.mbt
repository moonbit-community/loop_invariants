// ============================================================================
// FENWICK RANGE ADD + RANGE SUM
// ============================================================================
//
// Support range add and range sum queries on an array using two Fenwick trees.
// For 0-indexed inclusive range [l, r], we maintain:
//   prefix(x) = sum(bit1, x) * x - sum(bit2, x)  (with x in 1-indexed form)
// Then range_sum(l, r) = prefix(r) - prefix(l - 1).
//
// TIME COMPLEXITY: O(log n) per update/query
// SPACE COMPLEXITY: O(n)

///|
fn lowbit(x : Int) -> Int {
  x & -x
}

///|
pub struct FenwickRangeAddRangeSum {
  n : Int
  bit1 : Array[Int64]
  bit2 : Array[Int64]
}

///|
/// Create an empty structure of size n (0-indexed).
pub fn FenwickRangeAddRangeSum::new(n : Int) -> FenwickRangeAddRangeSum {
  let n0 = if n < 0 { 0 } else { n }
  let size = n0 + 2
  { n: n0, bit1: Array::make(size, 0L), bit2: Array::make(size, 0L) }
}

///|
/// Build from an initial array.
pub fn FenwickRangeAddRangeSum::from_array(
  arr : ArrayView[Int64],
) -> FenwickRangeAddRangeSum {
  let st = FenwickRangeAddRangeSum::new(arr.length())
  for i in 0..<arr.length() {
    st.range_add(i, i, arr[i])
  }
  st
}

///|
fn FenwickRangeAddRangeSum::add_bit(
  self : FenwickRangeAddRangeSum,
  bit : Array[Int64],
  idx : Int,
  delta : Int64,
) -> Unit {
  let mut i = idx
  let limit = self.n + 1
  for ; i <= limit; {
    bit[i] = bit[i] + delta
    i = i + lowbit(i)
  } where {
    invariant: i >= 1 && i <= limit,
    reasoning: (
      #|INVARIANT (BIT update path):
      #|i walks upward along Fenwick parent links (i += lowbit(i)). Every
      #|visited index's covered range contains the original position idx,
      #|so adding delta preserves prefix sums for that position.
      #|TERMINATION:
      #|i strictly increases and eventually exceeds limit.
    ),
  }
}

///|
fn sum_bit(bit : Array[Int64], idx : Int) -> Int64 {
  let mut i = idx
  let mut acc = 0L
  for ; i > 0; {
    acc = acc + bit[i]
    i = i - lowbit(i)
  } where {
    invariant: i >= 0,
    reasoning: (
      #|INVARIANT (BIT prefix sum):
      #|acc equals the sum of all Fenwick segments fully covered so far
      #|in the prefix [1..idx]. Each step removes lowbit(i), shrinking the
      #|remaining prefix while preserving the accumulated total.
      #|TERMINATION:
      #|i decreases to 0, so the full prefix sum is accumulated.
    ),
  }
  acc
}

///|
/// Add delta to all positions in [l, r] (inclusive, 0-indexed).
pub fn FenwickRangeAddRangeSum::range_add(
  self : FenwickRangeAddRangeSum,
  l : Int,
  r : Int,
  delta : Int64,
) -> Unit {
  if self.n <= 0 || l > r || l < 0 || r >= self.n {
    return
  }
  let left = l + 1
  let right = r + 1
  self.add_bit(self.bit1, left, delta)
  self.add_bit(self.bit1, right + 1, -delta)
  self.add_bit(self.bit2, left, delta * l.to_int64())
  self.add_bit(self.bit2, right + 1, -delta * (r + 1).to_int64())
}

///|
fn FenwickRangeAddRangeSum::prefix_sum(
  self : FenwickRangeAddRangeSum,
  idx : Int,
) -> Int64 {
  if idx < 0 {
    return 0L
  }
  let x = idx + 1
  let s1 = sum_bit(self.bit1, x)
  let s2 = sum_bit(self.bit2, x)
  s1 * x.to_int64() - s2
}

///|
/// Query sum over [l, r] (inclusive, 0-indexed).
pub fn FenwickRangeAddRangeSum::range_sum(
  self : FenwickRangeAddRangeSum,
  l : Int,
  r : Int,
) -> Int64 {
  if self.n <= 0 || l > r {
    return 0L
  }
  self.prefix_sum(r) - self.prefix_sum(l - 1)
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "fenwick range add range sum basic" {
  let st = FenwickRangeAddRangeSum::new(5)
  st.range_add(0, 4, 1L)
  st.range_add(1, 3, 2L)
  inspect(st.range_sum(0, 4), content="11")
  inspect(st.range_sum(1, 3), content="9")
}

///|
test "fenwick range add range sum from array" {
  let st = FenwickRangeAddRangeSum::from_array([1L, 2L, 3L, 4L, 5L])
  inspect(st.range_sum(0, 4), content="15")
  st.range_add(1, 3, 2L)
  inspect(st.range_sum(0, 4), content="21")
  inspect(st.range_sum(1, 3), content="15")
}
