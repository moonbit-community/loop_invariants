# Linear Sieve

## Overview

The **Linear Sieve** (also called Euler's Sieve) computes primes and
multiplicative functions in exactly O(n) time by ensuring each composite
is marked exactly once.

- **Time**: O(n)
- **Space**: O(n)
- **Output**: Primes, SPF, φ(n), μ(n)

## The Key Insight

```
Sieve of Eratosthenes: Marks each composite multiple times
  12 is marked by 2, 3 (twice)
  30 is marked by 2, 3, 5 (three times)
  → Total work: O(n log log n)

Linear Sieve insight: Mark each composite by its SMALLEST prime factor only
  12 = 2 × 6, so only 2 marks it
  30 = 2 × 15, so only 2 marks it
  → Each number marked exactly once → O(n)!
```

## Understanding the Algorithm

```
Key rule: For number i, multiply by primes p until p > spf[i]

Why? If p > spf[i], then spf[i*p] = spf[i], not p.
     So i*p should be marked by a smaller prime later.

Example with i = 6 (spf[6] = 2):
  6 × 2 = 12 ✓  (p = 2 ≤ spf[6] = 2)
  6 × 3 = 18 ✗  (p = 3 > spf[6] = 2, stop!)

Why stop? 18 = 2 × 9, so 9 will mark 18 with prime 2.
```

## Algorithm Walkthrough

```
Sieve up to n = 10:

i=2: 2 is prime (not marked)
     Mark 2×2=4 with spf[4]=2
     primes = [2]

i=3: 3 is prime (not marked)
     Mark 3×2=6 with spf[6]=2
     Mark 3×3=9 with spf[9]=3 (stop: 3 = spf[3])
     primes = [2, 3]

i=4: 4 is composite (spf[4]=2)
     Mark 4×2=8 with spf[8]=2 (stop: 2 = spf[4])
     primes = [2, 3]

i=5: 5 is prime
     Mark 5×2=10 with spf[10]=2
     Mark 5×3=15 > 10 (out of range in this example)
     primes = [2, 3, 5]

i=6: 6 is composite (spf[6]=2)
     Mark 6×2=12 > 10 (out of range)
     primes = [2, 3, 5]

... and so on

Result: spf = [_, _, 2, 3, 2, 5, 2, 7, 2, 3, 2]
        (index:  0  1  2  3  4  5  6  7  8  9 10)
```

## Visual: Why Each Composite is Marked Once

```
Composite 12:
  12 = 2 × 6   ← spf[12] = 2
  12 = 3 × 4   ← would set spf[12] = 3, but we stop at 3 > spf[4]=2
  12 = 4 × 3   ← not considered (4 is not prime)

Only 6 × 2 = 12 marks it!

Composite 30:
  30 = 2 × 15  ← spf[30] = 2
  30 = 3 × 10  ← would happen, but 3 > spf[10]=2, stop
  30 = 5 × 6   ← would happen, but 5 > spf[6]=2, stop

Only 15 × 2 = 30 marks it!
```

## Computing Multiplicative Functions

```
A function f is multiplicative if f(ab) = f(a)f(b) when gcd(a,b) = 1.

During the sieve, when marking i × p:

Case 1: p does not divide i (i.e., p < spf[i] is false, so p = spf[i])
  f(i × p) = f(i) × f(p)  (since gcd(i, p) = 1)

Case 2: p divides i (i.e., p = spf[i])
  Need special handling based on the function

For Euler's totient φ:
  Case 1: φ(i×p) = φ(i) × (p-1)
  Case 2: φ(i×p) = φ(i) × p

For Möbius μ:
  Case 1: μ(i×p) = μ(i) × (-1)
  Case 2: μ(i×p) = 0 (square factor)
```

## Quick Start

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

## What You Get

- `primes`: list of all primes ≤ n
- `spf`: smallest prime factor for every integer
- `phi`: Euler's totient function
- `mu`: Möbius function

These arrays enable fast factorization and multiplicative function queries.

## Understanding Euler's Totient φ(n)

```
φ(n) = count of integers 1 ≤ k ≤ n with gcd(k, n) = 1

Examples:
  φ(1) = 1    (just 1)
  φ(6) = 2    (1, 5 are coprime to 6)
  φ(10) = 4   (1, 3, 7, 9 are coprime to 10)
  φ(p) = p-1  (all 1..p-1 are coprime to prime p)

Formula: φ(n) = n × ∏(1 - 1/p) for all prime p dividing n
```

## Understanding Möbius μ(n)

```
μ(n) = { 1   if n is squarefree with even number of prime factors
       { -1  if n is squarefree with odd number of prime factors
       { 0   if n has a squared prime factor

Examples:
  μ(1) = 1     (empty product, even)
  μ(2) = -1   (one prime, odd)
  μ(6) = 1    (2×3, two primes, even)
  μ(4) = 0    (2², has square)
  μ(30) = -1  (2×3×5, three primes, odd)

Used in: Möbius inversion, inclusion-exclusion
```

## Factorization Example

```mbt check
///|
test "linear sieve factorization" {
  let sieve = @linear_sieve.LinearSieve::new(100)
  inspect(sieve.factorize(84), content="[(2, 2), (3, 1), (7, 1)]")
  inspect(sieve.is_prime(97), content="true")
}
```

## Fast Factorization with SPF

```
To factorize n using spf array:

factorize(n):
  factors = []
  while n > 1:
    p = spf[n]
    count = 0
    while spf[n] == p:
      n = n / p
      count++
    factors.append((p, count))
  return factors

Example: factorize(84)
  84: spf=2, 84/2=42, 42/2=21, 21/2 fails → (2, 2)
  21: spf=3, 21/3=7 → (3, 1)
  7: spf=7, 7/7=1 → (7, 1)
  Result: [(2,2), (3,1), (7,1)]

Time: O(log n) per factorization!
```

## Common Applications

### 1. Prime Counting
```
Count primes ≤ n: Just primes.length()
```

### 2. Euler's Theorem
```
a^φ(n) ≡ 1 (mod n) when gcd(a,n) = 1
Used for modular exponentiation.
```

### 3. Möbius Inversion
```
If g(n) = Σ f(d) for d|n, then f(n) = Σ μ(d) × g(n/d)
Powerful technique for counting problems.
```

### 4. Divisor Sums
```
Compute Σ f(d) for all d|n for each n.
Use multiplicativity for efficiency.
```

## Complexity Analysis

| Operation | Time |
|-----------|------|
| Sieve construction | O(n) |
| Prime check | O(1) |
| Factorization | O(log n) |
| φ(n), μ(n) lookup | O(1) |

## Linear Sieve vs Eratosthenes

| Sieve | Time | Multiplicative Functions |
|-------|------|-------------------------|
| **Linear** | O(n) | Easy to compute |
| Eratosthenes | O(n log log n) | Extra work needed |
| Segmented | O(n log log n) | Memory efficient |

**Choose Linear Sieve when**: You need multiplicative functions or guaranteed O(n).

## Implementation Notes

- The inner loop multiplies i by primes in order
- Stop when prime > spf[i] to ensure each composite is marked once
- φ and μ are computed incrementally during sieving
- Memory: 4 arrays of size n (spf, phi, mu, is_prime flag)

