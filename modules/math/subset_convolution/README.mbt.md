# Subset Convolution

## Overview

**Subset convolution** computes, for each subset S of {0..n-1}:

```
h[S] = Σ_{T ⊆ S} f[T] · g[S \ T]
```

Every way to split S into a disjoint pair (T, S\T) contributes `f[T] · g[S\T]`
to the result. This is the "disjoint subset sum" convolution — distinct from
OR, AND, or XOR convolution.

- **Time**:  O(n² · 2^n)
- **Space**: O(n · 2^n)
- **Practical limit**: n ≤ 20

---

## The Problem: Enumerate Disjoint Partitions

```
Naive approach — for each S, enumerate all subsets T of S:

  h[S] = Σ_{T ⊆ S} f[T] · g[S \ T]

Cost per subset S of size k: 2^k (all sub-subsets)
Total cost: Σ_{k=0}^{n} C(n,k) · 2^k = 3^n   (by binomial theorem)

For n=20: 3^20 ≈ 3.5 · 10^9  — too slow.

Subset convolution brings this down to O(n² · 2^n):
  n=20: 20² · 2^20 ≈ 4.2 · 10^8  — feasible.
```

---

## The Key Insight: Ranked Stratification

The algorithm lifts the 1-D problem (indexed by subsets) to a 2-D problem
(indexed by subsets and popcount) so that the disjoint constraint becomes
a polynomial convolution.

```
Assign each subset a "rank" equal to its popcount (number of set bits).

Define ranked layers:

  F[k][S] = f[S]  if popcount(S) == k
           = 0    otherwise

  G[k][S] = g[S]  if popcount(S) == k
           = 0    otherwise

Then the subset convolution answer lives at the correct rank:

  H[k][S] = Σ_{i=0}^{k} F[i][S] · G[k-i][S]     (pointwise in S)

            ←————— polynomial mult over k ————→

Because T ⊆ S and S \ T are disjoint, their sizes sum to |S|.
Rank tracks this: rank(T) + rank(S\T) = rank(S).
Checking the rank enforces the disjointness condition automatically.
```

---

## Algorithm: Three Phases

```
┌─────────────────────────────────────────────────────────────────┐
│                  SUBSET CONVOLUTION PIPELINE                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  f[S], g[S]                                                     │
│      │                                                           │
│      ▼  Stratify by popcount                                    │
│  F[k][S], G[k][S]     (n+1 layers, each of size 2^n)           │
│      │                                                           │
│      ▼  Zeta (sum-over-subsets) transform on each layer        │
│  F̂[k][S] = Σ_{T⊆S} F[k][T]                                    │
│  Ĝ[k][S] = Σ_{T⊆S} G[k][T]                                    │
│      │                                                           │
│      ▼  Polynomial convolution in the rank dimension           │
│  Ĥ[k][S] = Σ_{i=0}^{k} F̂[i][S] · Ĝ[k-i][S]                  │
│      │                                                           │
│      ▼  Inverse zeta (Mobius) transform on each layer          │
│  H[k][S]  (reverse the subset-sum accumulation)                │
│      │                                                           │
│      ▼  Extract answer at correct rank                         │
│  h[S] = H[popcount(S)][S]                                       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Phase 1: Popcount Stratification

```
Input f = [f_00, f_01, f_10, f_11]   (n=2, subsets in binary order)

Populate layers by rank:

  Rank 0 (popcount 0):  subset 00 only
    F[0] = [f_00, 0,    0,    0   ]

  Rank 1 (popcount 1):  subsets 01, 10
    F[1] = [0,    f_01, f_10, 0   ]

  Rank 2 (popcount 2):  subset 11 only
    F[2] = [0,    0,    0,    f_11]
```

---

## Phase 2: Zeta Transform (Sum Over Subsets)

The zeta (sum-over-subsets) transform converts each layer from point values to
prefix-sum-over-subsets values. It processes one bit at a time:

```
For each bit b in 0..<n:
  For each mask S with bit b set:
    layer[S] += layer[S ^ (1<<b)]   // add contribution from S without bit b
```

```
Visual for n=2, one layer (indices 00, 01, 10, 11):

  Initial:   a   b   c   d

  Bit 0:
    S=01 (bit 0 set): layer[01] += layer[00]  →  b += a
    S=11 (bit 0 set): layer[11] += layer[10]  →  d += c
    After bit 0:  a   (a+b)   c   (c+d)

  Bit 1:
    S=10 (bit 1 set): layer[10] += layer[00]  →  c += a
    S=11 (bit 1 set): layer[11] += layer[01]  →  (c+d) += (a+b)
    After bit 1:  a   (a+b)   (a+c)   (a+b+c+d)

  Result: F̂[S] = Σ_{T⊆S} F[T]  ✓
