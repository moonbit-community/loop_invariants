# Subset Convolution

## Overview

Subset convolution combines two functions on subsets:

```
h[S] = sum_{A ⊆ S} f[A] * g[S \ A]
```

This implementation runs in **O(n^2 · 2^n)** using popcount layers and
zeta transforms.

## Example

```mbt check
///|
test "subset convolution example" {
  let f : Array[Int64] = [1L, 2L, 3L, 4L]
  let g : Array[Int64] = [5L, 6L, 7L, 8L]
  let h = @subset_convolution.subset_convolution(f[:], g[:])
  inspect(h, content="[5, 16, 22, 60]")
}
```
