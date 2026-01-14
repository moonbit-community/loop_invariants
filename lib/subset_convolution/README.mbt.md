# Subset Convolution

## Overview

**Subset Convolution** combines two functions on subsets:

```
h[S] = Σ_{T ⊆ S} f[T] · g[S \ T]
```

For each subset S, sum over all ways to partition S into T and S\T.

- **Time**: O(n² · 2ⁿ)
- **Space**: O(n · 2ⁿ)
- **Key Feature**: Partition counting over subsets

## The Key Insight

```
Problem: Compute h[S] = Σ_{T ⊆ S} f[T] · g[S \ T]

This is NOT the same as XOR convolution!
Here T and S\T must partition S (T ∪ (S\T) = S and T ∩ (S\T) = ∅)

Naive: For each S, enumerate all 2^|S| subsets → O(3^n) total

Subset convolution insight:
  Partition the problem by popcount (number of bits)!

  For subsets of size k:
    h[S, k] = Σ_{i=0}^{k} f[S, i] · g[S, k-i]
  where f[S, i] = f[S] if popcount(S) = i, else 0

  This is a polynomial convolution on the size dimension!
  Use zeta/Möbius transforms to handle the subset structure.
```

## Visual: Popcount Stratification

```
For n = 2 bits, subsets by popcount:

Size 0: {∅}         (mask 00)
Size 1: {{0}, {1}}  (masks 01, 10)
Size 2: {{0,1}}     (mask 11)

Subset convolution for h[11] (set {0,1}):
  h[{0,1}] = f[∅]·g[{0,1}] + f[{0}]·g[{1}] + f[{1}]·g[{0}] + f[{0,1}]·g[∅]

Organized by size:
  size 0 + size 2: f[∅]·g[{0,1}]
  size 1 + size 1: f[{0}]·g[{1}] + f[{1}]·g[{0}]
  size 2 + size 0: f[{0,1}]·g[∅]

This is convolution on sizes with subset constraint!
```

## Algorithm

```
subset_convolution(f, g):
  n = log2(length(f))

  // Step 1: Create popcount-stratified versions
  // F[k][S] = f[S] if popcount(S) = k, else 0
  // G[k][S] = g[S] if popcount(S) = k, else 0
  F = array[n+1][2^n] of zeros
  G = array[n+1][2^n] of zeros

  for S in 0..2^n-1:
    k = popcount(S)
    F[k][S] = f[S]
    G[k][S] = g[S]

  // Step 2: Apply zeta transform to each layer
  for k in 0..n:
    zeta_transform(F[k])
    zeta_transform(G[k])

  // Step 3: Convolve layers (polynomial multiplication on k)
  H = array[n+1][2^n] of zeros
  for S in 0..2^n-1:
    for i in 0..n:
      for j in 0..n-i:
        H[i+j][S] += F[i][S] * G[j][S]

  // Step 4: Apply inverse zeta (Möbius) transform
  for k in 0..n:
    mobius_transform(H[k])

  // Step 5: Extract result
  h = array[2^n]
  for S in 0..2^n-1:
    k = popcount(S)
    h[S] = H[k][S]

  return h
```

## Example Usage

```mbt check
///|
test "subset convolution quick start" {
  let f : Array[Int64] = [1L, 2L, 3L, 4L]
  let g : Array[Int64] = [5L, 6L, 7L, 8L]
  let h = @subset_convolution.subset_convolution(f[:], g[:])
  inspect(h, content="[5, 16, 22, 60]")
}
```

## Walkthrough of Example

```
n = 2, so masks 0..3 represent subsets of {0, 1}

f = [1, 2, 3, 4]  →  f[∅]=1, f[{0}]=2, f[{1}]=3, f[{0,1}]=4
g = [5, 6, 7, 8]  →  g[∅]=5, g[{0}]=6, g[{1}]=7, g[{0,1}]=8

Compute h[S] = Σ_{T ⊆ S} f[T]·g[S\T]:

h[∅] = f[∅]·g[∅] = 1·5 = 5

h[{0}] = f[∅]·g[{0}] + f[{0}]·g[∅]
       = 1·6 + 2·5 = 6 + 10 = 16

h[{1}] = f[∅]·g[{1}] + f[{1}]·g[∅]
       = 1·7 + 3·5 = 7 + 15 = 22

h[{0,1}] = f[∅]·g[{0,1}] + f[{0}]·g[{1}] + f[{1}]·g[{0}] + f[{0,1}]·g[∅]
         = 1·8 + 2·7 + 3·6 + 4·5
         = 8 + 14 + 18 + 20 = 60

Result: [5, 16, 22, 60] ✓
```

## Why Zeta Transform?

```
Zeta transform: ζ[f](S) = Σ_{T ⊆ S} f[T]

Key property: ζ[f * g] = ζ[f] · ζ[g]  (pointwise product)

where (f * g)[S] = Σ_{T ⊆ S} f[T] · g[S\T]

This is exactly subset convolution!

So: h = f * g
    ζ[h] = ζ[f] · ζ[g]
    h = ζ⁻¹[ζ[f] · ζ[g]]

But wait, this is OR convolution, not subset convolution!
The popcount trick ensures T ∪ (S\T) = S with no overlap.
```

## Common Applications

### 1. Counting Partitions
```
Count ways to partition a set into two parts
with specific properties.
```

### 2. Bitmask DP
```
Accelerate DP over subsets when the recurrence
involves partitioning into disjoint subsets.
```

### 3. Combinatorics
```
Problems involving "choose elements for group A,
remaining go to group B" patterns.
```

### 4. Graph Problems
```
Count ways to partition vertices into independent sets,
covers, or other disjoint structures.
```

## Complexity Analysis

| Operation | Time | Notes |
|-----------|------|-------|
| Zeta/Möbius transform | O(n · 2ⁿ) | Per layer |
| Layer convolution | O(n² · 2ⁿ) | Polynomial multiply |
| **Total** | **O(n² · 2ⁿ)** | |

## Subset Convolution vs Other Transforms

| Convolution | Formula | Time |
|-------------|---------|------|
| Subset | h[S] = Σ_{T⊆S} f[T]·g[S\T] | O(n² · 2ⁿ) |
| OR | h[S] = Σ_{T∪U=S} f[T]·g[U] | O(n · 2ⁿ) |
| AND | h[S] = Σ_{T∩U=S} f[T]·g[U] | O(n · 2ⁿ) |
| XOR | h[S] = Σ_{T⊕U=S} f[T]·g[U] | O(n · 2ⁿ) |

**Key difference**: Subset convolution requires T and S\T to be disjoint
(a true partition), while OR allows overlap.

## Implementation Notes

- n should be small (n ≤ 20 typically) due to O(2ⁿ) factor
- Stratify by popcount to separate "size layers"
- Zeta transform on each layer independently
- Convolve layers like polynomial coefficients
- Möbius transform to recover result
- Extract h[S] from layer popcount(S)

## The Zeta and Möbius Transforms

```
Zeta transform (subset sum):
  ζ[f](S) = Σ_{T ⊆ S} f[T]

  for i in 0..n-1:
    for S in 0..2^n-1:
      if S has bit i:
        f[S] += f[S without bit i]

Möbius transform (inverse):
  μ[f](S) such that ζ[μ[f]] = f

  for i in 0..n-1:
    for S in 0..2^n-1:
      if S has bit i:
        f[S] -= f[S without bit i]
```

