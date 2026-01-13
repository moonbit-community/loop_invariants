# Pollard Rho Factorization

## Overview

This package combines a deterministic Miller–Rabin test for 64-bit integers
with Pollard's Rho algorithm to factor composite numbers efficiently.

- **Time**: sub-exponential in practice (heuristic)
- **Space**: O(1) extra (plus recursion)

## Example

```mbt check
///|
test "pollard rho example" {
  let factors = @pollard_rho.factorize_with_counts(8051L)
  inspect(factors, content="[(83, 1), (97, 1)]")
}
```
