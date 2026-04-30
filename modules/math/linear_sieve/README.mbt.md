# Linear Sieve (Euler Sieve)

## What It Solves

The **linear sieve** computes primes and multiplicative functions in **O(n)** by
ensuring **each composite is marked exactly once** — by its smallest prime
factor (SPF).

It produces, for all `1..n`:

- `primes` list
- `spf` (smallest prime factor)
- Euler's totient `phi`
- Mobius `mu`

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

## Decision Logic (Mermaid Flowchart)

```mermaid
flowchart TD
    A[outer loop: i = 2..n] --> B{spf[i] == 0?}
    B -- yes --> C[i is prime\nspf[i]=i\nphi[i]=i-1\nmu[i]=-1\nprimes.push i]
    B -- no  --> D[i is composite\nvalues already set]
    C --> E
    D --> E[inner loop:\nfor each prime p in primes]
    E --> F{i * p > n?}
    F -- yes --> G[break: out of range]
    F -- no  --> H[spf[i*p] = p]
    H --> I{p divides i?}
    I -- yes --> J[phi[i*p] = phi[i] * p\nmu[i*p] = 0\nbreak]
    I -- no  --> K[phi[i*p] = phi[i] * p-1\nmu[i*p] = -mu[i]\ncontinue to next prime]
    K --> E
    J --> A
    G --> A
```

The `break` on `p | i` is the crucial step that makes the sieve linear: once
`p` divides `i`, every subsequent prime `q > p` would satisfy `q > spf[i*q]`,
so `i*q` will be marked later by `spf[i*q]` instead.

## Step-by-Step Trace (n = 10)

```
Initial state:
  primes = []
  phi[1] = 1,  mu[1] = 1

i = 2  spf[2] = 0 => prime
  spf[2]=2, phi[2]=1, mu[2]=-1
  primes = [2]
  p=2: ip=4 <= 10, spf[4]=2
       2 % 2 == 0 => phi[4]=phi[2]*2=2, mu[4]=0, BREAK

i = 3  spf[3] = 0 => prime
  spf[3]=3, phi[3]=2, mu[3]=-1
  primes = [2, 3]
  p=2: ip=6 <= 10, spf[6]=2
       3 % 2 != 0 => phi[6]=phi[3]*1=2, mu[6]=-mu[3]=1
  p=3: ip=9 <= 10, spf[9]=3
       3 % 3 == 0 => phi[9]=phi[3]*3=6, mu[9]=0, BREAK

i = 4  spf[4] = 2 => composite
  p=2: ip=8 <= 10, spf[8]=2
       4 % 2 == 0 => phi[8]=phi[4]*2=4, mu[8]=0, BREAK

i = 5  spf[5] = 0 => prime
  spf[5]=5, phi[5]=4, mu[5]=-1
  primes = [2, 3, 5]
  p=2: ip=10 <= 10, spf[10]=2
       5 % 2 != 0 => phi[10]=phi[5]*1=4, mu[10]=-mu[5]=1
  p=3: ip=15 > 10 => BREAK (out of range)

i = 6  spf[6] = 2 => composite
  p=2: ip=12 > 10 => BREAK

i = 7  spf[7] = 0 => prime
  spf[7]=7, phi[7]=6, mu[7]=-1
  primes = [2, 3, 5, 7]
  p=2: ip=14 > 10 => BREAK

i = 8  spf[8] = 2 => composite
  p=2: ip=16 > 10 => BREAK

i = 9  spf[9] = 3 => composite
  p=2: ip=18 > 10 => BREAK

i = 10 spf[10] = 2 => composite
  p=2: ip=20 > 10 => BREAK

Done.
```

## ASCII Art: Which Prime Crosses Off Which Composite

The grid below shows, for `n = 20`, which composite is marked (crossed off)
and by which prime. Each cell shows `marked_by_p` or `.` for primes.

```
 n   | marked by | reason
-----+-----------+------------------------------------
  2  |     .     | prime
  3  |     .     | prime
  4  |     2     | i=2, p=2  (2%2==0, break)
  5  |     .     | prime
  6  |     2     | i=3, p=2  (3%2!=0, continue)
  7  |     .     | prime
  8  |     2     | i=4, p=2  (4%2==0, break)
  9  |     3     | i=3, p=3  (3%3==0, break)
 10  |     2     | i=5, p=2  (5%2!=0, continue)
 11  |     .     | prime
 12  |     2     | i=6, p=2  (6%2==0, break)
 13  |     .     | prime
 14  |     2     | i=7, p=2  (7%2!=0, continue)
 15  |     3     | i=5, p=3  (5%2!=0, then 5%3!=0... wait: i=5,p=3->15)
 16  |     2     | i=8, p=2  (8%2==0, break)
 17  |     .     | prime
 18  |     2     | i=9, p=2  (9%2!=0, continue)
 19  |     .     | prime
 20  |     2     | i=10, p=2 (10%2==0, break)
```

