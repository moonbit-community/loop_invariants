// ============================================================================
// SUM OVER SUBSETS (SOS) DP  -  "subset-sum transform"
// ============================================================================
//
// PROBLEM
//
// Given a function `f : {0, 1}^n -> Int64` represented as an array of
// length `2^n`, compute the **subset sum**
//
//   F[S] = sum over T subset-of S  of  f[T]
//
// for every subset `S` of `{0, 1, ..., n-1}`. The naive computation is
// `O(3^n)` (iterate every (T, S) with T subset of S). The SOS DP -- a
// dimension-by-dimension prefix sum over the hypercube -- runs in
// `O(n * 2^n)`.
//
// THE ALGORITHM (in-place)
//
//   for bit in 0..<n:
//     for mask in 0..<2^n:
//       if mask has bit set:
//         f[mask] += f[mask ^ (1 << bit)]
//
// After bit `i` is processed, `f[S]` is the sum of `f_original[T]`
// over all `T` that agree with `S` on the high bits `i+1..n-1` and
// are arbitrary on bits `0..i` (subject to `T subset of S`).
//
// THE INVARIANT (after iteration with bit b finished)
//
//   "f[S]  =  sum_{T: T agrees with S on bits b+1..n-1, T ∩ S = T on bits 0..b}
//             f_original[T]."
//
// At b = n - 1 this is exactly the subset-sum F[S].
//
// COMPLEXITY
//
//   Time : O(n * 2^n)
//   Space: O(1) extra (in-place over the input array)
//
// VARIANTS PROVIDED
//
//   sum_over_subsets    F[S] = sum_{T subset S}     f[T]   (zeta over subsets)
//   sum_over_supersets  F[S] = sum_{T superset S}   f[T]   (zeta over supersets)
//   mobius_subsets      inverse of sum_over_subsets
//   mobius_supersets    inverse of sum_over_supersets

///|
/// Number of bits inferred from `arr.length() = 2^n`. Returns `-1` if
/// the array is empty or not a power of two.
fn pop_count_of_pow2(len : Int) -> Int {
  if len <= 0 {
    return -1
  }
  let mut x = len
  let mut bits = 0
  while x > 1 {
    if x.land(1) != 0 {
      return -1
    }
    x = x / 2
    bits = bits + 1
  }
  bits
}

///|
/// Sum-over-subsets transform: replaces every `f[S]` with
/// `sum_{T subset of S} f[T]`. In place; returns `true` on success and
/// `false` if `arr.length()` is not a positive power of two.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let f = [0L, 1L, 2L, 3L]
///   let _ = @sos_dp.sum_over_subsets(f)
///   // F[0b00] = f[0]               = 0
///   // F[0b01] = f[0] + f[1]        = 1
///   // F[0b10] = f[0] + f[2]        = 2
///   // F[0b11] = f[0]+f[1]+f[2]+f[3] = 6
///   @debug.assert_eq(f, [0L, 1L, 2L, 6L])
/// }
/// ```
pub fn sum_over_subsets(arr : Array[Int64]) -> Bool {
  let n = pop_count_of_pow2(arr.length())
  if n < 0 {
    return false
  }
  let size = arr.length()
  for bit in 0..<n {
    for mask in 0..<size {
      if mask.land(1 << bit) != 0 {
        arr[mask] = arr[mask] + arr[mask.lxor(1 << bit)]
      }
    }
  }
  true
}

///|
/// Sum-over-supersets transform: replaces every `f[S]` with
/// `sum_{T superset of S} f[T]`. In place; returns `true` on success.
pub fn sum_over_supersets(arr : Array[Int64]) -> Bool {
  let n = pop_count_of_pow2(arr.length())
  if n < 0 {
    return false
  }
  let size = arr.length()
  for bit in 0..<n {
    for mask in 0..<size {
      if mask.land(1 << bit) == 0 {
        arr[mask] = arr[mask] + arr[mask.lor(1 << bit)]
      }
    }
  }
  true
}

///|
/// Inverse of `sum_over_subsets` (Mobius transform over the subset
/// lattice). After this, `arr[S]` is the unique function whose
/// subset-sum was the input.
///
/// Useful for **subset-sum convolution**: to compute
/// `(f * g)[S] = sum_{A | B = S} f[A] g[B]`, apply
/// `sum_over_subsets` to both, pointwise multiply, then
/// `mobius_subsets`.
pub fn mobius_subsets(arr : Array[Int64]) -> Bool {
  let n = pop_count_of_pow2(arr.length())
  if n < 0 {
    return false
  }
  let size = arr.length()
  for bit in 0..<n {
    for mask in 0..<size {
      if mask.land(1 << bit) != 0 {
        arr[mask] = arr[mask] - arr[mask.lxor(1 << bit)]
      }
    }
  }
  true
}

