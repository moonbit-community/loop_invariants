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
  if !is_power_of_two(n) {
    return []
  }
  let a = values.to_array()
  for len = 1; len < n; len = len * 2 {
    for i = 0; i < n; i = i + 2 * len {
      for j in 0..<len {
        let u = a[i + j]
        let v = a[i + j + len]
        a[i + j] = u + v
        a[i + j + len] = u - v
      }
    } where {
      proof_invariant: i >= 0 && i <= n,
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
    proof_invariant: len >= 1 && len <= n,
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
    for i in 0..<n {
      a[i] = a[i] / n.to_int64()
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
  } nobreak {
    n
  } where {
    proof_invariant: n > 0 && n <= 2 * target,
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
  for i in 0..<a.length() {
    fa[i] = a[i]
  }
  for i in 0..<b.length() {
    fb[i] = b[i]
  }
  let ta = fwht_xor(fa[:], false)
  let tb = fwht_xor(fb[:], false)
  for i in 0..<n {
    ta[i] = ta[i] * tb[i]
  }
  fwht_xor(ta[:], true)
}
