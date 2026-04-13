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
/// Returns the lowest set bit of `x`, i.e. `x & (-x)`.
///
/// This is the core primitive of the Fenwick Tree: the length of the range
/// that node `x` is responsible for equals `lowbit(x)`.
///
/// Examples: `lowbit(1)=1`, `lowbit(2)=2`, `lowbit(3)=1`, `lowbit(4)=4`.
fn lowbit(x : Int) -> Int {
  x & -x
}

///|
/// A Fenwick Tree (Binary Indexed Tree) that supports both range add updates
/// and range sum queries in O(log n) time per operation.
///
/// The structure maintains two internal BIT arrays (`bit1` and `bit2`) using
/// the mathematical decomposition:
///
/// ```
/// prefix(x) = sum(bit1, x) * x - sum(bit2, x)
/// ```
///
/// where `x` is the 1-indexed position corresponding to the 0-indexed query
/// boundary. This identity allows range sums to be answered using only four
/// BIT prefix queries.
///
/// All public methods use **0-indexed** coordinates: valid indices are `0..n-1`.
///
/// ## Invariant
///
/// After any sequence of `range_add` calls, for every 0-indexed boundary `i`:
/// - `bit1` stores the difference-array coefficients `b(k)` in 1-indexed form.
/// - `bit2` stores the weighted coefficients `b(k) * (k - 1)` in 1-indexed form.
/// - `prefix_sum(i) = sum(bit1, i+1) * (i+1) - sum(bit2, i+1)` equals the
///   true prefix sum of the logical array at position `i`.
pub struct FenwickRangeAddRangeSum {
  n : Int
  bit1 : Array[Int64]
  bit2 : Array[Int64]
}

///|
/// Create an empty `FenwickRangeAddRangeSum` of size `n` with all values zero.
///
/// Valid element indices after construction are `0..n-1`. Negative `n` is
/// treated as zero (empty structure).
///
/// Parameters:
/// - `n`: the number of logical elements to track.
///
/// Time complexity: O(n).
///
/// Example:
/// ```mbt check
/// test {
///   let st = @fenwick_range_add_range_sum.FenwickRangeAddRangeSum::new(5)
///   inspect(st.range_sum(0, 4), content="0")
/// }
/// ```
pub fn FenwickRangeAddRangeSum::new(n : Int) -> FenwickRangeAddRangeSum {
  let n0 = if n < 0 { 0 } else { n }
  let size = n0 + 2
  { n: n0, bit1: Array::make(size, 0L), bit2: Array::make(size, 0L) }
}

///|
/// Build a `FenwickRangeAddRangeSum` from an existing array in O(n log n) time.
///
/// Equivalent to constructing an empty structure of the same length and calling
/// `range_add(i, i, arr[i])` for each index `i`. The resulting structure
/// represents the given array and supports subsequent `range_add` and
/// `range_sum` operations.
///
/// Parameters:
/// - `arr`: the initial element values (0-indexed, `Int64`).
///
/// Time complexity: O(n log n).
///
/// Example:
/// ```mbt check
/// test {
///   let st = @fenwick_range_add_range_sum.FenwickRangeAddRangeSum::from_array([
///     1L, 2L, 3L, 4L, 5L,
///   ])
///   inspect(st.range_sum(0, 4), content="15")
///   inspect(st.range_sum(1, 3), content="9")
/// }
/// ```
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
/// Internal helper: standard Fenwick Tree point-add on an arbitrary BIT array.
///
/// Starts at 1-indexed position `idx` and climbs the tree by adding
/// `lowbit(i)` to `i` until `i` exceeds `self.n`. Touches at most
/// O(log n) nodes.
///
/// Parameters:
/// - `bit`: the internal BIT array (1-indexed, length >= self.n + 2).
/// - `idx`: 1-indexed starting position for the update.
/// - `delta`: value to add at each visited node.
///
/// Time complexity: O(log n).
///
/// INVARIANT: `i` strictly increases each iteration (lowbit >= 1), so the
/// loop terminates when `i > self.n`.
fn FenwickRangeAddRangeSum::add_bit(
  self : FenwickRangeAddRangeSum,
  bit : Array[Int64],
  idx : Int,
  delta : Int64,
) -> Unit {
  let limit = self.n + 1
  for i = idx {
    if i > limit {
      break
    } else {
      bit[i] = bit[i] + delta
      continue i + lowbit(i)
    }
  }
}

