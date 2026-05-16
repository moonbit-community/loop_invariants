# Sum Over Subsets (SOS) DP

## Overview

The **sum-over-subsets** transform replaces a function `f : 2^[n] -> Z`
with the array of subset sums

```
F[S] = sum over T ⊆ S of f[T]
```

The naive computation iterates over every `(T, S)` pair with `T ⊆ S`,
which has `Θ(3^n)` work. The **SOS DP** computes the same answer in
`O(n · 2^n)` via a bitwise prefix sum across each dimension of the
hypercube — the discrete analogue of computing a 2-D cumulative sum
row-by-row then column-by-column.

| Transform | Time | Space |
|---|---|---|
| Sum over subsets / supersets | `O(n · 2^n)` | in place |
| Möbius inverse (sub / super) | `O(n · 2^n)` | in place |

---

## Algorithm (in-place, subset variant)

```
for bit in 0..<n:
  for mask in 0..<2^n:
    if mask has `bit` set:
      f[mask] += f[mask ^ (1 << bit)]
```

After bit `b` has been processed,

> `f[S] = Σ_{T : T ⊆ S, T agrees with S on bits > b} f_original[T]`

At `b = n − 1` this is the full subset sum.

The **Möbius inverse** undoes the transform by subtracting instead of
adding, in the same bit order — it is exactly the linear operator's
inverse.

The **superset** variant flips the bit-set test (`mask has bit unset`)
and adds the value at `mask | (1 << bit)`.

---

## Subset-OR convolution

The most common use of SOS is computing an "OR-convolution":

```
h[S] = sum_{A | B = S} f[A] · g[B]
```

via the standard three-step recipe:

1. `sum_over_subsets(f); sum_over_subsets(g)` — apply the transform.
2. Multiply pointwise: `h[i] = f[i] · g[i]`.
3. `mobius_subsets(h)` — invert.

If you also enforce `A ∩ B = ∅` (proper **subset-sum convolution**)
you get the `O(n² · 2^n)` Yates / Yates-style algorithm — outside the
scope of this package.

---

## API

```
pub fn sum_over_subsets(arr : Array[Int64]) -> Bool
pub fn sum_over_supersets(arr : Array[Int64]) -> Bool
pub fn mobius_subsets(arr : Array[Int64]) -> Bool
pub fn mobius_supersets(arr : Array[Int64]) -> Bool
```

All four operate **in place** and return `true` on success, `false` if
`arr.length()` is not a positive power of two (length 1 counts).

---

## Tests and examples

```mbt check
///|
test "sos subset sum" {
  let f = [1L, 2L, 3L, 4L]
  let _ = @sos_dp.sum_over_subsets(f)
  // F[0b11] = 1 + 2 + 3 + 4 = 10
  debug_inspect(f, content="[1, 3, 4, 10]")
}
```

```mbt check
///|
test "sos mobius is inverse" {
  let original = [3L, 1L, 4L, 1L, 5L, 9L, 2L, 6L]
  let f = Array::makei(original.length(), i => original[i])
  let _ = @sos_dp.sum_over_subsets(f)
  let _ = @sos_dp.mobius_subsets(f)
  debug_inspect(f, content="[3, 1, 4, 1, 5, 9, 2, 6]")
}
```

---

## Use cases

- **Counting** over subsets where contributions are additive (e.g.
  inclusion–exclusion).
- **OR-convolution** for boolean / counting DPs over subsets.
- **Steiner-tree-style DPs** where you want
  `f[mask] = best over partitions of mask`.

---

## Pitfalls

- **Overflow.** Each subset sum can be up to `2^n` times the largest
  input; with `n = 20` and 32-bit inputs you are already at risk in
  `Int64`. Plan modulus or bignum accordingly.
- **Length checks.** A non-power-of-two array returns `false`; the
  array is not modified in that case.
- **Order matters for inverses.** `mobius_subsets` undoes
  `sum_over_subsets`; do *not* mix subset and superset variants.

---

## Related concepts

```
Zeta transform over the subset lattice    same operator, different name
Möbius transform over the subset lattice  the inverse
Walsh-Hadamard transform                  XOR-convolution analogue
Yates' algorithm                          subset-sum convolution (exact disjoint)
```
