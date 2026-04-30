# Math Utilities (number theory, matrices, FFT)

## 1. What is in this package?

This directory is a **grab bag of math-heavy algorithms** with rigorous loop
invariants. It focuses on **reasoning** as much as on speed. The code includes:

- Number theory: primality testing, CRT, binary GCD, modular inverse
- Bit tricks: trailing zeros and integer log2
- Perfect power detection
- Matrix exponentiation: Fibonacci, Tribonacci, path counting
- Matrix chain order and Strassen insight
- FFT / NTT for polynomial multiplication and pattern matching

Everything here is written as **examples with proofs**, so the README is long
and educational by design.
Examples are marked `mbt nocheck` because this package does not expose a public
API; the same scenarios are exercised in the package's test blocks.

## 2. Number theory core concepts

### 2.1 GCD (Euclidean algorithm)

The greatest common divisor is the largest integer dividing both numbers.

```
gcd(a, b) = gcd(b, a mod b)

Example:
  48 = 18 * 2 + 12
  18 = 12 * 1 +  6
  12 =  6 * 2 +  0
  => gcd(48, 18) = 6
```

This package uses **binary GCD (Stein's algorithm)**, which replaces division
with bit shifts and subtraction. It is often faster on low-level hardware.

```mbt nocheck
///|
test "binary_gcd examples" {
  inspect(binary_gcd(48, 18), content="6")
  inspect(binary_gcd(100, 35), content="5")
  inspect(binary_gcd(17, 13), content="1")
}
```

### 2.2 Extended GCD (Bezout coefficients)

Extended GCD gives `x` and `y` such that:

```
a*x + b*y = gcd(a, b)
```

Example:

```
48x + 18y = 6
One solution: x = -1, y = 3
Check: -48 + 54 = 6
```

```mbt nocheck
///|
test "extended_gcd_64 example" {
  let (g, x, y) = extended_gcd_64(48L, 18L)
  inspect(g, content="6")
  inspect(48L * x + 18L * y, content="6")
}
```

### 2.3 Modular inverse

A modular inverse of `a` modulo `m` is a number `x` such that:

```
a * x mod m = 1
```

It exists **only if** `gcd(a, m) = 1`.

```mbt nocheck
///|
test "mod_inverse examples" {
  inspect(mod_inverse(3L, 10L), content="Some(7)") // 3 * 7 = 21 = 1 mod 10
  inspect(mod_inverse(2L, 4L), content="None")
}
```

### 2.4 Modular exponentiation

Binary exponentiation computes `a^n mod m` in O(log n).

```
Example: 3^10 mod 7
3^2 = 2, 3^4 = 4, 3^8 = 2
3^10 = 3^8 * 3^2 = 2 * 2 = 4 mod 7
```

```mbt nocheck
///|
test "mod_exp example" {
  inspect(mod_exp(3L, 10L, 7L), content="4")
}
```

### 2.5 Miller-Rabin primality test

Miller-Rabin is a fast primality test. For 32-bit integers, a fixed set of
bases makes it deterministic.

Key step: write `n - 1 = d * 2^r` where `d` is odd.

```
Example: n = 561 (Carmichael number)
560 = 35 * 2^4
Test bases show it is composite
```

```mbt nocheck
///|
test "is_prime_32 examples" {
  inspect(is_prime_32(2), content="true")
  inspect(is_prime_32(17), content="true")
  inspect(is_prime_32(561), content="false")
}
```

### 2.6 Chinese Remainder Theorem (CRT)

CRT solves systems of congruences when moduli are coprime.

```
Solve:
  x = 2 (mod 3)
  x = 3 (mod 5)

Solution:
  x = 8 (mod 15)
```

Diagram:

```
mod 3: 0 1 2 0 1 2 0 1 2 0 1 2 0 1 2
mod 5: 0 1 2 3 4 0 1 2 3 4 0 1 2 3 4
                ^
                x = 8 is the first time both match (2, 3)
```

```mbt nocheck
///|
test "chinese_remainder example" {
  let congruences : Array[(Int64, Int64)] = [(2L, 3L), (3L, 5L)]
  let (x, m) = chinese_remainder(congruences[:])
  inspect(m, content="15")
  inspect(x, content="8")
}
```

## 3. Bit tricks

### 3.1 Count trailing zeros (ctz)

`ctz(n)` is the position of the lowest set bit in `n`.

```
Binary:  40 = 0b101000
Lowest set bit is at position 3
ctz(40) = 3
```

The implementation uses a **de Bruijn sequence** to map powers of two to
indices in O(1).

```mbt nocheck
///|
test "ctz examples" {
  inspect(count_trailing_zeros(1), content="0")
  inspect(count_trailing_zeros(8), content="3")
  inspect(count_trailing_zeros(40), content="3")
}
```

### 3.2 Integer log2

`ilog2(n)` returns `floor(log2(n))` for `n > 0`.

```
ilog2(1) = 0
ilog2(2) = 1
ilog2(3) = 1
ilog2(8) = 3
```

```mbt nocheck
///|
test "ilog2 examples" {
  inspect(ilog2(1), content="0")
  inspect(ilog2(3), content="1")
  inspect(ilog2(8), content="3")
  inspect(ilog2(1024), content="10")
}
```

## 4. Perfect power detection

A number is a **perfect power** if `n = a^b` for integers `a > 1` and `b > 1`.

Examples:

- 8 = 2^3
- 27 = 3^3
- 81 = 9^2

```mbt nocheck
///|
test "is_perfect_power examples" {
  inspect(is_perfect_power(8), content="true")
  inspect(is_perfect_power(27), content="true")
  inspect(is_perfect_power(10), content="false")
}
```

## 5. Matrix exponentiation (fast recurrences)

### 5.1 Fibonacci via 2x2 matrices

The Fibonacci recurrence can be encoded as:

```
| F(n+1) |   | 1 1 |^n   | 1 |
| F(n)   | = | 1 0 |   * | 0 |
```

So a single matrix power gives `F(n)` in O(log n).

```mbt nocheck
///|
test "fibonacci_matrix examples" {
  let m = 1000000007L
  inspect(fibonacci_matrix(10L, m), content="55")
  inspect(fibonacci_matrix(20L, m), content="6765")
}
```

### 5.2 Tribonacci via 3x3 matrices

Tribonacci: `T(n) = T(n-1) + T(n-2) + T(n-3)` with `T(0)=0, T(1)=1, T(2)=1`.

```
| T(n+2) |   | 1 1 1 |^n   | 1 |
| T(n+1) | = | 1 0 0 |   * | 1 |
| T(n)   |   | 0 1 0 |     | 0 |
```

```mbt nocheck
///|
test "tribonacci_matrix examples" {
  let m = 1000000007L
  inspect(tribonacci_matrix(5L, m), content="7")
  inspect(tribonacci_matrix(7L, m), content="24")
}
```

### 5.3 Counting paths in a graph

If `A` is the adjacency matrix of a graph, then:

```
(A^k)[i,j] = number of paths of length k from i to j
```

Example graph (triangle):

```
0 -- 1
 \  /
  2
```

```mbt nocheck
///|
test "count_paths triangle" {
  let adj : Array[Int64] = [0L, 1L, 1L, 1L, 0L, 1L, 1L, 1L, 0L]
  let paths2 = count_paths(adj, 3, 2L, 1000000007L)
  inspect(paths2[0 * 3 + 0], content="2") // 0->1->0 and 0->2->0
}
```

### 5.4 Matrix chain order (DP)

Matrix multiplication is associative, but the **parenthesization** changes the
cost drastically.

```
A: 10x30, B: 30x5, C: 5x60
(A*B)*C costs 10*30*5 + 10*5*60 = 4500
A*(B*C) costs 30*5*60 + 10*30*60 = 27000
```

```mbt nocheck
///|
test "matrix_chain_order examples" {
  let dims : Array[Int] = [10, 30, 5, 60]
  inspect(matrix_chain_order(dims[:]), content="4500")
}
```

### 5.5 Strassen's 2x2 insight

Strassen showed that 2x2 multiplication can be done with **7 multiplications**
(plus additions) instead of 8. This reduces the asymptotic complexity.

```mbt nocheck
///|
test "strassen_2x2 example" {
  let (c11, c12, c21, c22) = strassen_2x2(1, 2, 3, 4, 5, 6, 7, 8)
  inspect([c11, c12, c21, c22], content="[19, 22, 43, 50]")
}
```

### 5.6 Fast doubling for Fibonacci

Fast doubling computes `(F(n), F(n+1))` using two formulas:

```
F(2k)   = F(k) * (2*F(k+1) - F(k))
F(2k+1) = F(k)^2 + F(k+1)^2
```

```mbt nocheck
///|
test "fibonacci_fast_doubling examples" {
  let m = 1000000007L
  inspect(fibonacci_fast_doubling(10L, m).0, content="55")
  inspect(fibonacci_fast_doubling(50L, m).0, content="586268941")
}
```

### 5.7 Lucas numbers

Lucas numbers follow the same recurrence as Fibonacci but with different seeds:

```
L(0) = 2, L(1) = 1
```

```mbt nocheck
///|
test "lucas_matrix examples" {
  let m = 1000000007L
  inspect(lucas_matrix(5L, m), content="11")
  inspect(lucas_matrix(6L, m), content="18")
}
```

## 6. FFT and NTT (polynomial multiplication)

### 6.1 Convolution idea

Polynomial multiplication is convolution of coefficients:

```
(c = a * b)

c[k] = sum_{i=0..k} a[i] * b[k-i]
```

Naive is O(n^2). FFT reduces this to O(n log n) by evaluating polynomials at
roots of unity, multiplying pointwise, and transforming back.

### 6.2 Butterfly diagram (one stage)

```
Inputs: x, y

x' = x + w * y
 y' = x - w * y

This "butterfly" is repeated in log2(n) stages.
```

### 6.3 FFT example (integer polynomials)

```mbt nocheck
///|
test "polynomial_multiply_fft example" {
  let a = [1, 2] // 1 + 2x
  let b = [3, 4] // 3 + 4x
  let c = polynomial_multiply_fft(a, b)
  inspect(c, content="[3, 10, 8]") // 3 + 10x + 8x^2
}
```

### 6.4 NTT example (modular polynomials)

NTT is FFT over finite fields (mod prime). It avoids floating-point error.

```mbt nocheck
///|
test "polynomial_multiply_ntt example" {
  let a : Array[Int64] = [1L, 1L, 1L]
  let b : Array[Int64] = [1L, 1L]
  let c = polynomial_multiply_ntt(a, b)
  inspect(c, content="[1, 2, 2, 1]")
}
```

### 6.5 Polynomial generating function example

Coin change via polynomial multiplication:

- Coins: 1, 2, 5
- Ways to make 10 is the coefficient of x^10

```mbt nocheck
///|
test "count_change_polynomial example" {
  let coins = [1, 2, 5]
  let ways = count_change_polynomial(coins, 10)
  inspect(ways[10], content="10")
}
```

### 6.6 Pattern matching via convolution

Pattern matching can be reduced to convolution:

```
text:    [1, 2, 3, 2, 1]
pattern: [2, 3]
match at position 1 gives dot product 2*2 + 3*3 = 13
```

```mbt nocheck
///|
test "pattern_match_fft example" {
  let text = [1, 2, 3, 2, 1]
  let pattern = [2, 3]
  let result = pattern_match_fft(text, pattern)
  inspect(result[1], content="13")
}
```

## 7. Complexity summary

```
Number theory:
  binary_gcd             O(log n)
  mod_exp               O(log n)
  is_prime_32            O(log^3 n) per base (small constant)
  chinese_remainder      O(k log M)

Matrix algorithms:
  matrix_pow_2x2         O(log n)
  fibonacci_fast_doubling O(log n)
  matrix_chain_order     O(n^3)

FFT / NTT:
  polynomial_multiply    O(n log n)
```

## 8. When to use what

- Need primality? use `is_prime_32` for 32-bit inputs.
- Need modular inverse? `mod_inverse` uses extended GCD.
- Need fast recurrence values? use matrix exponentiation or fast doubling.
- Need polynomial multiplication or convolution? use FFT or NTT.

This package is meant as a **teaching library**: each example is written with
careful reasoning so you can learn both the algorithm and the proof mindset.
