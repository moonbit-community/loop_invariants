# Subset Convolution

## Overview

Subset convolution combines two functions on subsets:

```
h[S] = sum_{A ⊆ S} f[A] * g[S \ A]
```

This implementation runs in **O(n^2 · 2^n)** using popcount layers and
zeta transforms.

## Input Encoding

For `n` bits, arrays `f` and `g` have length `2^n`. Index `mask` corresponds
to a subset of `{0..n-1}` by its bitmask.

## Quick Start

```mbt check
///|
test "subset convolution quick start" {
  let f : Array[Int64] = [1L, 2L, 3L, 4L]
  let g : Array[Int64] = [5L, 6L, 7L, 8L]
  let h = @subset_convolution.subset_convolution(f[:], g[:])
  inspect(h, content="[5, 16, 22, 60]")
}
```

## How to Read the Example

Here `n = 2`, so masks are 0..3:

- `0b00`: empty set
- `0b01`: {0}
- `0b10`: {1}
- `0b11`: {0,1}

The result `h[mask]` is the sum over all splits `A ⊆ mask` of `f[A] * g[mask\\A]`.

## Notes

- Complexity is O(n^2 * 2^n), so n should be small (n ≤ 20).
