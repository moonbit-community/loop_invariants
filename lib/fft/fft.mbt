// ============================================================================
// FFT/NTT - Fast Polynomial Multiplication
// ============================================================================
//
// Fast Fourier Transform (FFT) and Number Theoretic Transform (NTT) enable
// O(n log n) polynomial multiplication by converting to/from point-value form.
//
// KEY INSIGHT: Multiplying polynomials in coefficient form is O(n²), but
// in point-value form (evaluations) it's O(n). FFT converts in O(n log n).
//
// NTT BASICS:
// Uses primitive roots of unity in modular arithmetic instead of complex numbers.
// For prime p = k * 2^m + 1, primitive root g exists where g^((p-1)/2^m) is
// a 2^m-th root of unity modulo p.
//
// Common NTT-friendly primes:
// - 998244353 = 119 * 2^23 + 1, primitive root = 3
// - 167772161 = 5 * 2^25 + 1, primitive root = 3
//
// ALGORITHM (Cooley-Tukey):
// 1. Bit-reverse permutation of coefficients
// 2. Iteratively combine pairs using butterfly operations
// 3. For inverse, use conjugate roots and divide by n
//
// INVARIANTS:
// 1. After stage k, groups of 2^k elements are DFT of their original positions
// 2. Bit-reversal maps index i to bit-reverse(i), preserving correct DFT ordering
// 3. After inverse transform and division by n, original coefficients recovered
//
// TIME COMPLEXITY: O(n log n)
// SPACE COMPLEXITY: O(n)

///|
const NTT_MOD : Int64 = 998244353L

///|
const NTT_ROOT : Int64 = 3L

///|
/// Fast modular exponentiation
fn mod_pow(base : Int64, exp : Int64, m : Int64) -> Int64 {
  for e = exp, result = 1L, b = base % m; e > 0L; {
    let next_result = if e % 2L == 1L { result * b % m } else { result }
    continue e / 2L, next_result, b * b % m
  } else {
    result
  } where {
    invariant: e >= 0L,
    reasoning: (
      #|INVARIANT (fast exponentiation):
      #|result * b^e (mod m) equals base^exp (mod m), and b holds the current
      #|square base for the remaining exponent bits.
      #|MAINTENANCE:
      #|If e is odd, multiply result by b; then square b and halve e, preserving
      #|result * b^e as the original power.
      #|TERMINATION:
      #|e halves each step, so it reaches 0 and the loop returns result.
    ),
  }
}

///|
/// Compute bit reversal of index
fn bit_reverse(x : Int, bits : Int) -> Int {
  let mut result = 0
  let mut v = x
  for i = 0; i < bits; i = i + 1 {
    result = (result << 1) | (v & 1)
    v = v >> 1
  } where {
    invariant: i >= 0 && i <= bits,
    reasoning: (
      #|INVARIANT (bit reverse):
      #|result is the reverse of the lowest i bits of x; v equals x >> i.
      #|MAINTENANCE:
      #|Shift result left, append v's lowest bit, then shift v right.
      #|TERMINATION:
      #|At i = bits, result is the full bit-reversal of x.
    ),
  }
  result
}

///|
/// Number Theoretic Transform
priv struct NTT {
  n : Int // Must be power of 2
  log_n : Int
  root : Int64
  root_inv : Int64
  mod_val : Int64
}

///|
fn NTT::new(size : Int) -> NTT {
  // Find smallest power of 2 >= size
  let (n, log_n) = for n = 1, log_n = 0; n < size; {
    continue n * 2, log_n + 1
  } else {
    (n, log_n)
  } where {
    invariant: n >= 1,
    invariant: log_n >= 0,
    reasoning: (
      #|INVARIANT (power-of-two growth):
      #|n equals 2^log_n and is the smallest power of two checked so far.
      #|MAINTENANCE:
      #|Doubling n and incrementing log_n preserves n = 2^log_n.
      #|TERMINATION:
      #|n grows exponentially, so eventually n >= size.
    ),
  }
  let root = mod_pow(NTT_ROOT, (NTT_MOD - 1L) / n.to_int64(), NTT_MOD)
  let root_inv = mod_pow(root, NTT_MOD - 2L, NTT_MOD)
  { n, log_n, root, root_inv, mod_val: NTT_MOD }
}

