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
  let limit = self.n + 1
  loop idx {
    i => {
      if i > limit {
        break ()
      }
      bit[i] = bit[i] + delta
      continue i + lowbit(i)
    }
  }
}

///|
fn sum_bit(bit : Array[Int64], idx : Int) -> Int64 {
  loop (idx, 0L) {
    (i, acc) => {
      if i <= 0 {
        break acc
      }
      continue (i - lowbit(i), acc + bit[i])
    }
  }
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
