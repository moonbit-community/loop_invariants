# Pollard's Rho Factorization (with Miller–Rabin)

This package factors 64‑bit integers quickly using:

- **Miller–Rabin** for primality,
- **Pollard's Rho** for non‑trivial factors.

It is practical for numbers up to about 10^18.

---

## 1. The problem

Given a number `n`, find its prime factors.

Brute force trial division is too slow:

```
trial division up to √n  ->  O(√n)
```

For `n = 10^18`, √n is 10^9 checks — too big.

---

## 2. Pollard's Rho in one sentence

**Generate a pseudo‑random sequence modulo n, detect a cycle, and use gcd to
extract a non‑trivial factor.**

The magic is that cycles appear sooner **modulo a factor** than modulo n.

---

## 3. The sequence

We iterate:

```
f(x) = x² + c  (mod n)
```

Choose a random start `x0` and random constant `c`.

Example with n = 91 (= 7 × 13), c = 1, x0 = 2:

```
x0 = 2
x1 = 2² + 1 = 5
x2 = 5² + 1 = 26
x3 = 26² + 1 = 677 = 586 (mod 91)
x4 = 586² + 1 = 37 (mod 91)
...
```

The sequence eventually cycles.

---

## 4. Why a cycle reveals a factor

Suppose n = p × q.

If two values are equal modulo **p**, then their difference is divisible by p:

```
x_i ≡ x_j (mod p)  =>  p | (x_i - x_j)
```

So:

```
gcd(|x_i - x_j|, n)  returns p (or q).
```

We do not know p, but the gcd reveals it!

This is a classic **birthday paradox** effect: with about √p steps, collisions
mod p become likely, so expected time is roughly O(n^(1/4)).

---

## 5. Cycle detection (tortoise & hare)

We do not store the whole sequence. We use Floyd’s cycle detection:

```
x = f(x)          // tortoise, 1 step
y = f(f(y))       // hare, 2 steps
d = gcd(|x - y|, n)
```

Diagram:

```
○ → ○ → ○ → ○ → ○ → ○
^         ^
x         y (moves faster)
```

When x and y meet modulo a factor, gcd gives that factor.

---

## 6. A full tiny walkthrough

Factor n = 91:

```
f(x) = x² + 1 (mod 91), x = y = 2

Iteration 1:
  x = 5
  y = f(f(2)) = f(5) = 26
  gcd(|5 - 26|, 91) = gcd(21, 91) = 7
```

We found factor 7, and 91 = 7 × 13.

---

## 7. Miller–Rabin (fast primality)

Before factoring, we check if n is already prime.

For 64‑bit integers, Miller–Rabin can be made **deterministic** by using a
fixed list of bases.

So:

```
if is_prime(n) -> n is prime, stop
else -> use Pollard's Rho
```

---

## 8. Public API

From `pkg.generated.mbti`:

- `is_prime(n : Int64) -> Bool`
- `factorize(n : Int64) -> Array[Int64]`  (list of prime factors)
- `factorize_with_counts(n : Int64) -> Array[(Int64, Int)]`

---

## 9. Quick start examples

```mbt check
///|
test "pollard rho quick start" {
  let factors = @pollard_rho.factorize_with_counts(8051L)
  inspect(factors, content="[(83, 1), (97, 1)]")
}
```

```mbt check
///|
test "pollard rho primes" {
  inspect(@pollard_rho.is_prime(2L), content="true")
  inspect(@pollard_rho.is_prime(97L), content="true")
  inspect(@pollard_rho.is_prime(221L), content="false")
}
```

```mbt check
///|
test "pollard rho large semiprime" {
  let n = 1000003L * 1000033L
  let factors = @pollard_rho.factorize_with_counts(n)
  inspect(factors, content="[(1000003, 1), (1000033, 1)]")
}
```

---

## 10. Example: repeated factors

```
360 = 2^3 × 3^2 × 5
```

```mbt check
///|
test "pollard rho repeated factors" {
  let factors = @pollard_rho.factorize_with_counts(360L)
  inspect(factors, content="[(2, 3), (3, 2), (5, 1)]")
}
```

---

## 11. Algorithm summary (pseudocode)

```
factorize(n):
  if n <= 1: return []
  if is_prime(n): return [n]

  d = pollard_rho(n)
  return factorize(d) + factorize(n / d)

pollard_rho(n):
  loop:
    choose random x, c
    x = y = x
    while d == 1:
      x = f(x)
      y = f(f(y))
      d = gcd(|x - y|, n)
    if d != n: return d
    // else restart with different parameters
```

---

## 12. Diagram: where gcd appears

```
Sequence mod n:
  x0 → x1 → x2 → x3 → ...

Sequence mod p (hidden factor):
  x0 → x1 → x2 → x1 → x2 → ... (cycle)

When x_i == x_j (mod p),
gcd(|x_i - x_j|, n) reveals p.
```

---

## 13. Complexity (rule of thumb)

| Step | Expected Time |
|------|----------------|
| Miller–Rabin | O(log^3 n) |
| One factor | O(n^(1/4)) |
| Full factorization | O(n^(1/4) × k) |

It is extremely fast for 64‑bit integers in practice.

---

## 14. Common applications

1. **Cryptography**: check RSA moduli when factors are small.
2. **Number theory**: compute Euler’s totient φ(n) or divisors.
3. **Competitive programming**: factor up to 10^18 quickly.

---

## 15. Tips and pitfalls

1. If gcd returns n, restart with a new constant c.
2. Always test primality before recursing.
3. Use 128‑bit intermediates for safe multiplication (implementation detail).
4. The algorithm is randomized — but for 64‑bit numbers it is extremely reliable.

---

## 16. Summary

- Miller–Rabin tells you if n is prime.
- Pollard’s Rho quickly finds a non‑trivial factor.
- The combination is the standard tool for 64‑bit factorization.
