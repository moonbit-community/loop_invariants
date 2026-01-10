// ============================================================================
// FFT - Fast Fourier Transform
// ============================================================================
//
// Computes the Discrete Fourier Transform in O(n log n) time.
// Essential for fast polynomial multiplication.
//
// DFT: X[k] = Σ x[n] * e^(-2πi*k*n/N) for k = 0..N-1
//
// KEY INSIGHT (Cooley-Tukey): Split into even and odd indices.
// DFT(x) = DFT(x_even) + w * DFT(x_odd) where w = e^(-2πi/N)
//
// INVARIANTS:
// 1. Array length must be power of 2
// 2. w^N = 1 (primitive N-th root of unity)
// 3. Inverse FFT uses w^(-1) = conjugate(w) and divides by N
//
// TIME COMPLEXITY: O(n log n)
// SPACE COMPLEXITY: O(n)

///|
const FFT_PI : Double = 3.14159265358979323846

///|
priv struct Complex {
  re : Double
  im : Double
} derive(Eq)

///|
fn Complex::new(re : Double, im : Double) -> Complex {
  { re, im }
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
fn Complex::scale(self : Complex, s : Double) -> Complex {
  { re: self.re * s, im: self.im * s }
}

///|
fn Complex::conj(self : Complex) -> Complex {
  { re: self.re, im: -self.im }
}

///|
fn Complex::from_polar(r : Double, theta : Double) -> Complex {
  { re: r * @math.cos(theta), im: r * @math.sin(theta) }
}

///|
/// Compute FFT in-place using iterative Cooley-Tukey
fn fft(a : Array[Complex], invert : Bool) -> Unit {
  let n = a.length()
  if n == 1 {
    return
  }

  // Bit-reversal permutation
  bit_reverse_permute(a)

  // Iterative FFT
  for len = 2; len <= n; {
    let angle = 2.0 * FFT_PI / len.to_double() * (if invert { -1.0 } else { 1.0 })
    let wlen = Complex::from_polar(1.0, angle)

    for i = 0; i < n; {
      let w = for j = 0, w = Complex::new(1.0, 0.0); j < len / 2; {
        let u = a[i + j]
        let v = a[i + j + len / 2].mul(w)
        a[i + j] = u.add(v)
        a[i + j + len / 2] = u.sub(v)
        continue j + 1, w.mul(wlen)
      } else {
        w
      }
      let _ = w
      continue i + len
    }
    continue len * 2
  }

  if invert {
    let n_inv = 1.0 / n.to_double()
    for i = 0; i < n; i = i + 1 {
      a[i] = a[i].scale(n_inv)
    }
  }
}

///|
/// Bit-reversal permutation
fn bit_reverse_permute(a : Array[Complex]) -> Unit {
  let n = a.length()
  for i = 1, j = 0; i < n; {
    let bit = n / 2
    let new_j = for b = bit, jj = j; b > 0 && jj >= b; {
      continue b / 2, jj - b
    } else {
      jj + b
    }

    if i < new_j {
      let tmp = a[i]
      a[i] = a[new_j]
      a[new_j] = tmp
    }
    continue i + 1, new_j
  }
}

///|
/// Multiply two polynomials using FFT
fn poly_multiply(a : Array[Int], b : Array[Int]) -> Array[Int] {
  let result_len = a.length() + b.length() - 1
  let n = next_power_of_2(result_len)

  // Convert to complex
  let fa = Array::makei(n, fn(i) {
    if i < a.length() {
      Complex::new(a[i].to_double(), 0.0)
    } else {
      Complex::new(0.0, 0.0)
    }
  })

  let fb = Array::makei(n, fn(i) {
    if i < b.length() {
      Complex::new(b[i].to_double(), 0.0)
    } else {
      Complex::new(0.0, 0.0)
    }
  })

  // Forward FFT
  fft(fa, false)
  fft(fb, false)

  // Pointwise multiply
  for i = 0; i < n; i = i + 1 {
    fa[i] = fa[i].mul(fb[i])
  }

  // Inverse FFT
  fft(fa, true)

  // Extract result
  Array::makei(result_len, fn(i) { (fa[i].re + 0.5).to_int() })
}

///|
fn next_power_of_2(n : Int) -> Int {
  for p = 1; p < n; {
    continue p * 2
  } else {
    p
  }
}

///|
/// Convolution of two arrays
fn convolve(a : Array[Double], b : Array[Double]) -> Array[Double] {
  let result_len = a.length() + b.length() - 1
  let n = next_power_of_2(result_len)

  let fa = Array::makei(n, fn(i) {
    if i < a.length() { Complex::new(a[i], 0.0) } else { Complex::new(0.0, 0.0) }
  })

  let fb = Array::makei(n, fn(i) {
    if i < b.length() { Complex::new(b[i], 0.0) } else { Complex::new(0.0, 0.0) }
  })

  fft(fa, false)
  fft(fb, false)

  for i = 0; i < n; i = i + 1 {
    fa[i] = fa[i].mul(fb[i])
  }

  fft(fa, true)

  Array::makei(result_len, fn(i) { fa[i].re })
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "poly multiply simple" {
  // (1 + 2x) * (3 + 4x) = 3 + 10x + 8x^2
  let a : Array[Int] = [1, 2]
  let b : Array[Int] = [3, 4]
  let result = poly_multiply(a, b)

  inspect(result[0], content="3")
  inspect(result[1], content="10")
  inspect(result[2], content="8")
}

///|
test "poly multiply larger" {
  // (1 + x + x^2) * (1 + x) = 1 + 2x + 2x^2 + x^3
  let a : Array[Int] = [1, 1, 1]
  let b : Array[Int] = [1, 1]
  let result = poly_multiply(a, b)

  inspect(result[0], content="1")
  inspect(result[1], content="2")
  inspect(result[2], content="2")
  inspect(result[3], content="1")
}

///|
test "poly multiply by constant" {
  // 3 * (2 + 5x) = 6 + 15x
  let a : Array[Int] = [3]
  let b : Array[Int] = [2, 5]
  let result = poly_multiply(a, b)

  inspect(result[0], content="6")
  inspect(result[1], content="15")
}

///|
test "complex operations" {
  let a = Complex::new(3.0, 4.0)
  let b = Complex::new(1.0, 2.0)

  let sum = a.add(b)
  inspect((sum.re - 4.0).abs() < 0.001, content="true")

  let prod = a.mul(b)
  // (3+4i)(1+2i) = 3 + 6i + 4i + 8i^2 = 3 - 8 + 10i = -5 + 10i
  inspect((prod.re - (-5.0)).abs() < 0.001, content="true")
  inspect((prod.im - 10.0).abs() < 0.001, content="true")
}

///|
test "next power of 2" {
  inspect(next_power_of_2(1), content="1")
  inspect(next_power_of_2(3), content="4")
  inspect(next_power_of_2(5), content="8")
  inspect(next_power_of_2(8), content="8")
}

///|
test "convolve" {
  let a : Array[Double] = [1.0, 2.0, 3.0]
  let b : Array[Double] = [1.0, 1.0]
  let result = convolve(a, b)

  inspect((result[0] - 1.0).abs() < 0.01, content="true")
  inspect((result[1] - 3.0).abs() < 0.01, content="true")
  inspect((result[2] - 5.0).abs() < 0.01, content="true")
  inspect((result[3] - 3.0).abs() < 0.01, content="true")
}

///|
test "poly multiply identity" {
  // p * 1 = p
  let a : Array[Int] = [1, 2, 3]
  let b : Array[Int] = [1]
  let result = poly_multiply(a, b)

  inspect(result.length(), content="3")
  inspect(result[0], content="1")
  inspect(result[1], content="2")
  inspect(result[2], content="3")
}
