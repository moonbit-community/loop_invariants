// ============================================================================
// NTT - Number Theoretic Transform
// ============================================================================
//
// FFT over finite fields (modular arithmetic) for exact integer
// polynomial multiplication without floating-point errors.
//
// Uses a prime p = k * 2^n + 1 where 2^n >= required transform size.
// Common choice: p = 998244353 = 119 * 2^23 + 1, primitive root g = 3
//
// KEY INSIGHT: Replace e^(2πi/N) with g^((p-1)/N) mod p.
// All FFT properties hold in the finite field.
//
// INVARIANTS:
// 1. p is prime of form k * 2^n + 1
// 2. g is a primitive root mod p
// 3. All arithmetic is mod p
//
// TIME COMPLEXITY: O(n log n)
// SPACE COMPLEXITY: O(n)

///|
const NTT_MOD : Int64 = 998244353L

///|
const NTT_ROOT : Int64 = 3L

///|
/// Modular exponentiation using functional for loop
fn ntt_pow(base : Int64, exp : Int64, m : Int64) -> Int64 {
  for result = 1L, b = base % m, e = exp; e > 0L; {
    let new_result = if e % 2L == 1L { result * b % m } else { result }
    continue new_result, b * b % m, e / 2L
  } else {
    result
  }
}

///|
/// Modular inverse using Fermat's little theorem
fn ntt_inv(a : Int64, m : Int64) -> Int64 {
  ntt_pow(a, m - 2L, m)
}

///|
/// NTT in-place transform
fn ntt(a : Array[Int64], invert : Bool) -> Unit {
  let n = a.length()
  if n == 1 {
    return
  }

  // Bit-reversal permutation
  ntt_bit_reverse(a)

  // Iterative NTT
  for len = 2; len <= n; {
    let w = if invert {
      ntt_pow(NTT_ROOT, (NTT_MOD - 1L) - (NTT_MOD - 1L) / len.to_int64(), NTT_MOD)
    } else {
      ntt_pow(NTT_ROOT, (NTT_MOD - 1L) / len.to_int64(), NTT_MOD)
    }

    for i = 0; i < n; {
      for j = 0, wj = 1L; j < len / 2; {
        let u = a[i + j]
        let v = a[i + j + len / 2] * wj % NTT_MOD
        a[i + j] = (u + v) % NTT_MOD
        a[i + j + len / 2] = (u - v + NTT_MOD) % NTT_MOD
        continue j + 1, wj * w % NTT_MOD
      }
      continue i + len
    }
    continue len * 2
  }

  if invert {
    let n_inv = ntt_inv(n.to_int64(), NTT_MOD)
    for i = 0; i < n; i = i + 1 {
      a[i] = a[i] * n_inv % NTT_MOD
    }
  }
}

///|
/// Bit-reversal permutation for NTT
fn ntt_bit_reverse(a : Array[Int64]) -> Unit {
  let n = a.length()
  for i = 1, j = 0; i < n; {
    let new_j = for b = n / 2, jj = j; b > 0 && jj >= b; {
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
/// Polynomial multiplication using NTT
fn ntt_multiply(a : Array[Int64], b : Array[Int64]) -> Array[Int64] {
  let result_len = a.length() + b.length() - 1
  let n = ntt_next_power_of_2(result_len)

  let fa = Array::makei(n, fn(i) {
    if i < a.length() { a[i] % NTT_MOD } else { 0L }
  })

  let fb = Array::makei(n, fn(i) {
    if i < b.length() { b[i] % NTT_MOD } else { 0L }
  })

  ntt(fa, false)
  ntt(fb, false)

  for i = 0; i < n; i = i + 1 {
    fa[i] = fa[i] * fb[i] % NTT_MOD
  }

  ntt(fa, true)

  Array::makei(result_len, fn(i) { fa[i] })
}

///|
fn ntt_next_power_of_2(n : Int) -> Int {
  for p = 1; p < n; {
    continue p * 2
  } else {
    p
  }
}

///|
/// Convolution with modular arithmetic
fn ntt_convolve(a : Array[Int64], b : Array[Int64]) -> Array[Int64] {
  ntt_multiply(a, b)
}

///|
/// Square a polynomial (more efficient than multiply with self)
fn ntt_square(a : Array[Int64]) -> Array[Int64] {
  let result_len = 2 * a.length() - 1
  let n = ntt_next_power_of_2(result_len)

  let fa = Array::makei(n, fn(i) {
    if i < a.length() { a[i] % NTT_MOD } else { 0L }
  })

  ntt(fa, false)

  for i = 0; i < n; i = i + 1 {
    fa[i] = fa[i] * fa[i] % NTT_MOD
  }

  ntt(fa, true)

  Array::makei(result_len, fn(i) { fa[i] })
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "ntt multiply simple" {
  // (1 + 2x) * (3 + 4x) = 3 + 10x + 8x^2
  let a : Array[Int64] = [1L, 2L]
  let b : Array[Int64] = [3L, 4L]
  let result = ntt_multiply(a, b)

  inspect(result[0], content="3")
  inspect(result[1], content="10")
  inspect(result[2], content="8")
}

///|
test "ntt multiply larger" {
  // (1 + x + x^2) * (1 + x) = 1 + 2x + 2x^2 + x^3
  let a : Array[Int64] = [1L, 1L, 1L]
  let b : Array[Int64] = [1L, 1L]
  let result = ntt_multiply(a, b)

  inspect(result[0], content="1")
  inspect(result[1], content="2")
  inspect(result[2], content="2")
  inspect(result[3], content="1")
}

///|
test "ntt modular" {
  // Test that results are mod p
  let large = NTT_MOD - 1L
  let a : Array[Int64] = [large]
  let b : Array[Int64] = [large]
  let result = ntt_multiply(a, b)

  // (p-1)^2 mod p = 1
  inspect(result[0], content="1")
}

///|
test "ntt square" {
  // (1 + x)^2 = 1 + 2x + x^2
  let a : Array[Int64] = [1L, 1L]
  let result = ntt_square(a)

  inspect(result[0], content="1")
  inspect(result[1], content="2")
  inspect(result[2], content="1")
}

///|
test "ntt pow" {
  // 3^5 = 243
  inspect(ntt_pow(3L, 5L, NTT_MOD), content="243")
  // 2^10 = 1024
  inspect(ntt_pow(2L, 10L, NTT_MOD), content="1024")
}

///|
test "ntt inv" {
  // a * a^(-1) = 1 mod p
  let a = 12345L
  let a_inv = ntt_inv(a, NTT_MOD)
  inspect(a * a_inv % NTT_MOD, content="1")
}

///|
test "ntt identity" {
  // p * 1 = p
  let a : Array[Int64] = [1L, 2L, 3L]
  let b : Array[Int64] = [1L]
  let result = ntt_multiply(a, b)

  inspect(result.length(), content="3")
  inspect(result[0], content="1")
  inspect(result[1], content="2")
  inspect(result[2], content="3")
}

///|
test "ntt convolve" {
  let a : Array[Int64] = [1L, 2L, 3L]
  let b : Array[Int64] = [1L, 1L]
  let result = ntt_convolve(a, b)

  inspect(result[0], content="1")
  inspect(result[1], content="3")
  inspect(result[2], content="5")
  inspect(result[3], content="3")
}
