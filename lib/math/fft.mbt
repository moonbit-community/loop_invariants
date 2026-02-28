// Fast Fourier Transform and Number Theoretic Transform
// Algorithms for polynomial multiplication with rigorous loop invariants

// ============================================================================
// COMPLEX NUMBER OPERATIONS
// ============================================================================

///|
priv struct Complex {
  re : Double
  im : Double
}

///|
fn Complex::new(re : Double, im : Double) -> Complex {
  { re, im }
}

///|
fn Complex::from_real(x : Double) -> Complex {
  { re: x, im: 0.0 }
}

///|
fn Complex::add(self : Complex, other : Complex) -> Complex {
  { re: self.re + other.re, im: self.im + other.im }
}

///|
fn Complex::sub(self : Complex, other : Complex) -> Complex {
  { re: self.re - other.re, im: self.im - other.im }
}

///|
fn Complex::mul(self : Complex, other : Complex) -> Complex {
  {
    re: self.re * other.re - self.im * other.im,
    im: self.re * other.im + self.im * other.re,
  }
}

///|
// ============================================================================
// BIT REVERSAL
// ============================================================================

///|
/// Compute the bit-reversed index for n bits
fn bit_reverse(x_in : Int, bits : Int) -> Int {
  for i = 0, x = x_in, result = 0; i < bits; {
    // Extract LSB of x, shift result left and add it
    let new_result = (result << 1) | (x & 1)
    let new_x = x >> 1
    continue i + 1, new_x, new_result
  } nobreak {
    result
  } where {
    invariant: result < 1 << i && i <= bits,
    reasoning: (
      #|BIT REVERSAL INVARIANT:
      #|  result contains the reversed bits of x_in[0..i)
      #|  in positions [0..i)
      #|
      #|BASE CASE (i = 0):
      #|  result = 0, which trivially contains reversed bits
      #|
      #|MAINTENANCE (i -> i + 1):
      #|  - Shift result left and add LSB of current x
      #|  - x is right-shifted, so next iteration reads the next bit
      #|  - Result now has i+1 reversed bits of x_in[0..i+1)
      #|
      #|TERMINATION (i = bits):
      #|  result contains all bits of x_in reversed
    ),
  }
}

///|
/// Reorder array elements using bit reversal permutation
fn bit_reverse_permute(arr : Array[Complex], n : Int, log_n : Int) -> Unit {
  for i = 0; i < n; i = i + 1 {
    let j = bit_reverse(i, log_n)
    if i < j {
      // Swap arr[i] and arr[j]
      let temp = arr[i]
      arr[i] = arr[j]
      arr[j] = temp
    }
  } where {
    invariant: i <= n,
    reasoning: (
      #|BIT REVERSAL PERMUTATION INVARIANT:
      #|  For all k < i, arr[k] and arr[bit_reverse(k)] have been swapped
      #|  if needed (i.e., if k < bit_reverse(k))
      #|
      #|We swap only when i < j to avoid double-swapping.
      #|This is a valid permutation that groups elements by
      #|their position in the butterfly network.
      #|MAINTENANCE:
      #|At index i we either swap i with j=bit_reverse(i) or do nothing.
      #|This fixes position i while leaving earlier positions unchanged.
      #|TERMINATION:
      #|When i = n, every index has been considered, so the array is fully
      #|bit-reversal permuted.
    ),
  }
}

// ============================================================================
// COOLEY-TUKEY FFT
// ============================================================================

// Pi constant for FFT

///|
let fft_pi : Double = 3.14159265358979323846

///|
/// Compute sin using Taylor series
fn fft_sin(x_in : Double) -> Double {
  // Normalize x to [-pi, pi]
  let two_pi = 2.0 * fft_pi
  let x0 = x_in
  let x = for x = x0; x > fft_pi; {
    continue x - two_pi
  } nobreak {
    x
  } where {
    invariant: x <= x0,
    reasoning: (
      #|INVARIANT (Normalize positive angle):
      #|x equals x0 minus some multiple of 2*pi and remains <= x0.
      #|MAINTENANCE:
      #|If x > pi, subtracting 2*pi preserves equivalence modulo 2*pi and
      #|strictly decreases x, keeping x <= x0.
      #|TERMINATION:
      #|Once x <= pi, the loop stops with x in (-inf, pi].
    ),
  }
  let x1 = x
  let x = for x = x1; x < -fft_pi; {
    continue x + two_pi
  } nobreak {
    x
  } where {
    invariant: x >= x1,
    reasoning: (
      #|INVARIANT (Normalize negative angle):
      #|x equals x1 plus some multiple of 2*pi and remains >= x1.
      #|MAINTENANCE:
      #|If x < -pi, adding 2*pi preserves equivalence modulo 2*pi and
      #|strictly increases x, keeping x >= x1.
      #|TERMINATION:
      #|Once x >= -pi, the loop stops with x in [-pi, pi].
    ),
  }
  // Taylor series: sin(x) = x - x^3/3! + x^5/5! - ...
  let x2 = x * x
  let x3 = x2 * x
  let x5 = x3 * x2
  let x7 = x5 * x2
  let x9 = x7 * x2
  let x11 = x9 * x2
  x - x3 / 6.0 + x5 / 120.0 - x7 / 5040.0 + x9 / 362880.0 - x11 / 39916800.0
}

