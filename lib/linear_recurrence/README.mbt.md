# Linear Recurrence (Kitamasa)

## Overview

This package computes the **n-th term** of a linear recurrence using the
Kitamasa method (polynomial doubling). It avoids matrix exponentiation and runs
in **O(k² log n)** for a recurrence of length `k`.

```
f(n) = c0*f(n-1) + c1*f(n-2) + ... + c_{k-1}*f(n-k)  (mod M)
```

- **Time**: O(k² log n)
- **Space**: O(k)

## Example

```mbt check
///|
test "linear recurrence example" {
  let m = 1000000007L
  let coeffs : Array[Int64] = [1L, 1L]
  let initial : Array[Int64] = [0L, 1L]
  inspect(
    @linear_recurrence.linear_recurrence_nth(coeffs, initial, 7L, m),
    content="13",
  )
}
```
