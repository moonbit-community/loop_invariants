// ============================================================================
// SUBSET CONVOLUTION
// ============================================================================
//
// Given functions f and g on subsets of {0..n-1} (arrays of length 2^n),
// compute h[S] = sum_{A subset S} f[A] * g[S \ A].
//
// This implementation uses the standard O(n^2 * 2^n) approach:
// - Split by popcount (rank stratification)
// - Zeta transform per popcount layer
// - Convolution in the rank dimension
// - Inverse zeta (Mobius) transform per rank layer

///|
/// Returns true if `n` is a positive power of two.
fn is_power_of_two(n : Int) -> Bool {
  n > 0 && (n & (n - 1)) == 0
}

///|
/// Returns log2 of `n`, where `n` must be an exact power of two.
///
/// For example, `log2_pow2(8)` returns `3`.
fn log2_pow2(n : Int) -> Int {
  for v = n, bits = 0; v > 1; {
    continue v / 2, bits + 1
  } nobreak {
    bits
  }
}

///|
/// Returns the number of set bits (popcount / Hamming weight) in `x`.
///
/// Uses Brian Kernighan's trick: each `x & (x-1)` clears the lowest set bit,
/// so the loop runs exactly `popcount(x)` times.
fn popcount(x : Int) -> Int {
  for v = x, cnt = 0; v > 0; {
    continue v & (v - 1), cnt + 1
  } nobreak {
    cnt
  }
}