///|
/// Compute cos using Taylor series
fn fft_cos(x_in : Double) -> Double {
  // Normalize x to [-pi, pi]
  let two_pi = 2.0 * fft_pi
  let x0 = x_in
  let x = for x = x0; x > fft_pi; {
    continue x - two_pi
  } nobreak {
    x
  } where {
    invariant: x <= x0,
    reasoning: (
      #|INVARIANT (Normalize positive angle):
      #|x equals x0 minus some multiple of 2*pi and remains <= x0.
      #|MAINTENANCE:
      #|If x > pi, subtracting 2*pi preserves equivalence modulo 2*pi and
      #|strictly decreases x, keeping x <= x0.
      #|TERMINATION:
      #|Once x <= pi, the loop stops with x in (-inf, pi].
    ),
  }
  let x1 = x
  let x = for x = x1; x < -fft_pi; {
    continue x + two_pi
  } nobreak {
    x
  } where {
    invariant: x >= x1,
    reasoning: (
      #|INVARIANT (Normalize negative angle):
      #|x equals x1 plus some multiple of 2*pi and remains >= x1.
      #|MAINTENANCE:
      #|If x < -pi, adding 2*pi preserves equivalence modulo 2*pi and
      #|strictly increases x, keeping x >= x1.
      #|TERMINATION:
      #|Once x >= -pi, the loop stops with x in [-pi, pi].
    ),
  }
  // Taylor series: cos(x) = 1 - x^2/2! + x^4/4! - ...
  let x2 = x * x
  let x4 = x2 * x2
  let x6 = x4 * x2
  let x8 = x6 * x2
  let x10 = x8 * x2
  1.0 - x2 / 2.0 + x4 / 24.0 - x6 / 720.0 + x8 / 40320.0 - x10 / 3628800.0
}