```

```
Mermaid diagram — data flow for 3-bit zeta on one layer:

  (subset indices 0..7 as S2S1S0)

  After bit 0 (propagate along dimension 0):
  S=001 ← S=000,  S=011 ← S=010,  S=101 ← S=100,  S=111 ← S=110

  After bit 1 (propagate along dimension 1):
  S=010 ← S=000,  S=011 ← S=001,  S=110 ← S=100,  S=111 ← S=101

  After bit 2 (propagate along dimension 2):
  S=100 ← S=000,  S=101 ← S=001,  S=110 ← S=010,  S=111 ← S=011
```

---

## Phase 3: Rank-Dimension Polynomial Convolution

After the zeta transform, each position S is independent — the convolution is
purely over the rank index k:

```
For each fixed S (treated as a scalar position):

  F̂[·][S] is a polynomial in k:  F̂[0][S], F̂[1][S], ..., F̂[n][S]
  Ĝ[·][S] is a polynomial in k:  Ĝ[0][S], Ĝ[1][S], ..., Ĝ[n][S]

  Ĥ[k][S] = Σ_{i=0}^{k} F̂[i][S] · Ĝ[k-i][S]
           = coefficient k of (F̂[·][S] · Ĝ[·][S])

  This is ordinary polynomial multiplication, done pointwise for each S.
```

```
Example for n=2, S=11 (fixed):

  F̂ column at S=11:   [F̂[0][11], F̂[1][11], F̂[2][11]]
  Ĝ column at S=11:   [Ĝ[0][11], Ĝ[1][11], Ĝ[2][11]]

  Ĥ[0][11] = F̂[0]·Ĝ[0]
  Ĥ[1][11] = F̂[0]·Ĝ[1] + F̂[1]·Ĝ[0]
  Ĥ[2][11] = F̂[0]·Ĝ[2] + F̂[1]·Ĝ[1] + F̂[2]·Ĝ[0]
```

---

## Phase 4: Inverse Zeta (Mobius) Transform

The inverse of the zeta transform is the Mobius transform. It reverses the
subset-sum accumulation by subtracting instead of adding:

```
For each bit b in 0..<n:
  For each mask S with bit b set:
    layer[S] -= layer[S ^ (1<<b)]   // undo the addition from the forward pass
```

```
Zeta and Mobius are inverses:

  Zeta:    F̂[S] = Σ_{T⊆S} F[T]   (inclusion — add up all subsets)
  Mobius:  F[S]  = Σ_{T⊆S} (-1)^|S\T| · F̂[T]   (inclusion-exclusion)

  Applied dimension by dimension, each step is its own inverse:

  Zeta   step for bit b:  a[S] += a[S ^ mask]
  Mobius step for bit b:  a[S] -= a[S ^ mask]
```

---

## Phase 5: Extract the Answer

After the inverse zeta transform, `H[k][S]` holds the correct value only when
`k == popcount(S)`. Extract these diagonal entries:

```
  h[S] = H[popcount(S)][S]    for each S in 0..<2^n
```

---

## Tiny Worked Example (n = 2)

```
f = [1, 2, 3, 4]     g = [5, 6, 7, 8]
     ∅  {0} {1} {0,1}     ∅  {0} {1} {0,1}

Step 1 — Stratify:

  F[0] = [1, 0, 0, 0]    G[0] = [5, 0, 0, 0]
  F[1] = [0, 2, 3, 0]    G[1] = [0, 6, 7, 0]
  F[2] = [0, 0, 0, 4]    G[2] = [0, 0, 0, 8]

Step 2 — Zeta transform each layer:

  F̂[0] = [1, 1, 1, 1]    Ĝ[0] = [5,  5,  5,  5]
  F̂[1] = [0, 2, 3, 5]    Ĝ[1] = [0,  6,  7, 13]
  F̂[2] = [0, 0, 0, 4]    Ĝ[2] = [0,  0,  0,  8]

