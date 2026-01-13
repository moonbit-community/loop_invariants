// ============================================================================
// SUBSET CONVOLUTION
// ============================================================================
//
// Given functions f and g on subsets of {0..n-1} (arrays of length 2^n),
// compute h[S] = sum_{A subset S} f[A] * g[S \ A].
//
// This implementation uses the standard O(n^2 * 2^n) approach:
// - Split by popcount
// - Zeta transform per popcount
// - Convolution in popcount dimension
// - Inverse zeta transform

///|
fn is_power_of_two(n : Int) -> Bool {
  n > 0 && (n & (n - 1)) == 0
}

///|
fn log2_pow2(n : Int) -> Int {
  let mut bits = 0
  let mut v = n
  while v > 1 {
    v = v / 2
    bits = bits + 1
  }
  bits
}

///|
fn popcount(x : Int) -> Int {
  let mut v = x
  let mut cnt = 0
  while v > 0 {
    v = v & (v - 1)
    cnt = cnt + 1
  }
  cnt
}

///|
/// Subset convolution of f and g (arrays of length 2^n).
pub fn subset_convolution(
  f : ArrayView[Int64],
  g : ArrayView[Int64],
) -> Array[Int64] {
  let size = if f.length() > g.length() { f.length() } else { g.length() }
  if size == 0 || not(is_power_of_two(size)) {
    return []
  }
  let n = log2_pow2(size)
  let fpad = Array::make(size, 0L)
  let gpad = Array::make(size, 0L)
  for s in 0..<f.length() {
    fpad[s] = f[s]
  }
  for s in 0..<g.length() {
    gpad[s] = g[s]
  }
  let fpc = Array::makei(n + 1, _ => Array::make(size, 0L))
  let gpc = Array::makei(n + 1, _ => Array::make(size, 0L))
  for s in 0..<size {
    let k = popcount(s)
    fpc[k][s] = fpad[s]
    gpc[k][s] = gpad[s]
  }
  for k = 0; k <= n; k = k + 1 {
    for bit = 0; bit < n; bit = bit + 1 {
      let mask = 1 << bit
      for s in 0..<size {
        if (s & mask) != 0 {
          fpc[k][s] = fpc[k][s] + fpc[k][s ^ mask]
          gpc[k][s] = gpc[k][s] + gpc[k][s ^ mask]
        }
      }
    } where {
      invariant: bit >= 0 && bit <= n,
      reasoning: (
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
    invariant: k >= 0 && k <= n + 1,
    reasoning: (
      #|INVARIANT (zeta over k):
      #|Zeta transforms are complete for all popcounts < k.
      #|MAINTENANCE:
      #|Apply zeta transform for popcount k.
      #|TERMINATION:
      #|At k = n+1, all popcount layers are transformed.
    ),
  }
  let hpc = Array::makei(n + 1, _ => Array::make(size, 0L))
  for k = 0; k <= n; k = k + 1 {
    for i = 0; i <= k; i = i + 1 {
      for s in 0..<size {
        hpc[k][s] = hpc[k][s] + fpc[i][s] * gpc[k - i][s]
      }
    } where {
      invariant: i >= 0 && i <= k + 1,
      reasoning: (
        #|INVARIANT (popcount convolution):
        #|hpc[k] accumulates contributions for i in [0, current).
        #|MAINTENANCE:
        #|Add the contribution from i to hpc[k].
        #|TERMINATION:
        #|At i = k+1, all splits i + (k-i) are processed.
      ),
    }
  } where {
    invariant: k >= 0 && k <= n + 1,
    reasoning: (
      #|INVARIANT (compute hpc):
      #|hpc layers for popcounts < k are fully computed.
      #|MAINTENANCE:
      #|Compute hpc[k] by summing over splits of k.
      #|TERMINATION:
      #|At k = n+1, all popcount layers are computed.
    ),
  }
  for k = 0; k <= n; k = k + 1 {
    for bit = 0; bit < n; bit = bit + 1 {
      let mask = 1 << bit
      for s in 0..<size {
        if (s & mask) != 0 {
          hpc[k][s] = hpc[k][s] - hpc[k][s ^ mask]
        }
      }
    } where {
      invariant: bit >= 0 && bit <= n,
      reasoning: (
        #|INVARIANT (inverse zeta per k):
        #|After each bit, hpc[k] is inverted for the processed bits.
        #|MAINTENANCE:
        #|Subtract contributions for the current bit.
        #|TERMINATION:
        #|At bit = n, inverse transform for k is complete.
      ),
    }
  } where {
    invariant: k >= 0 && k <= n + 1,
    reasoning: (
      #|INVARIANT (inverse zeta over k):
      #|Inverse transforms are complete for all popcounts < k.
      #|MAINTENANCE:
      #|Invert popcount layer k.
      #|TERMINATION:
      #|At k = n+1, all layers are inverted.
    ),
  }
  let h = Array::make(size, 0L)
  for s in 0..<size {
    let k = popcount(s)
    h[s] = hpc[k][s]
  }
  h
}