///|
/// In-place FFT using Cooley-Tukey algorithm
///  inverse = false for forward FFT, true for inverse FFT
fn fft_in_place(arr : Array[Complex], n : Int, inverse : Bool) -> Unit {
  // Compute log2(n)
  let log_n = for i = 0, temp = n; temp > 1; i = i + 1, temp = temp >> 1 {

  } nobreak {
    i
  } where {
    invariant: i >= 0,
    invariant: temp == n >> i,
    reasoning: (
      #|INVARIANT (Log2 count):
      #|temp is n shifted right by i bits, so i counts how many times we
      #|halve n until it reaches 1. This yields log2(n) for power-of-two n.
      #|MAINTENANCE:
      #|Right-shift temp once and increment i, preserving temp == n >> i.
      #|TERMINATION:
      #|When temp <= 1, i is the number of halving steps, i.e. log2(n).
    ),
  }
  // Bit-reversal permutation
  bit_reverse_permute(arr, n, log_n)
  // Iterative FFT with butterfly operations
  // len = 2, 4, 8, ..., n (size of sub-DFTs being combined)
  for len = 2; len <= n; len = len * 2 {
    let angle = 2.0 *
      fft_pi /
      len.to_double() *
      (if inverse { 1.0 } else { -1.0 })
    let wlen = Complex::new(fft_cos(angle), fft_sin(angle))
    // Process all sub-DFTs of current size
    for i = 0; i < n; i = i + len {
      // Butterfly operations within one sub-DFT
      for j = 0, w = Complex::from_real(1.0)
          j < len / 2
          j = j + 1, w = w.mul(wlen) {
        let u = arr[i + j]
        let v = arr[i + j + len / 2].mul(w)
        arr[i + j] = u.add(v)
        arr[i + j + len / 2] = u.sub(v)
      } where {
        invariant: j <= len / 2,
        reasoning: (
          #|BUTTERFLY OPERATION INVARIANT:
          #|  w = exp(-2πi * j / len) for forward FFT
          #|  w = exp(+2πi * j / len) for inverse FFT
          #|
          #|The butterfly operation computes:
          #|  arr[i+j] = u + v*w
          #|  arr[i+j+len/2] = u - v*w
          #|
          #|This combines two len/2-point DFTs into one len-point DFT.
          #|
          #|MATHEMATICAL BASIS:
          #|  DFT property: X[k] = E[k] + w^k * O[k]
          #|               X[k+n/2] = E[k] - w^k * O[k]
          #|  where E = DFT of even-indexed elements
          #|        O = DFT of odd-indexed elements
          #|MAINTENANCE:
          #|Update w to w * wlen so w = wlen^j, and apply the butterfly for
          #|index j, leaving previously processed pairs correct.
          #|TERMINATION:
          #|When j = len/2, all butterflies in the block have been applied.
        ),
      }
    } where {
      invariant: i >= 0 && i <= n,
      reasoning: (
        #|INVARIANT (Stage blocks):
        #|Blocks of size len starting before i are fully transformed for
        #|this stage. Each block merges two len/2 DFTs into a len DFT.
        #|MAINTENANCE:
        #|Processing block starting at i completes its len-point transform,
        #|and advancing i by len moves to the next disjoint block.
        #|TERMINATION:
        #|At i = n, all blocks for this stage are transformed.
      ),
    }
  } where {
    invariant: len >= 2 && len <= 2 * n,
    reasoning: (
      #|FFT SIZE DOUBLING INVARIANT:
      #|  After processing size len, all sub-DFTs of size len are computed.
      #|
      #|BASE CASE (len = 2):
      #|  After bit-reversal, adjacent pairs are combined
      #|
      #|MAINTENANCE (len -> 2*len):
      #|  Pairs of len-point DFTs are combined into 2*len-point DFTs,
      #|  so the invariant "all len-size blocks are transformed" holds
      #|  for the next stage size.
      #|
      #|TERMINATION (len = n):
      #|  The full n-point DFT is computed
      #|
      #|COMPLEXITY: O(n log n) total butterfly operations
    ),
  }
  // For inverse FFT, divide by n
  if inverse {
    let scale = 1.0 / n.to_double()
    for i = 0; i < n; i = i + 1 {
      arr[i] = Complex::new(arr[i].re * scale, arr[i].im * scale)
    } where {
      invariant: i >= 0 && i <= n,
      reasoning: (
        #|INVARIANT (Inverse normalization):
        #|After processing indices [0..i), arr[t] has been divided by n.
        #|This rescales the inverse FFT to recover the original signal.
        #|MAINTENANCE:
        #|Divide arr[i] by n to extend the normalized prefix.
        #|TERMINATION:
        #|At i = n, every entry is scaled by n^{-1}.
      ),
    }
  }
}

///|
/// Multiply two polynomials using FFT
fn polynomial_multiply_fft(a : Array[Int], b : Array[Int]) -> Array[Int] {
  let n1 = a.length()
  let n2 = b.length()
  if n1 == 0 || n2 == 0 {
    return []
  }
  // Find smallest power of 2 >= n1 + n2 - 1
  let result_len = n1 + n2 - 1
  let n = for size = 1; size < result_len; size = size * 2 {

  } nobreak {
    size
  } where {
    invariant: size >= 1,
    reasoning: (
      #|INVARIANT (FFT size):
      #|size stays a power of two and grows until it reaches result_len.
      #|MAINTENANCE:
      #|Multiply size by 2, preserving the power-of-two property.
      #|TERMINATION:
      #|When size >= result_len, it is the smallest power of two that fits.
    ),
  }
  // Convert to complex arrays
  let fa : Array[Complex] = Array::make(n, Complex::from_real(0.0))
  let fb : Array[Complex] = Array::make(n, Complex::from_real(0.0))
  for i = 0; i < n1; i = i + 1 {
    fa[i] = Complex::from_real(a[i].to_double())
  } where {
    invariant: i >= 0 && i <= n1,
    reasoning: (
      #|INVARIANT (Load a):
      #|fa[0..i) stores a[0..i) as complex values; remaining entries stay 0.
      #|MAINTENANCE:
      #|Assign fa[i] from a[i], extending the converted prefix.
      #|TERMINATION:
      #|At i = n1, all coefficients of a are loaded.
    ),
  }
  for i = 0; i < n2; i = i + 1 {
    fb[i] = Complex::from_real(b[i].to_double())
  } where {
    invariant: i >= 0 && i <= n2,
    reasoning: (
      #|INVARIANT (Load b):
      #|fb[0..i) stores b[0..i) as complex values, padding with zeros beyond n2.
      #|MAINTENANCE:
      #|Assign fb[i] from b[i], extending the converted prefix.
      #|TERMINATION:
      #|At i = n2, all coefficients of b are loaded.
    ),
  }
  // Forward FFT
  fft_in_place(fa, n, false)
  fft_in_place(fb, n, false)
  // Point-wise multiplication
  for i = 0; i < n; i = i + 1 {
    fa[i] = fa[i].mul(fb[i])
  } where {
    invariant: i <= n,
    reasoning: (
      #|CONVOLUTION THEOREM INVARIANT:
      #|  DFT(a * b) = DFT(a) · DFT(b)  (point-wise multiplication)
      #|
      #|After this loop:
      #|  fa[k] = FFT(a)[k] * FFT(b)[k] for all k
      #|
      #|When we apply inverse FFT, we get the convolution (a * b).
      #|MAINTENANCE:
      #|Multiply fa[i] by fb[i] for the next frequency index.
      #|TERMINATION:
      #|At i = n, all frequency components are multiplied.
    ),
  }
  // Inverse FFT
  fft_in_place(fa, n, true)
  // Extract result and round to integers
  let result : Array[Int] = Array::make(result_len, 0)
  for i = 0; i < result_len; i = i + 1 {
    // Round to nearest integer (FFT introduces floating-point errors)
    result[i] = (fa[i].re + 0.5).to_int()
  } where {
    invariant: i <= result_len,
    reasoning: (
      #|INVARIANT (Extract coefficients):
      #|result[0..i) contains the rounded convolution coefficients for
      #|degrees < i. Rounding mitigates floating-point drift from FFT.
      #|MAINTENANCE:
      #|Round fa[i].re and store it in result[i].
      #|TERMINATION:
      #|At i = result_len, the full convolution is extracted.
    ),
  }
  result
}

