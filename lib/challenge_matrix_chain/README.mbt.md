# Challenge: Matrix Chain Multiplication

Dynamic programming for optimal multiplication order.

## Core Idea

If matrices have dimensions `d0 x d1`, `d1 x d2`, ..., `d_{n-1} x d_n`,
we minimize:

```
dp[i][j] = min over k in [i..j-1] of
  dp[i][k] + dp[k+1][j] + d_i * d_{k+1} * d_{j+1}
```

This gives the minimum scalar multiplications to compute the product.

## Example

```mbt check
///|
test "matrix chain example" {
  let dims : Array[Int] = [10, 30, 5, 60]
  let cost = @challenge_matrix_chain.matrix_chain_min_cost(dims[:])
  inspect(cost, content="4500")
}
```

## Another Example

```mbt check
///|
test "matrix chain classic" {
  let dims : Array[Int] = [40, 20, 30, 10, 30]
  let cost = @challenge_matrix_chain.matrix_chain_min_cost(dims[:])
  inspect(cost, content="26000")
}
```

## Notes

- `dims` length is number_of_matrices + 1.
- Time complexity is O(n^3).
