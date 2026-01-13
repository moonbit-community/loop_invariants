# XOR Linear Basis

## Overview

A **xor basis** stores a set of integers such that any xor combination of the
stored values can be represented. It supports fast insertion, membership
queries, and maximizing xor with a given value.

- **Time**: O(B) per operation, where B ≤ 63 bits
- **Space**: O(B)

## Key Idea

Maintain one basis vector per highest set bit (like Gaussian elimination over
GF(2)). When inserting a number, eliminate its highest set bits using existing
basis vectors. If a bit position is empty, store the reduced value there.

To maximize xor with x, greedily try to flip the highest bits by xoring with
basis vectors from high to low.

## API

- `insert(x)` returns true if the rank increases.
- `can_represent(x)` checks if x is in the span.
- `max_xor(x)` returns the maximum possible `x ^ y`.
- `rank()` returns the basis size.

## Example Usage

```mbt check
///|
test "xor basis max" {
  let b = @xor_basis.XorBasis::new()
  let _ = b.insert(8L)
  let _ = b.insert(5L)
  let _ = b.insert(10L)
  inspect(b.max_xor(0L), content="15")
}
```

## Notes

- The basis is not unique; any reduced form works.
- Rank equals the number of independent vectors.