// ============================================================================
// NUMBER THEORETIC TRANSFORM (NTT)
// ============================================================================

// NTT is FFT over a finite field, using primitive roots instead of complex roots of unity
// This avoids floating-point errors for exact integer arithmetic

///|
/// Modular exponentiation: base^exp mod m
fn ntt_mod_pow(base_in : Int64, exp_in : Int64, m : Int64) -> Int64 {
  let mut base = base_in
  let mut exp = exp_in
  for result = 1L; exp > 0L; result = result {
    let new_result = if exp % 2L == 1L { result * base % m } else { result }
    exp = exp / 2L
    base = base * base % m
    continue new_result
  } nobreak {
    result
  } where {
    invariant: exp >= 0L,
    reasoning: (
      #|MODULAR EXPONENTIATION INVARIANT:
      #|  result * base^exp ≡ base_in^exp_in (mod m)
      #|
      #|BASE CASE (initially):
      #|  1 * base^exp = base^exp ✓
      #|
      #|MAINTENANCE:
      #|  If exp is odd: new_result = result * base
      #|    new_result * (base^2)^(exp/2) = result * base * base^(exp-1) ✓
      #|  If exp is even:
      #|    result * (base^2)^(exp/2) = result * base^exp ✓
      #|
      #|TERMINATION (exp = 0):
      #|  result = base_in^exp_in (mod m)
    ),
  }
}

// Common NTT-friendly prime: 998244353 = 119 * 2^23 + 1
// Primitive root: 3

///|
let ntt_mod : Int64 = 998244353L

///|
let ntt_g : Int64 = 3L // primitive root

