// ============================================================================
// FAST WALSH-HADAMARD TRANSFORM (XOR VARIANT)
// ============================================================================
//
// The Fast Walsh-Hadamard Transform (FWHT) computes the XOR convolution of two
// sequences in O(n log n) time. It is the XOR analog of the FFT for polynomial
// multiplication: instead of turning regular (addition-based) convolution into
// pointwise multiplication, FWHT turns XOR-indexed convolution into pointwise
// multiplication.
//
// DEFINITION:
//   Given arrays a and b of length n (a power of two), their XOR convolution c
//   is defined as:
//
//     c[k] = sum_{i XOR j = k} a[i] * b[j]
//
// ALGORITHM (iterative butterfly, in-place):
//   for len = 1; len < n; len *= 2:
//     for i = 0; i < n; i += 2 * len:
//       for j = 0; j < len; j++:
//         u = a[i + j]
//         v = a[i + j + len]
//         a[i + j]       = u + v    // butterfly sum
//         a[i + j + len] = u - v    // butterfly difference
//
//   The inverse transform applies the same butterfly network and then divides
//   every element by n.
//
// CORRECTNESS:
//   The Walsh-Hadamard matrix H satisfies H[i][j] = (-1)^popcount(i AND j).
//   This matrix is its own inverse up to a factor of n (H * H = n * I), which
//   is why the inverse transform only needs to divide by n.
//   The key identity H[i][j] * H[i][k] = H[i][j XOR k] ensures that
//   pointwise multiplication in the transformed domain corresponds to
//   XOR convolution in the original domain.
//
// INVARIANTS:
//   1. After stage len, all sub-blocks of size 2*len are fully transformed.
//   2. The transform is in-place: no extra allocation beyond the output copy.
//   3. Inverse transform composed with forward transform is the identity (up to
//      integer rounding when values are not divisible by n).
//
// TIME COMPLEXITY:  O(n log n)
// SPACE COMPLEXITY: O(n)  (output copy; the in-place butterfly touches no extra memory)

///|
fn is_power_of_two(n : Int) -> Bool {
  n > 0 && (n & (n - 1)) == 0
}

///|
/// Applies the Fast Walsh-Hadamard Transform (XOR variant) to `values`.
///
/// When `inverse` is `false`, computes the forward FWHT:
///
///   A[i] = sum_{j=0}^{n-1} (-1)^popcount(i AND j) * a[j]
///
/// When `inverse` is `true`, applies the same butterfly network and then
/// divides each element by `n`, recovering the original array:
///
///   FWHT_inv(FWHT(a)) == a   (exact for integer inputs whose FWHT is divisible by n)
///
/// The input length must be a power of two. If it is not, the function returns
/// an empty array.
///
/// Algorithm: iterative Cooley-Tukey-style butterfly on XOR groups.
/// At stage `len`, each butterfly combines positions (i+j) and (i+j+len):
///
///   new[i+j]     = old[i+j] + old[i+j+len]
///   new[i+j+len] = old[i+j] - old[i+j+len]
///
/// log2(n) such stages are applied, one per bit of the index.
///
/// Parameters:
/// - `values`: a view of the input array; must have power-of-two length.
/// - `inverse`: if true, divide every element by n after the butterfly passes.
///
/// Returns a fresh `Array[Int64]` of the same length as `values`.
///
/// Example — forward transform on [1, 2, 3, 4]:
///
///   Stage 1 (len=1): [3, -1, 7, -1]
///   Stage 2 (len=2): [10, -2, -4, 0]
///   fwht_xor([1,2,3,4][:], false) == [10, -2, -4, 0]
///
/// Example — round-trip:
///
///   let t   = fwht_xor([1L,2L,3L,4L][:], false)
///   let inv = fwht_xor(t[:], true)
///   // inv == [1, 2, 3, 4]
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
      proof_reasoning: (
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
    proof_reasoning: (
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
/// Computes the XOR convolution of arrays `a` and `b`.
///
/// The XOR convolution `c` is defined entry-by-entry as:
///
///   c[k] = sum_{i XOR j = k} a[i] * b[j]
///
/// That is, every pair of indices (i, j) whose bitwise XOR equals k
/// contributes a[i] * b[j] to the output c[k].
///
/// This is the XOR analog of polynomial multiplication: whereas regular
/// polynomial multiplication sums over pairs where i + j = k, XOR
/// convolution sums over pairs where i XOR j = k.
///
/// The function handles inputs of different lengths by zero-padding both
/// arrays to the smallest common power-of-two size before transforming.
///
/// Algorithm (three steps):
///   1. Zero-pad a and b to length n = next power of two >= max(|a|, |b|).
///   2. Forward-transform both with fwht_xor.
///   3. Multiply pointwise: ta[i] *= tb[i].
///   4. Inverse-transform ta with fwht_xor to recover c.
///
/// Parameters:
/// - `a`: first operand; any length (need not be a power of two).
/// - `b`: second operand; any length (need not be a power of two).
///
/// Returns an `Array[Int64]` of length equal to the padding size n.
/// Trailing zeros beyond max(|a|, |b|) are meaningfully zero because
/// indices >= max(|a|, |b|) have no contributing pairs.
///
/// Returns an empty array if both inputs are empty.
///
/// Example:
///   a = [1, 2, 3, 4],  b = [5, 6, 7, 8]
///
///   c[0] = a[0]*b[0] + a[1]*b[1] + a[2]*b[2] + a[3]*b[3]
///        = 5 + 12 + 21 + 32 = 70
///   c[1] = a[0]*b[1] + a[1]*b[0] + a[2]*b[3] + a[3]*b[2]
///        = 6 + 10 + 24 + 28 = 68
///   c[2] = a[0]*b[2] + a[1]*b[3] + a[2]*b[0] + a[3]*b[1]
///        = 7 + 16 + 15 + 24 = 62
///   c[3] = a[0]*b[3] + a[1]*b[2] + a[2]*b[1] + a[3]*b[0]
///        = 8 + 14 + 18 + 20 = 60
///
///   xor_convolution([1,2,3,4][:], [5,6,7,8][:]) == [70, 68, 62, 60]
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
    proof_reasoning: (
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