///|
/// Computes the subset convolution of `f` and `g`.
///
/// Given functions `f` and `g` defined on all subsets of {0..n-1} (encoded as
/// integer bitmasks), returns `h` where:
///
/// ```
/// h[S] = Σ_{T ⊆ S} f[T] · g[S \ T]
/// ```
///
/// Every disjoint pair (T, S\T) that partitions S contributes `f[T] · g[S\T]`.
///
/// ## Requirements
///
/// - Both inputs must have length 2^n for some n ≥ 0.
/// - If the inputs differ in length, the shorter one is zero-padded to match
///   the length of the longer one.
/// - Returns an empty array if the inputs are empty or not a power-of-two
///   length.
///
/// ## Algorithm
///
/// 1. **Stratify**: place `f[S]` into layer `F[popcount(S)]`, and likewise
///    for `g`. Each layer has size 2^n.
///
/// 2. **Zeta transform** each layer: `F̂[k][S] = Σ_{T⊆S} F[k][T]`.
///    Implemented as n passes, one per bit, each propagating values from
///    subsets to their supersets.
///
/// 3. **Rank convolution**: at each position S independently, multiply the
///    two rank-polynomials pointwise:
///    `Ĥ[k][S] = Σ_{i=0..k} F̂[i][S] · Ĝ[k-i][S]`.
///
/// 4. **Inverse zeta (Mobius) transform** each result layer: undo the
///    subset-sum accumulation by subtracting instead of adding.
///
/// 5. **Extract**: `h[S] = H[popcount(S)][S]`.
///
/// ## Complexity
///
/// - Time:  O(n^2 * 2^n)
/// - Space: O(n * 2^n)
///
/// Practical for n ≤ 20.
///
/// ## Example
///
/// ```
/// f = [1, 2, 3, 4]   (∅→1, {0}→2, {1}→3, {0,1}→4)
/// g = [5, 6, 7, 8]
///
/// h[∅]     = f[∅]·g[∅]                                         =  5
/// h[{0}]   = f[∅]·g[{0}] + f[{0}]·g[∅]                        = 16
/// h[{1}]   = f[∅]·g[{1}] + f[{1}]·g[∅]                        = 22
/// h[{0,1}] = f[∅]·g[{0,1}]+f[{0}]·g[{1}]+f[{1}]·g[{0}]+f[{0,1}]·g[∅] = 60
/// ```
pub fn subset_convolution(
  f : ArrayView[Int64],
  g : ArrayView[Int64],
) -> Array[Int64] {
  let size = if f.length() > g.length() { f.length() } else { g.length() }
  if size == 0 || !is_power_of_two(size) {
    return []
  }
  let n = log2_pow2(size)
  // Zero-pad inputs to the same length.
  let fpad = Array::make(size, 0L)
  let gpad = Array::make(size, 0L)
  for s in 0..<f.length() {
    fpad[s] = f[s]
  }
  for s in 0..<g.length() {
    gpad[s] = g[s]
  }
  // Phase 1: Stratify by popcount.
  // fpc[k][S] = f[S] if popcount(S) == k, else 0.
  let fpc = [ for _ in 0..<(n + 1) => Array::make(size, 0L) ]
  let gpc = [ for _ in 0..<(n + 1) => Array::make(size, 0L) ]
  for s in 0..<size {
    let k = popcount(s)
    fpc[k][s] = fpad[s]
    gpc[k][s] = gpad[s]
  }
  // Phase 2: Zeta (sum-over-subsets) transform on each rank layer.
  // After this, fpc[k][S] = Σ_{T⊆S, popcount(T)=k} f[T].
  // Each bit b adds the value from the subset without that bit.
  for k in 0..<=n {
    for bit in 0..<n {
      let mask = 1 << bit
      for s in 0..<size {
        if (s & mask) != 0 {
          fpc[k][s] = fpc[k][s] + fpc[k][s ^ mask]
          gpc[k][s] = gpc[k][s] + gpc[k][s ^ mask]
        }
      }
    } where {
      proof_invariant: bit >= 0 && bit <= n,
      proof_reasoning: (
        #|INVARIANT (zeta per k):
        #|After each bit, subset sums for fpc[k]/gpc[k] are correct for the
        #|processed bits.
        #|MAINTENANCE:
        #|Propagate values along the current bit.
        #|TERMINATION:
        #|At bit = n, zeta transform for k is complete.
      ),
    }
  } where {
    proof_invariant: k >= 0 && k <= n + 1,
    proof_reasoning: (
      #|INVARIANT (zeta over k):
      #|Zeta transforms are complete for all popcounts < k.
      #|MAINTENANCE:
      #|Apply zeta transform for popcount k.
      #|TERMINATION:
      #|At k = n+1, all popcount layers are transformed.
    ),
  }
  // Phase 3: Rank-dimension polynomial convolution.
  // hpc[k][S] = Σ_{i=0..k} fpc[i][S] * gpc[k-i][S].
  // Each position S is handled independently as a polynomial product over k.
  let hpc = [ for _ in 0..<(n + 1) => Array::make(size, 0L) ]
  for k in 0..<=n {
    for i in 0..<=k {
      for s in 0..<size {
        hpc[k][s] = hpc[k][s] + fpc[i][s] * gpc[k - i][s]
      }
    } where {
      proof_invariant: i >= 0 && i <= k + 1,
      proof_reasoning: (
        #|INVARIANT (popcount convolution):
        #|hpc[k] accumulates contributions for i in [0, current).
        #|MAINTENANCE:
        #|Add the contribution from i to hpc[k].
        #|TERMINATION:
        #|At i = k+1, all splits i + (k-i) are processed.
      ),
    }
  } where {
    proof_invariant: k >= 0 && k <= n + 1,
    proof_reasoning: (
      #|INVARIANT (compute hpc):
      #|hpc layers for popcounts < k are fully computed.
      #|MAINTENANCE:
      #|Compute hpc[k] by summing over splits of k.
      #|TERMINATION:
      #|At k = n+1, all popcount layers are computed.
    ),
  }
  // Phase 4: Inverse zeta (Mobius) transform on each rank layer.
  // Subtracts instead of adds to undo the zeta accumulation.
  // After this, hpc[k][S] = Σ_{T⊆S, popcount(T)=k} h[T] for the
  // contribution from splits at rank k.
  for k in 0..<=n {
    for bit in 0..<n {
      let mask = 1 << bit
      for s in 0..<size {
        if (s & mask) != 0 {
          hpc[k][s] = hpc[k][s] - hpc[k][s ^ mask]
        }
      }
    } where {
      proof_invariant: bit >= 0 && bit <= n,
      proof_reasoning: (
        #|INVARIANT (inverse zeta per k):
        #|After each bit, hpc[k] is inverted for the processed bits.
        #|MAINTENANCE:
        #|Subtract contributions for the current bit.
        #|TERMINATION:
        #|At bit = n, inverse transform for k is complete.
      ),
    }
  } where {
    proof_invariant: k >= 0 && k <= n + 1,
    proof_reasoning: (
      #|INVARIANT (inverse zeta over k):
      #|Inverse transforms are complete for all popcounts < k.
      #|MAINTENANCE:
      #|Invert popcount layer k.
      #|TERMINATION:
      #|At k = n+1, all layers are inverted.
    ),
  }
  // Phase 5: Extract the answer from the diagonal rank layer.
  // The correct value for subset S lives in layer popcount(S).
  let h = Array::make(size, 0L)
  for s in 0..<size {
    let k = popcount(s)
    h[s] = hpc[k][s]
  }
  h
}

///|
test "subset_convolution" {
  assert_eq(subset_convolution([1L, 1L, 1L, 1L][:], [1L, 1L, 1L, 1L][:]), [
    1L, 2L, 2L, 4L,
  ])
}
