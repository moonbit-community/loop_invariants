// ============================================================================
// Challenge: Sqrt Decomposition (Range Sum)
// ============================================================================

///|
fn sqrt_ceil(n : Int) -> Int {
  if n <= 0 {
    return 1
  }
  for b = 1 {
    if b * b >= n {
      break b
    } else {
      continue b + 1
    }
  } where {
    invariant: b >= 1,
    reasoning: (
      #|INVARIANT (sqrt ceil):
      #|b is the smallest candidate tested so far; all smaller values satisfy
      #|b^2 < n.
      #|MAINTENANCE:
      #|Increment b while b^2 < n.
      #|TERMINATION:
      #|The first b with b^2 >= n is the ceiling of sqrt(n).
    ),
  }
}

///|
pub struct SqrtDecomp {
  n : Int
  block_size : Int
  arr : Array[Int]
  block_sum : Array[Int]
}

///|
#warnings("+missing_invariant+missing_reasoning")
pub fn build_sqrt_decomp(arr : ArrayView[Int]) -> SqrtDecomp {
  let n = arr.length()
  let block_size = sqrt_ceil(n)
  let block_count = (n + block_size - 1) / block_size
  let data = arr.to_array()
  let block_sum = Array::make(block_count, 0)
  for i = 0; i < n; i = i + 1 {
    block_sum[i / block_size] = block_sum[i / block_size] + data[i]
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (block sums):
      #|block_sum accumulates the sums of data[0..i) per block.
      #|MAINTENANCE:
      #|Add data[i] to its block.
      #|TERMINATION:
      #|At i = n, all block sums are ready.
    ),
  }
  { n, block_size, arr: data, block_sum }
}

///|
#warnings("+missing_invariant+missing_reasoning")
pub fn range_sum(sd : SqrtDecomp, l : Int, r : Int) -> Int {
  for pos = l, acc = 0 {
    if pos >= r {
      break acc
    } else if pos % sd.block_size == 0 && pos + sd.block_size <= r {
      continue pos + sd.block_size, acc + sd.block_sum[pos / sd.block_size]
    } else {
      continue pos + 1, acc + sd.arr[pos]
    }
  } where {
    invariant: pos >= l && pos <= r,
    reasoning: (
      #|INVARIANT (range sum):
      #|acc equals sum of sd.arr[l..pos). The cursor pos marks the next element
      #|to account for.
      #|MAINTENANCE:
      #|If aligned, add a whole block; otherwise add a single element.
      #|TERMINATION:
      #|At pos = r, acc is the sum over [l, r).
    ),
  }
}

///|
pub fn update(sd : SqrtDecomp, idx : Int, value : Int) -> Unit {
  let block = idx / sd.block_size
  let diff = value - sd.arr[idx]
  sd.arr[idx] = value
  sd.block_sum[block] = sd.block_sum[block] + diff
}

///|
test "sqrt_decomposition_sum" {
  let arr : Array[Int] = [1, 2, 3, 4, 5, 6]
  let sd = build_sqrt_decomp(arr[:])
  assert_eq(range_sum(sd, 0, 3), 6)
  assert_eq(range_sum(sd, 2, 6), 18)
  update(sd, 3, 10)
  assert_eq(range_sum(sd, 2, 6), 24)
}
