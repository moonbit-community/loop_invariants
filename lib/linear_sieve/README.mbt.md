# Linear Sieve (Euler Sieve)

## What It Solves

The **linear sieve** computes primes and multiplicative functions in **O(n)** by
ensuring **each composite is marked exactly once** — by its smallest prime
factor (SPF).

It produces, for all `1..n`:

- `primes` list
- `spf` (smallest prime factor)
- Euler's totient `phi`
- Möbius `mu`

## Why It Is Linear

Eratosthenes marks composites multiple times:

```
12 is marked by 2 and 3
30 is marked by 2, 3, and 5
```

Linear sieve marks each composite only once, by its smallest prime factor:

```
12 = 2 * 6   => only marked when i=6, p=2
30 = 2 * 15  => only marked when i=15, p=2
```

So total work is proportional to `n`.

## The Key Rule

For each `i`, multiply by primes `p` **in order** until `p > spf[i]`:

```
if p > spf[i] -> stop
```

Reason: if `p > spf[i]`, then the smallest prime factor of `i*p` is still
`spf[i]`, so `i*p` will be handled when that smaller prime is used later.

## Walkthrough (n = 10)

```
Start:
primes = []
spf[1] = 0 (unused)
phi[1] = 1, mu[1] = 1

i = 2 (spf[2] = 0 => prime)
  primes = [2]
  spf[2] = 2, phi[2] = 1, mu[2] = -1
  mark 2*2 = 4, spf[4] = 2

i = 3 (prime)
  primes = [2, 3]
  spf[3] = 3, phi[3] = 2, mu[3] = -1
  mark 3*2 = 6, spf[6] = 2
  mark 3*3 = 9, spf[9] = 3 (stop: p == spf[3])

i = 4 (composite, spf[4]=2)
  mark 4*2 = 8, spf[8] = 2 (stop: p == spf[4])

i = 5 (prime)
  primes = [2,3,5]
  mark 5*2 = 10, spf[10] = 2

Done.
```

## Visual: “Marked Once” Property

```
Composite 12:
  12 = 2 * 6   (p=2, i=6)  -> marked here
  12 = 3 * 4   (p=3, i=4)  -> skipped because p > spf[4]=2

Composite 30:
  30 = 2 * 15  (p=2, i=15) -> marked here
  30 = 3 * 10  (p=3, i=10) -> skipped because p > spf[10]=2
  30 = 5 * 6   (p=5, i=6)  -> skipped because p > spf[6]=2
```

Each composite gets exactly one “mark” from its smallest prime factor.

## Result Table (n = 10)

```
 n | spf | phi | mu
---+-----+-----+----
 1 |  0  |  1  |  1
 2 |  2  |  1  | -1
 3 |  3  |  2  | -1
 4 |  2  |  2  |  0
 5 |  5  |  4  | -1
 6 |  2  |  2  |  1
 7 |  7  |  6  | -1
 8 |  2  |  4  |  0
 9 |  3  |  6  |  0
10 |  2  |  4  |  1
```

## Euler’s Totient φ(n)

```
φ(n) = count of numbers 1..n that are coprime with n

φ(1) = 1
φ(6) = 2  (1 and 5)
φ(10) = 4 (1,3,7,9)
φ(p) = p-1 for prime p
```

The sieve updates:

```
if p divides i:   φ(i*p) = φ(i) * p
else:             φ(i*p) = φ(i) * (p - 1)
```

## Möbius μ(n)

```
μ(n) =  1   if n is squarefree with an even number of primes
      = -1  if n is squarefree with an odd number of primes
      =  0  if n has any squared prime factor
```

Examples:

```
μ(1) = 1
μ(2) = -1
μ(6) = 1
μ(4) = 0  (2^2 divides 4)
μ(30) = -1 (three primes)
```

Sieve update:

```
if p divides i:   μ(i*p) = 0
else:             μ(i*p) = -μ(i)
```

## Factorization Using SPF

Once you have `spf`, you can factorize in O(log n):

```
84:
  spf = 2 -> 84/2=42 -> 42/2=21   => 2^2
  spf = 3 -> 21/3=7              => 3^1
  spf = 7 -> 7/7=1               => 7^1

Result: [(2,2), (3,1), (7,1)]
```

## Example Usage

```mbt check
///|
test "linear sieve quick start" {
  let sieve = @linear_sieve.LinearSieve::new(10)
  inspect(sieve.primes, content="[2, 3, 5, 7]")
  inspect(sieve.spf[10], content="2")
  inspect(sieve.phi[10], content="4")
  inspect(sieve.mu[10], content="1")
  inspect(sieve.mu[4], content="0")
  inspect(sieve.is_prime(7), content="true")
  inspect(sieve.is_prime(9), content="false")
}
```

```mbt check
///|
test "linear sieve factorization" {
  let sieve = @linear_sieve.LinearSieve::new(100)
  inspect(sieve.factorize(84), content="[(2, 2), (3, 1), (7, 1)]")
  inspect(sieve.is_prime(97), content="true")
}
```

## Complexity

| Operation | Time |
|-----------|------|
| Sieve construction | O(n) |
| Prime check | O(1) |
| Factorization | O(log n) |
| φ(n), μ(n) lookup | O(1) |

## Linear Sieve vs Eratosthenes

| Sieve | Time | Extra Functions |
|-------|------|------------------|
| Linear (Euler) | O(n) | phi, mu, spf built-in |
| Eratosthenes | O(n log log n) | primes only |
| Segmented | O(n log log n) | memory efficient |

## Common Pitfalls

- The sieve is **inclusive**: `LinearSieve::new(n)` computes values for `1..n`.
- Factorization only works for `x <= n` (beyond that, spf is missing).
- `spf[1]` is 0 by definition (1 has no prime factor).

## When to Use Linear Sieve

- You need **many queries** of prime, φ, μ, or factorization.
- You want guaranteed **O(n)** preprocessing.
- You are working in number theory problems or multiplicative functions.