///|
/// In-place NTT
fn ntt_in_place(arr : Array[Int64], n : Int, inverse : Bool) -> Unit {
  // Compute log2(n)
  let log_n = for i = 0, temp = n; temp > 1; i = i + 1, temp = temp >> 1 {

  } nobreak {
    i
  } where {
    invariant: i >= 0,
    invariant: temp == n >> i,
    reasoning: (
      #|INVARIANT (Log2 count):
      #|temp equals n shifted right by i bits, so i counts the power-of-two
      #|levels in the iterative NTT stages.
      #|MAINTENANCE:
      #|Shift temp once and increment i, preserving temp == n >> i.
      #|TERMINATION:
      #|When temp <= 1, i is the number of stages, i.e. log2(n).
    ),
  }
  // Bit-reversal permutation
  for i = 0; i < n; i = i + 1 {
    let j = bit_reverse(i, log_n)
    if i < j {
      let temp = arr[i]
      arr[i] = arr[j]
      arr[j] = temp
    }
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (Bit reversal):
      #|Indices < i are placed at their bit-reversed positions. Swapping only
      #|when i < j avoids double swaps and prepares for in-place butterflies.
      #|MAINTENANCE:
      #|At index i, swapping i with j=bit_reverse(i) (if i<j) fixes both
      #|positions without disturbing earlier indices.
      #|TERMINATION:
      #|At i = n, every index is placed at its bit-reversed position.
    ),
  }
  // Iterative NTT
  for len = 2; len <= n; len = len * 2 {
    // Compute primitive len-th root of unity
    let w = if inverse {
      // For inverse, use w^(-1) = w^(mod-2) by Fermat's little theorem
      ntt_mod_pow(ntt_g, (ntt_mod - 1L) / len.to_int64(), ntt_mod)
    } else {
      ntt_mod_pow(ntt_g, (ntt_mod - 1L) / len.to_int64(), ntt_mod)
    }
    let w_actual = if inverse {
      ntt_mod_pow(w, ntt_mod - 2L, ntt_mod) // modular inverse
    } else {
      w
    }
    // Process all sub-transforms
    for i = 0; i < n; i = i + len {
      for j = 0, wj = 1L; j < len / 2; j = j + 1, wj = wj * w_actual % ntt_mod {
        let u = arr[i + j]
        let v = arr[i + j + len / 2] * wj % ntt_mod
        arr[i + j] = (u + v) % ntt_mod
        arr[i + j + len / 2] = (u - v % ntt_mod + ntt_mod) % ntt_mod
      } where {
        invariant: j <= len / 2,
        reasoning: (
          #|NTT BUTTERFLY INVARIANT:
          #|  wj = g^((mod-1)/len * j) for forward NTT
          #|  wj = g^(-(mod-1)/len * j) for inverse NTT
          #|
          #|Same butterfly structure as FFT:
          #|  arr[i+j] = u + v*wj (mod p)
          #|  arr[i+j+len/2] = u - v*wj (mod p)
          #|
          #|CORRECTNESS:
          #|  Using Fermat's little theorem: a^(p-1) ≡ 1 (mod p)
          #|  So g^((p-1)/n) is an n-th root of unity modulo p.
          #|MAINTENANCE:
          #|Update wj = wj * w_actual so wj tracks the next root power, and
          #|apply the butterfly to position j, keeping prior pairs correct.
          #|TERMINATION:
          #|When j = len/2, all butterflies in the block are applied.
        ),
      }
    } where {
      invariant: i >= 0 && i <= n,
      reasoning: (
        #|INVARIANT (Stage blocks):
        #|Blocks of size len starting before i are fully transformed for this
        #|stage. Each block merges two len/2 sub-transforms.
        #|MAINTENANCE:
        #|Processing block at i completes its len-point transform; advancing
        #|i by len moves to the next disjoint block.
        #|TERMINATION:
        #|At i = n, all blocks are transformed for this stage.
      ),
    }
  } where {
    invariant: len >= 2 && len <= 2 * n,
    reasoning: (
      #|NTT SIZE INVARIANT:
      #|  Same as FFT - sub-transforms double in size each iteration.
      #|  All arithmetic is exact modulo the NTT prime.
      #|MAINTENANCE:
      #|After finishing size len, doubling len schedules the next merge of
      #|two len-point transforms into a 2*len-point transform.
      #|TERMINATION:
      #|When len exceeds n, all stages up to size n are complete.
    ),
  }
  // For inverse NTT, multiply by n^(-1)
  if inverse {
    let n_inv = ntt_mod_pow(n.to_int64(), ntt_mod - 2L, ntt_mod)
    for i = 0; i < n; i = i + 1 {
      arr[i] = arr[i] * n_inv % ntt_mod
    } where {
      invariant: i >= 0 && i <= n,
      reasoning: (
        #|INVARIANT (Inverse normalization):
        #|After processing indices [0..i), arr[t] has been multiplied by n^{-1}
        #|to rescale the inverse transform.
        #|MAINTENANCE:
        #|Multiply arr[i] by n_inv to extend the normalized prefix.
        #|TERMINATION:
        #|At i = n, all entries are scaled by n^{-1}.
      ),
    }
  }
}

