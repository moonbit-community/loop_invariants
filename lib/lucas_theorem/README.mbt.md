# Lucas Theorem (binomial mod prime)

## 1. Problem statement

We want to compute the binomial coefficient

```
C(n, k) mod p
```

for **very large** `n` and `k`, where `p` is a **prime**.

Direct factorial formulas break once `n >= p`, because `n!` contains `p` as a
factor and becomes 0 modulo `p`. Lucas' theorem works around this by reducing
the problem to many tiny binomial coefficients.

## 2. Core idea in one line

Write `n` and `k` in base `p`. Then multiply small digit-wise binomials:

```
C(n, k) mod p = product over digits i of C(n_i, k_i) mod p
```

If any digit has `k_i > n_i`, the answer is 0.

## 3. Why direct factorial fails (quick warning)

Suppose `p = 7` and `n = 100`.

```
100! mod 7 = 0
```

So the standard formula

```
C(n, k) = n! / (k! * (n-k)!)
```

is not usable once `n >= p`, because division in modular arithmetic requires
inverses of numbers that are already 0 modulo `p`.

Lucas avoids this by never asking for factorials larger than `p - 1`.

## 4. Base-p digit decomposition (visual)

Think of `n` and `k` written in base `p` as stacks of digits:

```
Example: p = 5

n = 6  = 1 * 5 + 1
k = 1  = 0 * 5 + 1

Place values:     5^1   5^0
n digits:          1     1
k digits:          0     1
```

Lucas says:

```
C(6, 1) mod 5 = C(1, 0) * C(1, 1) mod 5 = 1
```

Each digit pair is small (0..p-1), so it is easy to compute.

## 5. The theorem (formal statement)

Let `p` be prime, and write

```
n = n_0 + n_1 * p + n_2 * p^2 + ...
k = k_0 + k_1 * p + k_2 * p^2 + ...
```

Then

```
C(n, k) mod p = product_i C(n_i, k_i) mod p
```

and if any `k_i > n_i`, the product is 0.

## 6. Step-by-step example (p = 3)

Compute `C(12, 5) mod 3`.

Base-3 digits:

```
12 = 1 * 9 + 1 * 3 + 0  => digits (1, 1, 0)
 5 = 0 * 9 + 1 * 3 + 2  => digits (0, 1, 2)

Digits by place:      3^2  3^1  3^0
n digits:              1    1    0
k digits:              0    1    2
```

Lucas product:

```
C(12, 5) mod 3 = C(1, 0) * C(1, 1) * C(0, 2) mod 3
               = 1 * 1 * 0
               = 0
```

Since a digit has `k_i > n_i`, the result must be 0.

## 7. Another example (p = 7)

Compute `C(10, 3) mod 7`.

Base-7 digits:

```
10 = 1 * 7 + 3  => digits (1, 3)
 3 = 0 * 7 + 3  => digits (0, 3)

Digits by place:      7^1  7^0
n digits:              1    3
k digits:              0    3
```

Lucas product:

```
C(10, 3) mod 7 = C(1, 0) * C(3, 3) mod 7
               = 1 * 1
               = 1
```

## 8. The special case p = 2 (parity rule)

When `p = 2`, Lucas reduces to a clean bit rule:

```
C(n, k) is odd  <=>  every 1-bit of k is also a 1-bit of n
```

This is the same as: `(k & ~n) == 0`.

Example:

```
n = 13 (1101)
k = 5  (0101)

All 1-bits of k appear in n => C(13,5) is odd => mod 2 = 1

n = 13 (1101)
k = 6  (0110)

k has a 1 in the 2-bit where n has 0 => even => mod 2 = 0
```

## 9. How we compute the small C(n_i, k_i)

In this implementation we precompute factorials and inverse factorials
modulo `p`:

```
C(n, k) = fact[n] * inv_fact[k] * inv_fact[n-k] mod p
```

Because `p` is prime, Fermat's little theorem gives modular inverses:

```
a^(p-2) mod p = a^{-1} mod p
```

So we compute:

- `fact[0..p-1]`
- `inv_fact[p-1] = fact[p-1]^(p-2) mod p`
- fill downward with `inv_fact[i] = inv_fact[i+1] * (i+1) mod p`

This costs O(p) time and space, plus a single `pow_mod` in O(log p).

## 10. Algorithm (high level)

```
if k > n: return 0
if p <= 1: return 0

precompute fact[0..p-1] and inv_fact[0..p-1]
result = 1

while k > 0:
  n_i = n mod p
  k_i = k mod p

  if k_i > n_i: return 0
  result = result * C(n_i, k_i) mod p

  n = n / p
  k = k / p

return result
```

## 11. Digit-by-digit multiplication (diagram)

```
Example: n = 10, k = 3, p = 7

Step | n_i | k_i | C(n_i, k_i) | product
-----+-----+-----+-------------+--------
  0  |  3  |  3  |      1      |   1
  1  |  1  |  0  |      1      |   1

Final answer = 1
```

## 12. Example usage (runnable)

```mbt check
///|
test "lucas theorem basics" {
  inspect(@lucas_theorem.nck_mod_prime_lucas(10L, 3L, 7L), content="1")
  inspect(@lucas_theorem.nck_mod_prime_lucas(12L, 5L, 3L), content="0")
  inspect(@lucas_theorem.nck_mod_prime_lucas(8L, 3L, 3L), content="2")
}
```

```mbt check
///|
test "lucas parity rule" {
  inspect(@lucas_theorem.nck_mod_prime_lucas(13L, 5L, 2L), content="1")
  inspect(@lucas_theorem.nck_mod_prime_lucas(13L, 6L, 2L), content="0")
}
```

```mbt check
///|
test "lucas base-5 example" {
  inspect(@lucas_theorem.nck_mod_prime_lucas(7L, 2L, 5L), content="1")
}
```

```mbt check
///|
test "lucas larger digits" {
  inspect(@lucas_theorem.nck_mod_prime_lucas(100L, 50L, 7L), content="4")
}
```

```mbt check
///|
test "lucas edge cases" {
  inspect(@lucas_theorem.nck_mod_prime_lucas(5L, 9L, 7L), content="0")
  inspect(@lucas_theorem.nck_mod_prime_lucas(5L, 2L, 1L), content="0")
}
```

## 13. Complexity

For a single call:

```
Precompute factorials: O(p)
Compute Lucas digits: O(log_p n)
Space: O(p)
```

If you will call this many times for the same `p`, consider caching the
factorials and inverse factorials. This implementation recomputes them on
each call for simplicity.

## 14. Why the theorem is true (short intuition)

The identity

```
(1 + x)^p mod p = 1 + x^p
```

is the key. When you expand `(1 + x)^n` and rewrite `n` in base `p`, every digit
contributes a factor `(1 + x^{p^i})^{n_i}`. Multiplying the coefficients of
`x^k` across these factors produces exactly the product over digits.

## 15. Common pitfalls

- `p` must be prime. Lucas does not work for composite `p`.
- `p` must fit in `Int` because we allocate arrays of size `p`.
- For `n < p`, Lucas still works, but direct factorial is also fine.
- If `k > n`, the answer is always 0.

## 16. Generalizations

- **Prime powers**: there is a generalized Lucas theorem for `p^q`.
- **Composite modulus**: compute per prime power and combine with CRT.
- **Kummer's theorem**: the number of carries in base `p` when adding
  `k` and `n-k` equals the exponent of `p` dividing `C(n, k)`.

These are excellent follow-up topics once Lucas is mastered.
