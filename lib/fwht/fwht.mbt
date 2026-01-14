// ============================================================================
// FAST WALSH-HADAMARD TRANSFORM (XOR)
// ============================================================================
//
// Computes XOR transform on arrays whose length is a power of two. The inverse
// transform divides by n.
//
// TIME COMPLEXITY: O(n log n)
// SPACE COMPLEXITY: O(n)

///|
fn is_power_of_two(n : Int) -> Bool {
  n > 0 && (n & (n - 1)) == 0
}

///|
/// XOR FWHT. When inverse=true, divides each value by n.
pub fn fwht_xor(values : ArrayView[Int64], inverse : Bool) -> Array[Int64] {
  let n = values.length()
  if not(is_power_of_two(n)) {
    return []
  }
  let a = values.to_array()
  for len = 1; len < n; len = len * 2 {
    for i = 0; i < n; i = i + 2 * len {
      for j = 0; j < len; j = j + 1 {
        let u = a[i + j]
        let v = a[i + j + len]
        a[i + j] = u + v
        a[i + j + len] = u - v
      } where {
        invariant: j >= 0 && j <= len,
        reasoning: (
          #|INVARIANT (butterfly inner):
          #|Positions i..i+j-1 have been updated with XOR butterflies.
          #|MAINTENANCE:
          #|Apply the butterfly at offset j within the current block.
          #|TERMINATION:
          #|At j = len, the block [i, i+2*len) is fully processed.
        ),
      }
    } where {
      invariant: i >= 0 && i <= n,
      reasoning: (
        #|INVARIANT (butterfly block):
        #|All blocks in [0, i) of size 2*len have been transformed.
        #|MAINTENANCE:
        #|Process the next block starting at i.
        #|TERMINATION:
        #|At i = n, this stage length is complete.
      ),
    }
  } where {
    invariant: len >= 1 && len <= n,
    reasoning: (
      #|INVARIANT (stage size):
      #|After each stage, the transform is correct for sub-blocks of size 2*len.
      #|MAINTENANCE:
      #|Double len to merge adjacent transformed blocks.
      #|TERMINATION:
      #|At len >= n, all bits have been processed.
    ),
  }
  if inverse {
    for i = 0; i < n; i = i + 1 {
      a[i] = a[i] / n.to_int64()
    } where {
      invariant: i >= 0 && i <= n,
      reasoning: (
        #|INVARIANT (inverse scaling):
        #|a[0..i) has been divided by n.
        #|MAINTENANCE:
        #|Scale a[i] by 1/n.
        #|TERMINATION:
        #|At i = n, the inverse transform is complete.
      ),
    }
  }
  a
}

///|
/// XOR convolution of a and b.
pub fn xor_convolution(
  a : ArrayView[Int64],
  b : ArrayView[Int64],
) -> Array[Int64] {
  let target = if a.length() > b.length() { a.length() } else { b.length() }
  if target == 0 {
    return []
  }
  let n = for n = 1; n < target; {
    continue n * 2
  } else {
    n
  } where {
    invariant: n > 0 && n <= 2 * target,
    reasoning: (
      #|INVARIANT (pad size):
      #|n is the smallest power of two >= target after doublings.
      #|MAINTENANCE:
      #|Double n until it reaches or exceeds target.
      #|TERMINATION:
      #|At n >= target, the padding size is valid.
    ),
  }
  let fa = Array::make(n, 0L)
  let fb = Array::make(n, 0L)
  for i = 0; i < a.length(); i = i + 1 {
    fa[i] = a[i]
  } where {
    invariant: i >= 0 && i <= a.length(),
    reasoning: (
      #|INVARIANT (copy a):
      #|fa[0..i) matches a[0..i).
      #|MAINTENANCE:
      #|Copy a[i] into fa.
      #|TERMINATION:
      #|At i = len, all elements of a are copied.
    ),
  }
  for i = 0; i < b.length(); i = i + 1 {
    fb[i] = b[i]
  } where {
    invariant: i >= 0 && i <= b.length(),
    reasoning: (
      #|INVARIANT (copy b):
      #|fb[0..i) matches b[0..i).
      #|MAINTENANCE:
      #|Copy b[i] into fb.
      #|TERMINATION:
      #|At i = len, all elements of b are copied.
    ),
  }
  let ta = fwht_xor(fa[:], false)
  let tb = fwht_xor(fb[:], false)
  for i = 0; i < n; i = i + 1 {
    ta[i] = ta[i] * tb[i]
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (pointwise multiply):
      #|ta[0..i) holds the product of transformed coefficients.
      #|MAINTENANCE:
      #|Multiply coefficient i.
      #|TERMINATION:
      #|At i = n, pointwise multiplication is complete.
    ),
  }
  fwht_xor(ta[:], true)
}