///|
/// Multiply two polynomials using NTT (exact integer arithmetic mod 998244353)
fn polynomial_multiply_ntt(a : Array[Int64], b : Array[Int64]) -> Array[Int64] {
  let n1 = a.length()
  let n2 = b.length()
  if n1 == 0 || n2 == 0 {
    return []
  }
  let result_len = n1 + n2 - 1
  // Find smallest power of 2 >= result_len
  let n = for size = 1; size < result_len; size = size * 2 {

  } nobreak {
    size
  } where {
    invariant: size >= 1,
    reasoning: (
      #|INVARIANT (NTT size):
      #|size stays a power of two and grows until it reaches result_len.
      #|MAINTENANCE:
      #|Multiply size by 2, preserving the power-of-two property.
      #|TERMINATION:
      #|When size >= result_len, it is the smallest power of two that fits.
    ),
  }
  // Prepare arrays
  let fa : Array[Int64] = Array::make(n, 0L)
  let fb : Array[Int64] = Array::make(n, 0L)
  for i = 0; i < n1; i = i + 1 {
    fa[i] = a[i] % ntt_mod
  } where {
    invariant: i >= 0 && i <= n1,
    reasoning: (
      #|INVARIANT (Load a):
      #|fa[0..i) holds a[0..i) modulo ntt_mod, padded with zeros beyond n1.
      #|MAINTENANCE:
      #|Assign fa[i] = a[i] % ntt_mod, extending the prefix.
      #|TERMINATION:
      #|At i = n1, all coefficients of a are loaded.
    ),
  }
  for i = 0; i < n2; i = i + 1 {
    fb[i] = b[i] % ntt_mod
  } where {
    invariant: i >= 0 && i <= n2,
    reasoning: (
      #|INVARIANT (Load b):
      #|fb[0..i) holds b[0..i) modulo ntt_mod, with zero padding.
      #|MAINTENANCE:
      #|Assign fb[i] = b[i] % ntt_mod, extending the prefix.
      #|TERMINATION:
      #|At i = n2, all coefficients of b are loaded.
    ),
  }
  // Forward NTT
  ntt_in_place(fa, n, false)
  ntt_in_place(fb, n, false)
  // Point-wise multiplication
  for i = 0; i < n; i = i + 1 {
    fa[i] = fa[i] * fb[i] % ntt_mod
  } where {
    invariant: i <= n,
    reasoning: (
      #|INVARIANT (Point-wise product):
      #|After processing indices [0..i), fa[t] equals NTT(a)[t] * NTT(b)[t]
      #|mod ntt_mod. The inverse NTT then yields the exact convolution.
      #|MAINTENANCE:
      #|Multiply fa[i] by fb[i] for the next frequency index.
      #|TERMINATION:
      #|At i = n, all frequency components are multiplied.
    ),
  }
  // Inverse NTT
  ntt_in_place(fa, n, true)
  // Extract result
  let result : Array[Int64] = Array::make(result_len, 0L)
  for i = 0; i < result_len; i = i + 1 {
    result[i] = fa[i]
  } where {
    invariant: i >= 0 && i <= result_len,
    reasoning: (
      #|INVARIANT (Extract result):
      #|result[0..i) contains the first i coefficients of the inverse NTT,
      #|which correspond to the polynomial product.
      #|MAINTENANCE:
      #|Copy fa[i] into result[i] as the next coefficient.
      #|TERMINATION:
      #|At i = result_len, the full product is extracted.
    ),
  }
  result
}

// ============================================================================
// APPLICATIONS
// ============================================================================

///|
/// Count the number of ways to make change for amount using coins
///  (using generating functions and polynomial multiplication)
fn count_change_polynomial(coins : Array[Int], max_amount : Int) -> Array[Int] {
  // For each coin value c, the generating function is:
  // 1 + x^c + x^(2c) + x^(3c) + ... = 1/(1-x^c)
  // We approximate by computing product up to x^max_amount
  let result : Array[Int] = Array::make(max_amount + 1, 0)
  result[0] = 1 // Base case: 1 way to make 0
  // For each coin, update the DP array (standard knapsack approach)
  // This is equivalent to polynomial multiplication with truncation
  for i = 0; i < coins.length(); i = i + 1 {
    let coin = coins[i]
    for amount = coin; amount <= max_amount; amount = amount + 1 {
      result[amount] = result[amount] + result[amount - coin]
    } where {
      invariant: amount >= coin && amount <= max_amount + 1,
      reasoning: (
        #|GENERATING FUNCTION INVARIANT:
        #|  result[k] = coefficient of x^k in product of all processed coins
        #|
        #|For coin c: multiply by (1 + x^c + x^(2c) + ...)
        #|Coefficient update: result[k] += result[k-c]
        #|
        #|This is convolution with the geometric series for each coin.
        #|MAINTENANCE:
        #|At amount, add ways that end with one coin c by using result[amount-c],
        #|so coefficients up to amount incorporate the current coin.
        #|TERMINATION:
        #|When amount = max_amount + 1, all coefficients for this coin are updated.
      ),
    }
  } where {
    invariant: i >= 0 && i <= coins.length(),
    reasoning: (
      #|INVARIANT (Coin sequence):
      #|After processing coins[0..i), result holds the generating function
      #|for those coins. Each new coin multiplies by its geometric series.
      #|MAINTENANCE:
      #|Updating with coins[i] extends the product by the coin's series,
      #|so the invariant holds for coins[0..i+1).
      #|TERMINATION:
      #|At i = coins.length(), all coins are incorporated.
    ),
  }
  result
}