///|
/// Perform NTT in-place
fn NTT::transform(self : NTT, a : Array[Int64], inverse : Bool) -> Unit {
  let n = self.n

  // Bit-reverse permutation
  for i = 0; i < n; i = i + 1 {
    let j = bit_reverse(i, self.log_n)
    if i < j {
      let tmp = a[i]
      a[i] = a[j]
      a[j] = tmp
    }
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (Bit-reversal):
      #|For all indices < i, a has been swapped into its bit-reversed position.
      #|We only swap when i < j to avoid undoing a previous swap, so each pair
      #|is processed exactly once. This prepares the array for iterative
      #|Cooley-Tukey butterflies.
      #|MAINTENANCE:
      #|Processing index i performs at most one swap and preserves the invariant
      #|for the next prefix.
      #|TERMINATION:
      #|At i == n, the permutation is fully applied.
    ),
  }

  // Cooley-Tukey NTT
  for len = 2; len <= n; {
    let w_base = if inverse { self.root_inv } else { self.root }
    let w = mod_pow(w_base, (n / len).to_int64(), self.mod_val)
    for i = 0; i < n; i = i + len {
      let mut wn = 1L
      for j = 0; j < len / 2; j = j + 1 {
        let u = a[i + j]
        let v = a[i + j + len / 2] * wn % self.mod_val
        a[i + j] = (u + v) % self.mod_val
        a[i + j + len / 2] = ((u - v) % self.mod_val + self.mod_val) %
          self.mod_val
        wn = wn * w % self.mod_val
      } where {
        invariant: j >= 0 && j <= len / 2,
        reasoning: (
          #|INVARIANT (butterflies):
          #|Within this block, positions [0..j) are transformed; wn equals w^j.
          #|MAINTENANCE:
          #|Apply the butterfly at j using wn, then advance wn *= w.
          #|TERMINATION:
          #|At j = len/2, the block is fully transformed for this stage.
        ),
      }
    } where {
      invariant: i >= 0 && i <= n,
      reasoning: (
        #|INVARIANT (stage blocks):
        #|All blocks starting at indices < i are transformed for length len.
        #|MAINTENANCE:
        #|Process the block at i with its butterflies.
        #|TERMINATION:
        #|At i = n, all blocks for this stage are complete.
      ),
    }
    continue len * 2
  } where {
    invariant: len >= 2 && len <= n * 2,
    reasoning: (
      #|INVARIANT (NTT stages):
      #|len is the current butterfly size; all previous stages with smaller
      #|sizes have been fully applied to a.
      #|MAINTENANCE:
      #|Processing all blocks of size len completes this stage, then doubling
      #|len advances to the next stage.
      #|TERMINATION:
      #|len doubles each step and exceeds n, completing all stages.
    ),
  }

  // For inverse, divide by n
  if inverse {
    let n_inv = mod_pow(n.to_int64(), self.mod_val - 2L, self.mod_val)
    for i = 0; i < n; i = i + 1 {
      a[i] = a[i] * n_inv % self.mod_val
    } where {
      invariant: i >= 0 && i <= n,
      reasoning: (
        #|INVARIANT (Inverse scaling):
        #|After processing indices [0..i), a[t] has been multiplied by n_inv
        #|to normalize the inverse NTT. When i reaches n, all coefficients are
        #|scaled by 1/n as required.
        #|MAINTENANCE:
        #|Multiplying a[i] by n_inv extends the normalized prefix by one.
        #|TERMINATION:
        #|At i == n, all coefficients are normalized.
      ),
    }
  }
}

