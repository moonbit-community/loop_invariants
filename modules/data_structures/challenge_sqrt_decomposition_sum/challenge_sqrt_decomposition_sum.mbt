// ============================================================================
// Challenge: Sqrt Decomposition (Range Sum)
// ============================================================================

///|
fn sqrt_ceil(n : Int) -> Int {
  if n <= 0 {
    1
  } else {
    sqrt_ceil_from(n, 1)
  }
}

///|
fn sqrt_ceil_from(n : Int, b : Int) -> Int {
  if b * b >= n {
    b
  } else {
    sqrt_ceil_from(n, b + 1)
  }
}

///|
/// A sqrt-decomposition structure supporting point updates and range sums.
///
/// Partitions the array into blocks of size `ceil(sqrt(n))` and caches the
/// sum of each block. A range query walks full blocks in O(1) each and only
/// pays per-element cost on the (at most two) partial boundary blocks, for an
/// `O(sqrt(n))` query and `O(1)` update. Build with `build_sqrt_decomp`, then
/// use `range_sum` and `update`.
///
/// Example:
/// ```moonbit nocheck
/// test {
///   let arr : Array[Int] = [1, 2, 3, 4, 5, 6, 7, 8, 9]
///   let sd = build_sqrt_decomp(arr[:])
///   assert_eq(range_sum(sd, 0, 9), 45)
///   update(sd, 2, 30)
///   assert_eq(range_sum(sd, 0, 9), 72)
/// }
/// ```
pub struct SqrtDecomp {
  n : Int
  block_size : Int
  arr : Array[Int]
  block_sum : Array[Int]
}

///|
/// Build a sqrt decomposition structure for range sums.
pub fn build_sqrt_decomp(arr : ArrayView[Int]) -> SqrtDecomp {
  let n = arr.length()
  let block_size = sqrt_ceil(n)
  let block_count = (n + block_size - 1) / block_size
  let data = arr.to_owned()
  let block_sum = Array::make(block_count, 0)
  for i in 0..<n {
    block_sum[i / block_size] = block_sum[i / block_size] + data[i]
  }
  { n, block_size, arr: data, block_sum }
}

///|
/// Query the sum over [l, r).
pub fn range_sum(sd : SqrtDecomp, l : Int, r : Int) -> Int {
  range_sum_from(sd, l, r, 0)
}

///|
fn range_sum_from(sd : SqrtDecomp, pos : Int, r : Int, acc : Int) -> Int {
  if pos >= r {
    acc
  } else if pos % sd.block_size == 0 && pos + sd.block_size <= r {
    range_sum_from(
      sd,
      pos + sd.block_size,
      r,
      acc + sd.block_sum[pos / sd.block_size],
    )
  } else {
    range_sum_from(sd, pos + 1, r, acc + sd.arr[pos])
  }
}

///|
/// Update index idx to value in the sqrt decomposition structure.
pub fn update(sd : SqrtDecomp, idx : Int, value : Int) -> Unit {
  let block = idx / sd.block_size
  let diff = value - sd.arr[idx]
  sd.arr[idx] = value
  sd.block_sum[block] = sd.block_sum[block] + diff
}