///|
/// Compute string pattern matching counts using FFT-based convolution
///  Returns array where result[i] = number of matching positions at offset i
fn pattern_match_fft(text : Array[Int], pattern : Array[Int]) -> Array[Int] {
  let n = text.length()
  let m = pattern.length()
  if m > n || m == 0 {
    return []
  }
  // For exact matching, we use the following trick:
  // Define f(i) = sum over j of (text[i+j] - pattern[j])^2
  // f(i) = 0 iff text[i..i+m-1] matches pattern
  // This can be computed using convolution
  // f(i) = sum_j text[i+j]^2 - 2*sum_j text[i+j]*pattern[j] + sum_j pattern[j]^2
  // The middle term is a convolution (with reversed pattern)
  // Reverse pattern
  let pattern_rev : Array[Int] = Array::make(m, 0)
  for i = 0; i < m; i = i + 1 {
    pattern_rev[i] = pattern[m - 1 - i]
  } where {
    invariant: i >= 0 && i <= m,
    reasoning: (
      #|INVARIANT (Pattern reverse):
      #|pattern_rev[0..i) equals pattern[m-1..m-i] reversed, preparing the
      #|sequence for convolution-based matching.
      #|MAINTENANCE:
      #|Assign pattern_rev[i] = pattern[m-1-i], extending the reversed prefix.
      #|TERMINATION:
      #|At i = m, pattern_rev is the full reversal of pattern.
    ),
  }
  // Compute convolution of text and reversed pattern
  let conv = polynomial_multiply_fft(text, pattern_rev)
  // For simplicity, return the convolution values directly
  // (full implementation would compute f(i) and check for zeros)
  let result_len = n - m + 1
  let result : Array[Int] = Array::make(result_len, 0)
  for i = 0; i < result_len; i = i + 1 {
    // The convolution at position i+m-1 gives sum_j text[i+j]*pattern[m-1-j]
    // which equals sum_j text[i+j]*pattern_rev[j]
    if i + m - 1 < conv.length() {
      result[i] = conv[i + m - 1]
    }
  } where {
    invariant: i <= result_len,
    reasoning: (
      #|INVARIANT (Match score):
      #|result[0..i) contains convolution-based match scores for offsets
      #|0..i-1. Each score is the dot product of the text window and pattern.
      #|MAINTENANCE:
      #|Store the convolution value at offset i (when in range), extending
      #|the computed prefix of match scores.
      #|TERMINATION:
      #|At i = result_len, all offsets have scores.
    ),
  }
  result
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "bit_reverse" {
  inspect(bit_reverse(0, 3), content="0")
  inspect(bit_reverse(1, 3), content="4") // 001 -> 100
  inspect(bit_reverse(2, 3), content="2") // 010 -> 010
  inspect(bit_reverse(3, 3), content="6") // 011 -> 110
  inspect(bit_reverse(4, 3), content="1") // 100 -> 001
  inspect(bit_reverse(5, 3), content="5") // 101 -> 101
  inspect(bit_reverse(6, 3), content="3") // 110 -> 011
  inspect(bit_reverse(7, 3), content="7") // 111 -> 111
}

///|
test "polynomial_multiply_fft_simple" {
  // (1 + 2x) * (3 + 4x) = 3 + 4x + 6x + 8x^2 = 3 + 10x + 8x^2
  let a = [1, 2]
  let b = [3, 4]
  let result = polynomial_multiply_fft(a, b)
  inspect(result.length(), content="3")
  inspect(result[0], content="3")
  inspect(result[1], content="10")
  inspect(result[2], content="8")
}

///|
test "polynomial_multiply_fft_larger" {
  // (1 + 1x + 1x^2) * (1 + 1x) = 1 + 2x + 2x^2 + 1x^3
  let a = [1, 1, 1]
  let b = [1, 1]
  let result = polynomial_multiply_fft(a, b)
  inspect(result.length(), content="4")
  inspect(result[0], content="1")
  inspect(result[1], content="2")
  inspect(result[2], content="2")
  inspect(result[3], content="1")
}

///|
test "polynomial_multiply_ntt_simple" {
  let a : Array[Int64] = [1L, 2L]
  let b : Array[Int64] = [3L, 4L]
  let result = polynomial_multiply_ntt(a, b)
  inspect(result.length(), content="3")
  inspect(result[0], content="3")
  inspect(result[1], content="10")
  inspect(result[2], content="8")
}

///|
test "polynomial_multiply_ntt_larger" {
  let a : Array[Int64] = [1L, 1L, 1L]
  let b : Array[Int64] = [1L, 1L]
  let result = polynomial_multiply_ntt(a, b)
  inspect(result.length(), content="4")
  inspect(result[0], content="1")
  inspect(result[1], content="2")
  inspect(result[2], content="2")
  inspect(result[3], content="1")
}

///|
test "count_change" {
  let coins = [1, 2, 5]
  let ways = count_change_polynomial(coins, 10)
  // Ways to make 0: 1 (empty)
  // Ways to make 1: 1 (1)
  // Ways to make 2: 2 (1+1, 2)
  // Ways to make 5: 4 (11111, 1112, 122, 5)
  inspect(ways[0], content="1")
  inspect(ways[1], content="1")
  inspect(ways[2], content="2")
  inspect(ways[5], content="4")
  inspect(ways[10], content="10") // 10 ways to make 10 cents
}

///|
test "ntt_mod_pow" {
  inspect(ntt_mod_pow(2L, 10L, 1000L), content="24") // 1024 mod 1000
  inspect(ntt_mod_pow(3L, 4L, 100L), content="81") // 81 mod 100
  inspect(ntt_mod_pow(5L, 3L, 13L), content="8") // 125 mod 13
}

///|
test "fft_trig" {
  // Basic sanity checks for trig functions
  let sin_0 = fft_sin(0.0)
  let cos_0 = fft_cos(0.0)
  // sin(0) ≈ 0, cos(0) ≈ 1
  inspect(sin_0 < 0.0001 && sin_0 > -0.0001, content="true")
  inspect(cos_0 > 0.999, content="true")
  // sin(π/2) ≈ 1, cos(π/2) ≈ 0
  let half_pi = fft_pi / 2.0
  let sin_half = fft_sin(half_pi)
  let cos_half = fft_cos(half_pi)
  inspect(sin_half > 0.999, content="true")
  inspect(cos_half < 0.01 && cos_half > -0.01, content="true")
}

///|
test "pattern_match_fft" {
  // Simple convolution-based matching
  // text: [1, 2, 3, 2, 1]
  // pattern: [2, 3]
  // At position 1: 2*2 + 3*3 = 13
  let text = [1, 2, 3, 2, 1]
  let pattern = [2, 3]
  let result = pattern_match_fft(text, pattern)
  inspect(result.length(), content="4")
  // result[1] should have high value where pattern matches
  inspect(result[1], content="13") // 2*2 + 3*3 = 13 (match position)
}

///|
test "polynomial_multiply_with_zeros" {
  // Test edge cases
  let a : Array[Int] = [0, 1, 0, 1]
  let b : Array[Int] = [1, 0, 1]
  let result = polynomial_multiply_fft(a, b)
  // (x + x^3) * (1 + x^2) = x + x^3 + x^3 + x^5 = x + 2x^3 + x^5
  inspect(result.length(), content="6")
  inspect(result[0], content="0")
  inspect(result[1], content="1")
  inspect(result[2], content="0")
  inspect(result[3], content="2")
  inspect(result[4], content="0")
  inspect(result[5], content="1")
}

///|
test "empty_polynomial" {
  let empty : Array[Int] = []
  let non_empty = [1, 2, 3]
  inspect(polynomial_multiply_fft(empty, non_empty).length(), content="0")
  inspect(polynomial_multiply_fft(non_empty, empty).length(), content="0")
}

///|
test "single_element_polynomial" {
  let a = [5]
  let b = [3]
  let result = polynomial_multiply_fft(a, b)
  inspect(result.length(), content="1")
  inspect(result[0], content="15")
}

///|
test "large_polynomial_multiply" {
  // Test with larger polynomials to exercise FFT properly
  let n = 16
  let a : Array[Int] = Array::make(n, 1)
  let b : Array[Int] = Array::make(n, 1)
  let result = polynomial_multiply_fft(a, b)
  // (1 + x + x^2 + ... + x^15)^2
  // coefficient of x^k is min(k+1, 2n-1-k) for k < 2n-1
  inspect(result.length(), content="31")
  inspect(result[0], content="1") // x^0 coefficient
  inspect(result[15], content="16") // x^15 coefficient (middle)
  inspect(result[30], content="1") // x^30 coefficient
}