///|
/// Multiply two polynomials modulo NTT_MOD
fn NTT::multiply(
  self : NTT,
  a : Array[Int64],
  b : Array[Int64],
) -> Array[Int64] {
  let n = self.n

  // Pad arrays to size n
  let pa = Array::make(n, 0L)
  let pb = Array::make(n, 0L)
  for i = 0; i < a.length() && i < n; i = i + 1 {
    pa[i] = a[i] % self.mod_val
  } where {
    invariant: i >= 0 && i <= a.length() && i <= n,
    reasoning: (
      #|INVARIANT (Pad a):
      #|pa[0..i) matches a[0..i) modulo mod_val, and remaining entries are 0.
      #|MAINTENANCE:
      #|Assign pa[i] = a[i] % mod_val to extend the padded prefix.
      #|TERMINATION:
      #|At i = min(a.length(), n), padding of a is complete.
    ),
  }
  for i = 0; i < b.length() && i < n; i = i + 1 {
    pb[i] = b[i] % self.mod_val
  } where {
    invariant: i >= 0 && i <= b.length() && i <= n,
    reasoning: (
      #|INVARIANT (Pad b):
      #|pb[0..i) matches b[0..i) modulo mod_val, and remaining entries are 0.
      #|MAINTENANCE:
      #|Assign pb[i] = b[i] % mod_val to extend the padded prefix.
      #|TERMINATION:
      #|At i = min(b.length(), n), padding of b is complete.
    ),
  }

  // Transform both
  self.transform(pa, false)
  self.transform(pb, false)

  // Point-wise multiplication
  for i = 0; i < n; i = i + 1 {
    pa[i] = pa[i] * pb[i] % self.mod_val
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (Point-wise product):
      #|After processing indices [0..i), pa[t] equals NTT(a)[t] * NTT(b)[t]
      #|mod mod_val for all t < i. By the convolution theorem, this is the
      #|NTT of the coefficient-wise convolution. The inverse transform then
      #|recovers the product polynomial.
      #|MAINTENANCE:
      #|Multiplying pa[i] by pb[i] extends the point-wise product prefix.
      #|TERMINATION:
      #|At i == n, all frequency components are multiplied.
    ),
  }

  // Inverse transform
  self.transform(pa, true)
  pa
}

// ============================================================================
// SIMPLE POLYNOMIAL MULTIPLICATION (for comparison)
// ============================================================================

///|
/// O(n²) naive polynomial multiplication
fn poly_multiply_naive(a : Array[Int64], b : Array[Int64]) -> Array[Int64] {
  if a.length() == 0 || b.length() == 0 {
    return []
  }
  let result = Array::make(a.length() + b.length() - 1, 0L)
  for i = 0; i < a.length(); i = i + 1 {
    for j = 0; j < b.length(); j = j + 1 {
      result[i + j] = (result[i + j] + a[i] * b[j]) % NTT_MOD
    } where {
      invariant: j >= 0 && j <= b.length(),
      reasoning: (
        #|INVARIANT (Inner products):
        #|After processing j, result[i + t] includes contribution from
        #|a[i] * b[t] for all t < j. This accumulates all pairs for fixed i.
        #|MAINTENANCE:
        #|Each step adds a[i] * b[j] to result[i + j], extending the prefix.
        #|TERMINATION:
        #|At j == b.length(), all products for row i are accumulated.
      ),
    }
  } where {
    invariant: i >= 0 && i <= a.length(),
    reasoning: (
      #|INVARIANT (Outer accumulation):
      #|After processing i, result includes contributions from all pairs
      #|a[0..i) * b[*], so each coefficient has the sum of products for
      #|those leading terms.
      #|MAINTENANCE:
      #|Completing the inner loop adds all pairs for row i.
      #|TERMINATION:
      #|At i == a.length(), all coefficient products are summed.
    ),
  }
  result
}

// ============================================================================
// KARATSUBA MULTIPLICATION (O(n^1.58))
// ============================================================================

