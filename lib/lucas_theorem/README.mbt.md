# Lucas Theorem

## Overview

Lucas theorem computes `C(n, k) mod p` for **large n** when `p` is prime:

```
C(n, k) ≡ Π C(n_i, k_i) (mod p)
```

where `n_i` and `k_i` are digits of `n` and `k` in base `p`.

- **Time**: O(p + log_p n)
- **Space**: O(p)

## Example

```mbt check
///|
test "lucas theorem example" {
  inspect(@lucas_theorem.nck_mod_prime_lucas(10L, 3L, 7L), content="1")
}
```
