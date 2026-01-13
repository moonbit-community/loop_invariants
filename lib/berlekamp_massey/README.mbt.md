# Berlekamp–Massey

## Overview

Berlekamp–Massey finds the **shortest linear recurrence** that generates a
sequence over a finite field:

```
s[i] = c0*s[i-1] + c1*s[i-2] + ... + c_{L-1}*s[i-L]  (mod M)
```

This implementation assumes **M is prime**, so modular inverses exist.

- **Time**: O(n²)
- **Space**: O(n)

## Example

```mbt check
///|
test "berlekamp massey example" {
  let m = 1000000007L
  let seq : Array[Int64] = [0L, 1L, 1L, 2L, 3L, 5L, 8L]
  let coeffs = @berlekamp_massey.berlekamp_massey(seq, m)
  inspect(coeffs, content="[1, 1]")
}
```