Key observation: every even composite is crossed off by prime 2.
Odd composites with smallest prime factor 3 are crossed off by 3, etc.
No composite appears in more than one "marked by" row — that is the
guarantee that gives O(n) time.

## Visual: "Marked Once" Property

```
Composite 12:
  12 = 2 * 6   (p=2, i=6)  -> marked here
  12 = 3 * 4   (p=3, i=4)  -> skipped because p=3 > spf[4]=2

Composite 30:
  30 = 2 * 15  (p=2, i=15) -> marked here
  30 = 3 * 10  (p=3, i=10) -> skipped because p=3 > spf[10]=2
  30 = 5 * 6   (p=5, i=6)  -> skipped because p=5 > spf[6]=2
```

Each composite gets exactly one "mark" from its smallest prime factor.

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

## Euler's Totient phi(n)

```
phi(n) = count of numbers 1..n that are coprime with n

phi(1)  = 1
phi(6)  = 2   (1 and 5)
phi(10) = 4   (1, 3, 7, 9)
phi(p)  = p-1 for prime p
```

The sieve updates phi multiplicatively:

```
if p divides i:   phi(i*p) = phi(i) * p
else:             phi(i*p) = phi(i) * (p - 1)
```

Derivation: when p does not divide i, `i*p` gains a new prime factor p, and
the totient formula contributes a factor of `(1 - 1/p)`, giving `phi(i) * p *
(1 - 1/p) = phi(i) * (p-1)`.  When p already divides i, no new prime is
introduced; only the exponent increases, contributing a factor of p.

## Mobius mu(n)

```
mu(n) =  1   if n is squarefree with an even number of prime factors
       = -1  if n is squarefree with an odd number of prime factors
       =  0  if n has any squared prime factor
```

Examples:

```
mu(1)  =  1   (empty product)
mu(2)  = -1   (one prime factor)
mu(6)  =  1   (two prime factors: 2 and 3)
mu(4)  =  0   (2^2 divides 4)
mu(30) = -1   (three prime factors: 2, 3, 5)
```

Sieve update:

```
if p divides i:   mu(i*p) = 0   (p^2 now divides i*p)
else:             mu(i*p) = -mu(i)  (flip sign for new prime)
```

## Factorization Using SPF

Once you have `spf`, you can factorize any `x <= n` in O(log n) by repeatedly
dividing out `spf[x]`:

```
Factorize 84:
  spf[84] = 2 -> 84/2=42 -> 42/2=21   => 2^2
  spf[21] = 3 -> 21/3=7               => 3^1
  spf[7]  = 7 -> 7/7=1                => 7^1

Result: [(2, 2), (3, 1), (7, 1)]

Factorize 60:
  spf[60] = 2 -> 60/2=30 -> 30/2=15   => 2^2
  spf[15] = 3 -> 15/3=5               => 3^1
  spf[5]  = 5 -> 5/5=1                => 5^1

Result: [(2, 2), (3, 1), (5, 1)]
```

The inner loop exits when the current value drops to 1, so at most O(log x)
divisions are performed.

## Example Usage

```mbt check
///|
test "linear sieve quick start" {
  let sieve = @linear_sieve.LinearSieve(10)
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
  let sieve = @linear_sieve.LinearSieve(100)
  inspect(sieve.factorize(84), content="[(2, 2), (3, 1), (7, 1)]")
  inspect(sieve.is_prime(97), content="true")
}
```

## Complexity

| Operation          | Time     |
|--------------------|----------|
| Sieve construction | O(n)     |
| Prime check        | O(1)     |
| Factorization      | O(log n) |
| phi(n), mu(n) lookup | O(1)   |

## Linear Sieve vs Eratosthenes

| Sieve              | Time           | Extra Functions           |
|--------------------|----------------|---------------------------|
| Linear (Euler)     | O(n)           | phi, mu, spf built-in     |
| Eratosthenes       | O(n log log n) | primes only               |
| Segmented          | O(n log log n) | memory efficient           |

The linear sieve uses more memory per entry (four arrays instead of one
bitset), but provides O(1) lookup for phi, mu, and spf without any additional
passes.

## Common Pitfalls

- The sieve is **inclusive**: `LinearSieve(n)` computes values for `1..n`.
- Factorization only works for `x <= n` (beyond that, spf is missing).
- `spf[1]` is 0 by definition (1 has no prime factor).
- `phi[0]` and `mu[0]` are 0 (unused sentinel values).
- Calling `factorize` with `x > n` returns an empty array, not an error.

## When to Use Linear Sieve

- You need **many queries** of prime, phi, mu, or factorization.
- You want guaranteed **O(n)** preprocessing with no hidden log factors.
- You are working on number-theory problems that require multiplicative
  functions (Euler product formula, Dirichlet convolution, etc.).