///|
/// Internal helper: standard Fenwick Tree prefix-sum query on an arbitrary
/// BIT array.
///
/// Descends from 1-indexed position `idx` by subtracting `lowbit(i)` from
/// `i`, accumulating partial sums until `i <= 0`.
///
/// Parameters:
/// - `bit`: the internal BIT array (1-indexed).
/// - `idx`: 1-indexed upper bound for the prefix sum.
///
/// Returns the prefix sum from index 1 to `idx`.
///
/// Time complexity: O(log n).
///
/// INVARIANT: `i` strictly decreases each iteration (lowbit >= 1), so the
/// loop terminates when `i <= 0`.
fn sum_bit(bit : Array[Int64], idx : Int) -> Int64 {
  for i = idx, acc = 0L {
    if i <= 0 {
      break acc
    } else {
      continue i - lowbit(i), acc + bit[i]
    }
  }
}

///|
/// Add `delta` to every element in the 0-indexed inclusive range `[l, r]`.
///
/// Encodes the range update in two internal BIT arrays using the
/// difference-array decomposition:
///
/// ```
/// bit1.add(l+1, +delta)          bit2.add(l+1, +delta * l)
/// bit1.add(r+2, -delta)          bit2.add(r+2, -delta * (r+1))
/// ```
///
/// After these four point-updates, any subsequent `prefix_sum` query
/// correctly accounts for the contribution of this range.
///
/// Parameters:
/// - `l`: first 0-indexed position (inclusive). Silently ignored if out of
///   bounds or if `l > r`.
/// - `r`: last 0-indexed position (inclusive). Silently ignored if out of
///   bounds or if `l > r`.
/// - `delta`: value to add to every element in `[l, r]` (may be negative).
///
/// Time complexity: O(log n).
///
/// Example:
/// ```mbt check
/// test {
///   let st = @fenwick_range_add_range_sum.FenwickRangeAddRangeSum::new(5)
///   st.range_add(1, 3, 10L)
///   inspect(st.range_sum(0, 0), content="0")
///   inspect(st.range_sum(1, 1), content="10")
///   inspect(st.range_sum(3, 3), content="10")
///   inspect(st.range_sum(4, 4), content="0")
/// }
/// ```
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
/// Compute the prefix sum of the logical array over 0-indexed positions
/// `[0, idx]` (inclusive).
///
/// Uses the two-BIT formula with 1-indexed position `x = idx + 1`:
///
/// ```
/// prefix_sum(idx) = sum(bit1, x) * x - sum(bit2, x)
/// ```
///
/// Parameters:
/// - `idx`: last 0-indexed position to include. Returns 0 if `idx < 0`.
///
/// Time complexity: O(log n).
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
/// Return the sum of all elements in the 0-indexed inclusive range `[l, r]`.
///
/// Uses the identity:
///
/// ```
/// range_sum(l, r) = prefix_sum(r) - prefix_sum(l - 1)
/// ```
///
/// Returns 0 when the structure is empty, when `l > r`, or when the range
/// falls entirely outside `[0, n-1]`.
///
/// Parameters:
/// - `l`: first 0-indexed position (inclusive).
/// - `r`: last 0-indexed position (inclusive).
///
/// Time complexity: O(log n) (two `prefix_sum` calls).
///
/// Example:
/// ```mbt check
/// test {
///   let st = @fenwick_range_add_range_sum.FenwickRangeAddRangeSum::from_array([
///     1L, 2L, 3L, 4L, 5L,
///   ])
///   st.range_add(1, 3, 2L)
///   inspect(st.range_sum(0, 4), content="21")
///   inspect(st.range_sum(1, 3), content="15")
/// }
/// ```
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