///|
/// Inverse of `sum_over_supersets`.
pub fn mobius_supersets(arr : Array[Int64]) -> Bool {
  let n = pop_count_of_pow2(arr.length())
  if n < 0 {
    return false
  }
  let size = arr.length()
  for bit in 0..<n {
    for mask in 0..<size {
      if mask.land(1 << bit) == 0 {
        arr[mask] = arr[mask] - arr[mask.lor(1 << bit)]
      }
    }
  }
  true
}

///|
test "sos basic 2-bit" {
  // f = [f(00), f(01), f(10), f(11)] = [1, 2, 3, 4]
  // F[00] = 1
  // F[01] = 1 + 2 = 3
  // F[10] = 1 + 3 = 4
  // F[11] = 1+2+3+4 = 10
  let f = [1L, 2L, 3L, 4L]
  @debug.assert_eq(sum_over_subsets(f), true)
  @debug.assert_eq(f, [1L, 3L, 4L, 10L])
}

///|
test "sos brute force 3-bit" {
  // Brute force vs SOS for n=3.
  let size = 8
  let original = [1L, 2L, 4L, 8L, 16L, 32L, 64L, 128L]
  let brute = Array::make(size, 0L)
  for s in 0..<size {
    for t in 0..<size {
      if t.land(s) == t {
        brute[s] = brute[s] + original[t]
      }
    }
  }
  let f = Array::makei(size, i => original[i])
  @debug.assert_eq(sum_over_subsets(f), true)
  for s in 0..<size {
    @debug.assert_eq(f[s], brute[s])
  }
}

///|
test "sos invertible by mobius" {
  let original = [3L, 1L, 4L, 1L, 5L, 9L, 2L, 6L]
  let f = Array::makei(original.length(), i => original[i])
  @debug.assert_eq(sum_over_subsets(f), true)
  @debug.assert_eq(mobius_subsets(f), true)
  for i in 0..<original.length() {
    @debug.assert_eq(f[i], original[i])
  }
}

///|
test "sos supersets sum" {
  // f = [1, 2, 4, 8]
  // S = 00: sum over supersets {00, 01, 10, 11} = 15
  // S = 01: sum over supersets {01, 11} = 2 + 8 = 10
  // S = 10: sum over supersets {10, 11} = 4 + 8 = 12
  // S = 11: sum over supersets {11} = 8
  let f = [1L, 2L, 4L, 8L]
  @debug.assert_eq(sum_over_supersets(f), true)
  @debug.assert_eq(f, [15L, 10L, 12L, 8L])
}

///|
test "sos supersets invertible by mobius" {
  let original = [3L, 1L, 4L, 1L, 5L, 9L, 2L, 6L]
  let f = Array::makei(original.length(), i => original[i])
  @debug.assert_eq(sum_over_supersets(f), true)
  @debug.assert_eq(mobius_supersets(f), true)
  for i in 0..<original.length() {
    @debug.assert_eq(f[i], original[i])
  }
}

///|
test "sos rejects non-power-of-two" {
  let f3 = [1L, 2L, 3L]
  @debug.assert_eq(sum_over_subsets(f3), false)
  let f0 : Array[Int64] = []
  @debug.assert_eq(sum_over_subsets(f0), false)
  let f5 = [1L, 2L, 3L, 4L, 5L]
  @debug.assert_eq(sum_over_supersets(f5), false)
}

///|
test "sos length 1" {
  // n = 0: only the empty subset; the transform is identity.
  let f = [42L]
  @debug.assert_eq(sum_over_subsets(f), true)
  @debug.assert_eq(f, [42L])
  @debug.assert_eq(mobius_subsets(f), true)
  @debug.assert_eq(f, [42L])
}

///|
test "sos subset convolution sanity" {
  // (f * g)[S] = sum_{A | B = S, A & B = 0} f[A] g[B] -- subset
  // convolution. The simpler "or-convolution" is sum_{A | B = S}, which
  // equals SOS(f) * SOS(g) pointwise then inverse-SOS.
  let f = [0L, 1L, 0L, 0L]
  let g = [0L, 0L, 1L, 0L]
  // f[01] = 1, g[10] = 1, all else 0; so or-conv should give:
  //   h[11] = 1 (01 | 10 = 11)
  //   h[other] = 0
  let fs = Array::makei(f.length(), i => f[i])
  let gs = Array::makei(g.length(), i => g[i])
  @debug.assert_eq(sum_over_subsets(fs), true)
  @debug.assert_eq(sum_over_subsets(gs), true)
  for i in 0..<f.length() {
    fs[i] = fs[i] * gs[i]
  }
  @debug.assert_eq(mobius_subsets(fs), true)
  @debug.assert_eq(fs, [0L, 0L, 0L, 1L])
}