Step 3 — Rank convolution at each S:

  S=00: Ĥ[0]=1·5=5,  Ĥ[1]=1·0+0·5=0,  Ĥ[2]=1·0+0·0+0·5=0
  S=01: Ĥ[0]=1·5=5,  Ĥ[1]=1·6+2·5=16, Ĥ[2]=1·0+2·6+0·5=12
  S=10: Ĥ[0]=1·5=5,  Ĥ[1]=1·7+3·5=22, Ĥ[2]=1·0+3·7+0·5=21
  S=11: Ĥ[0]=1·5=5,  Ĥ[1]=1·13+5·5=38,Ĥ[2]=1·8+5·13+4·5=89

  Ĥ[0] = [5,  5,  5,  5]
  Ĥ[1] = [0, 16, 22, 38]
  Ĥ[2] = [0,  0,  0, 89]

Step 4 — Inverse zeta (Mobius) each layer:

  H[0] = [5,  0,  0,  0]    (same as F̂[0] inverted)
  H[1] = [0, 16, 22,  0]
  H[2] = [0,  0,  0, 60]

Step 5 — Extract diagonal:

  h[00] = H[0][00] = 5
  h[01] = H[1][01] = 16
  h[10] = H[1][10] = 22
  h[11] = H[2][11] = 60

Result: h = [5, 16, 22, 60]
```

Manual verification:

```
h[∅]     = f[∅]·g[∅]                            = 1·5           =  5
h[{0}]   = f[∅]·g[{0}] + f[{0}]·g[∅]           = 1·6 + 2·5    = 16
h[{1}]   = f[∅]·g[{1}] + f[{1}]·g[∅]           = 1·7 + 3·5    = 22
h[{0,1}] = f[∅]·g[{0,1}] + f[{0}]·g[{1}]
          + f[{1}]·g[{0}] + f[{0,1}]·g[∅]       = 8+14+18+20   = 60  ✓
```

---

## Example Usage

```mbt check
///|
test "subset convolution quick start" {
  let f : Array[Int64] = [1L, 2L, 3L, 4L]
  let g : Array[Int64] = [5L, 6L, 7L, 8L]
  let h = @subset_convolution.subset_convolution(f, g)
  debug_inspect(h, content="[5, 16, 22, 60]")
}
```

```mbt check
///|
test "subset convolution identity" {
  // Convolving with the identity: delta[S] = 1 if S=∅ else 0
  // h[S] = Σ_{T⊆S} f[T]·delta[S\T] = f[S]·delta[∅] = f[S]
  let f : Array[Int64] = [3L, 7L, 5L, 11L]
  let delta : Array[Int64] = [1L, 0L, 0L, 0L]
  let h = @subset_convolution.subset_convolution(f, delta)
  debug_inspect(h, content="[3, 7, 5, 11]")
}
```

---

## Complexity

```
                   Layers    Per-layer cost    Total
Stratification:    n+1       2^n               O(n · 2^n)
Zeta transforms:   n+1       n · 2^n           O(n² · 2^n)
Rank convolution:  n+1       (n+1) · 2^n       O(n² · 2^n)
Inverse zeta:      n+1       n · 2^n           O(n² · 2^n)
Extraction:        1         2^n               O(2^n)

Overall:  Time O(n² · 2^n)   Space O(n · 2^n)
```

Practical guidance:

```
n = 10:  layers=11,  size=1024,   ops ≈  112K   — instant
n = 15:  layers=16,  size=32768,  ops ≈  7.9M   — fast
n = 20:  layers=21,  size=1M,     ops ≈  440M   — ~1 s
n = 25:  layers=26,  size=32M,    ops ≈  21B    — too slow
```

---

## When to Use Subset Convolution

- Partitioning DP on subsets: count ways to partition set S into parts with
  property P and property Q.
- Domino-covering / coloring problems on subsets where two roles are assigned.
- Any formula of the form h[S] = Σ_{T⊆S} f[T] · g[S\T] where T and S\T must
  be disjoint (not OR convolution, which allows overlap).

Contrast with other subset transforms:

```
OR  convolution: h[S] = Σ_{A|B=S} f[A]·g[B]   (A, B may overlap)
AND convolution: h[S] = Σ_{A&B=S} f[A]·g[B]
XOR convolution: h[S] = Σ_{A^B=S} f[A]·g[B]

Subset (disjoint) convolution:
             h[S] = Σ_{A⊔B=S} f[A]·g[B]        (A∩B = ∅, A∪B = S)
```

---

## Beginner Checklist

1. Input arrays must have length exactly 2^n for some n.
2. Index `s` represents the subset whose members are the set bits of `s`.
3. The answer is the disjoint-partition convolution, not OR/AND/XOR.
4. Complexity grows quickly — keep n ≤ 20 in practice.
5. The empty set (index 0) is a valid element: f[0] = f[∅].