///|
/// Karatsuba polynomial multiplication
fn poly_multiply_karatsuba(a : Array[Int64], b : Array[Int64]) -> Array[Int64] {
  let n = a.length()
  let m = b.length()
  if n == 0 || m == 0 {
    return []
  }
  if n < 32 || m < 32 {
    return poly_multiply_naive(a, b)
  }
  let half = (if n > m { n } else { m }) / 2

  // Split: a = a_low + x^half * a_high
  let a_low : Array[Int64] = []
  let a_high : Array[Int64] = []
  for i = 0; i < a.length(); i = i + 1 {
    if i < half {
      a_low.push(a[i])
    } else {
      a_high.push(a[i])
    }
  } where {
    invariant: i >= 0 && i <= a.length(),
    reasoning: (
      #|INVARIANT (Split a):
      #|a_low contains a[0..min(i,half)) and a_high contains a[half..i) for
      #|elements already processed. This partitions a into low/high halves.
      #|MAINTENANCE:
      #|Each element a[i] is appended to the appropriate half.
      #|TERMINATION:
      #|At i == a.length(), the split is complete.
    ),
  }
  let b_low : Array[Int64] = []
  let b_high : Array[Int64] = []
  for i = 0; i < b.length(); i = i + 1 {
    if i < half {
      b_low.push(b[i])
    } else {
      b_high.push(b[i])
    }
  } where {
    invariant: i >= 0 && i <= b.length(),
    reasoning: (
      #|INVARIANT (Split b):
      #|b_low contains b[0..min(i,half)) and b_high contains b[half..i)
      #|for processed indices, splitting b into low/high halves.
      #|MAINTENANCE:
      #|Each element b[i] is appended to the appropriate half.
      #|TERMINATION:
      #|At i == b.length(), the split is complete.
    ),
  }

  // Recursive multiplications
  let z0 = poly_multiply_karatsuba(a_low, b_low)
  let z2 = poly_multiply_karatsuba(a_high, b_high)

  // z1 = (a_low + a_high)(b_low + b_high) - z0 - z2
  let a_sum : Array[Int64] = []
  let b_sum : Array[Int64] = []
  let max_low = if a_low.length() > a_high.length() {
    a_low.length()
  } else {
    a_high.length()
  }
  for i = 0; i < max_low; i = i + 1 {
    let av = if i < a_low.length() { a_low[i] } else { 0L }
    let ah = if i < a_high.length() { a_high[i] } else { 0L }
    a_sum.push((av + ah) % NTT_MOD)
  } where {
    invariant: i >= 0 && i <= max_low,
    reasoning: (
      #|INVARIANT (a_low + a_high):
      #|a_sum[0..i) holds the coefficient-wise sum of a_low and a_high,
      #|padding with zeros when one half is shorter.
      #|MAINTENANCE:
      #|Each step appends one summed coefficient to a_sum.
      #|TERMINATION:
      #|At i == max_low, the summed vector is complete.
    ),
  }
  let max_low_b = if b_low.length() > b_high.length() {
    b_low.length()
  } else {
    b_high.length()
  }
  for i = 0; i < max_low_b; i = i + 1 {
    let bv = if i < b_low.length() { b_low[i] } else { 0L }
    let bh = if i < b_high.length() { b_high[i] } else { 0L }
    b_sum.push((bv + bh) % NTT_MOD)
  } where {
    invariant: i >= 0 && i <= max_low_b,
    reasoning: (
      #|INVARIANT (b_low + b_high):
      #|b_sum[0..i) holds the coefficient-wise sum of b_low and b_high,
      #|with zero padding as needed.
      #|MAINTENANCE:
      #|Each step appends one summed coefficient to b_sum.
      #|TERMINATION:
      #|At i == max_low_b, the summed vector is complete.
    ),
  }
  let z1_full = poly_multiply_karatsuba(a_sum, b_sum)

  // Combine: result = z0 + x^half * z1 + x^(2*half) * z2
  let result_len = n + m - 1
  let result = Array::make(result_len, 0L)
  for i = 0; i < z0.length(); i = i + 1 {
    result[i] = (result[i] + z0[i]) % NTT_MOD
  } where {
    invariant: i >= 0 && i <= z0.length(),
    reasoning: (
      #|INVARIANT (z0 add):
      #|result[0..i) includes the low-part contribution z0, corresponding to
      #|coefficients of degree < half.
      #|MAINTENANCE:
      #|Adding z0[i] extends the low-part contribution by one coefficient.
      #|TERMINATION:
      #|At i == z0.length(), all low coefficients are added.
    ),
  }
  for i = 0; i < z1_full.length(); i = i + 1 {
    if i + half < result_len {
      let sub = if i < z0.length() { z0[i] } else { 0L }
      let sub2 = if i < z2.length() { z2[i] } else { 0L }
      result[i + half] = (
          (result[i + half] + z1_full[i] - sub - sub2) % NTT_MOD + NTT_MOD
        ) %
        NTT_MOD
    }
  } where {
    invariant: i >= 0 && i <= z1_full.length(),
    reasoning: (
      #|INVARIANT (z1 correction):
      #|result[half..half+i) has been updated with z1_full minus z0 and z2,
      #|which isolates the middle coefficients of the Karatsuba combine.
      #|MAINTENANCE:
      #|Updating index i extends the corrected middle band by one coefficient.
      #|TERMINATION:
      #|At i == z1_full.length(), all middle coefficients are corrected.
    ),
  }
  for i = 0; i < z2.length(); i = i + 1 {
    if i + 2 * half < result_len {
      result[i + 2 * half] = (result[i + 2 * half] + z2[i]) % NTT_MOD
    }
  } where {
    invariant: i >= 0 && i <= z2.length(),
    reasoning: (
      #|INVARIANT (z2 add):
      #|result[2*half..2*half+i) includes the high-part contribution z2,
      #|corresponding to degrees shifted by 2*half.
      #|MAINTENANCE:
      #|Adding z2[i] extends the high-part contribution by one coefficient.
      #|TERMINATION:
      #|At i == z2.length(), all high coefficients are added.
    ),
  }
  result
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "ntt basic multiplication" {
  // (1 + 2x) * (3 + 4x) = 3 + 10x + 8x²
  let a : Array[Int64] = [1L, 2L]
  let b : Array[Int64] = [3L, 4L]
  let ntt = NTT::new(4)
  let result = ntt.multiply(a, b)
  inspect(result[0], content="3")
  inspect(result[1], content="10")
  inspect(result[2], content="8")
}

///|
test "ntt larger multiplication" {
  // (1 + x + x²) * (1 + x + x²) = 1 + 2x + 3x² + 2x³ + x⁴
  let a : Array[Int64] = [1L, 1L, 1L]
  let b : Array[Int64] = [1L, 1L, 1L]
  let ntt = NTT::new(8)
  let result = ntt.multiply(a, b)
  inspect(result[0], content="1")
  inspect(result[1], content="2")
  inspect(result[2], content="3")
  inspect(result[3], content="2")
  inspect(result[4], content="1")
}

///|
test "ntt vs naive" {
  let a : Array[Int64] = [1L, 2L, 3L, 4L]
  let b : Array[Int64] = [5L, 6L, 7L, 8L]
  let ntt = NTT::new(8)
  let ntt_result = ntt.multiply(a, b)
  let naive_result = poly_multiply_naive(a, b)
  for i in 0..<naive_result.length() {
    inspect(ntt_result[i] == naive_result[i], content="true")
  }
}

///|
test "karatsuba vs naive" {
  let a : Array[Int64] = [1L, 2L, 3L, 4L, 5L]
  let b : Array[Int64] = [6L, 7L, 8L, 9L, 10L]
  let karatsuba_result = poly_multiply_karatsuba(a, b)
  let naive_result = poly_multiply_naive(a, b)
  inspect(karatsuba_result.length() == naive_result.length(), content="true")
  for i in 0..<naive_result.length() {
    inspect(karatsuba_result[i] == naive_result[i], content="true")
  }
}

///|
test "mod_pow" {
  inspect(mod_pow(3L, 0L, 7L), content="1")
  inspect(mod_pow(3L, 1L, 7L), content="3")
  inspect(mod_pow(3L, 2L, 7L), content="2") // 9 % 7 = 2
  inspect(mod_pow(2L, 10L, 1000L), content="24") // 1024 % 1000 = 24
}

///|
test "bit_reverse" {
  inspect(bit_reverse(0, 3), content="0")
  inspect(bit_reverse(1, 3), content="4") // 001 -> 100
  inspect(bit_reverse(2, 3), content="2") // 010 -> 010
  inspect(bit_reverse(3, 3), content="6") // 011 -> 110
}
